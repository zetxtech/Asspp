#import "SAPContext.h"
#import <CommonCrypto/CommonDigest.h>
#include "SapMachine.h"
#include <unordered_map>

static NSData *ReadAssetContainer(NSURL *root) {
    return [NSData dataWithContentsOfURL:[root URLByAppendingPathComponent:@"SAPAssets.bin"]];
}

static std::unordered_map<std::string, std::vector<uint8_t>> ParseAssetContainer(NSData *container) {
    static const uint8_t magic[] = {'A', 'S', 'S', 'P', 'B', 'I', 'N', '1', 0};
    NSUInteger magicLength = sizeof(magic);
    if (container.length < magicLength || memcmp(container.bytes, magic, magicLength) != 0)
        throw std::runtime_error("SAP asset container is missing or invalid. Rebuild or reinstall the app.");
    std::unordered_map<std::string, std::vector<uint8_t>> assets;
    const uint8_t *cursor = static_cast<const uint8_t *>(container.bytes) + magicLength;
    const uint8_t *end = static_cast<const uint8_t *>(container.bytes) + container.length;
    while (cursor < end) {
        if (end - cursor < 4) throw std::runtime_error("SAP asset container is truncated.");
        uint32_t nameLength = 0;
        memcpy(&nameLength, cursor, 4);
        cursor += 4;
        nameLength = CFSwapInt32BigToHost(nameLength);
        if (nameLength == 0 || nameLength > 256 || end - cursor < nameLength)
            throw std::runtime_error("SAP asset container has an invalid name field.");
        std::string name(reinterpret_cast<const char *>(cursor), nameLength);
        cursor += nameLength;
        if (end - cursor < 8) throw std::runtime_error("SAP asset container is truncated.");
        uint64_t dataLength = 0;
        memcpy(&dataLength, cursor, 8);
        cursor += 8;
        dataLength = CFSwapInt64BigToHost(dataLength);
        if (dataLength == 0 || end - cursor < dataLength)
            throw std::runtime_error("SAP asset container has an invalid payload field.");
        auto &slot = assets[name];
        slot.assign(cursor, cursor + dataLength);
        cursor += dataLength;
    }
    return assets;
}

static std::vector<uint8_t> LookupVerifiedAsset(const std::unordered_map<std::string, std::vector<uint8_t>> &assets,
                                                const char *name, NSUInteger size, const char *hash) {
    auto found = assets.find(name);
    if (found == assets.end() || found->second.size() != size)
        throw std::runtime_error("SAP asset " + std::string(name) + " has size " +
                                 std::to_string(static_cast<unsigned long long>(found == assets.end() ? 0 : found->second.size())) +
                                 ", expected " + std::to_string(static_cast<unsigned long long>(size)) +
                                 ". Rebuild or reinstall the app.");
    const std::vector<uint8_t> &data = found->second;
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.data(), (CC_LONG)data.size(), digest);
    NSMutableString *actual = [NSMutableString string];
    for (unsigned char byte : digest) [actual appendFormat:@"%02x", byte];
    if (![actual isEqualToString:[NSString stringWithUTF8String:hash]])
        throw std::runtime_error("SAP asset " + std::string(name) + " failed SHA-256 verification. Rebuild or reinstall the app.");
    return data;
}

static void SetError(NSError **error, const std::exception &exception) {
    if (error) *error = [NSError errorWithDomain:@"Asspp.SAP" code:1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithUTF8String:exception.what()]}];
}

@implementation SAPContext {
    std::unique_ptr<SapMachine> _machine;
    std::vector<uint8_t> _hardwareID;
    uint64_t _context;
    BOOL _complete;
    NSUInteger _exchanges;
}

- (instancetype)initWithAssetsURL:(NSURL *)url hardwareID:(NSData *)hardwareID error:(NSError **)error {
    self = [super init];
    if (!self) return nil;
    try {
        if (hardwareID.length != 6) throw std::runtime_error("Invalid SAP device identifier.");
        auto bytes = static_cast<const uint8_t *>(hardwareID.bytes);
        _hardwareID.assign(bytes, bytes + hardwareID.length);
        auto assets = ParseAssetContainer(ReadAssetContainer(url));
        _machine = SapMachine::Create(
            LookupVerifiedAsset(assets, "CoreFP", 29014912, "f19141336be4198d0f8991bb00017c915efc7aeaece36c345f7faa1237ea6074"),
            LookupVerifiedAsset(assets, "CommerceCore", 207744, "c5401e57402230f3c876409d295319ddf1e61287bc882683c5d61277be7bc1f2"),
            LookupVerifiedAsset(assets, "CommerceKit", 3271840, "b84ff12c21987856c0a17b78f1ad82b73195a6dec5f3b208a17d245555a2c8a2"),
            LookupVerifiedAsset(assets, "CoreFP.icxs", 5288352, "473e78af86979f5bd4f6269561caf770b3d16c098d918846eeac8cdd2fe6566a"),
            _hardwareID
        );
        _context = _machine->Initialize(_hardwareID);
        return self;
    } catch (const std::exception &exception) {
        SetError(error, exception);
        return nil;
    }
}

- (BOOL)complete { return _complete; }

- (NSData *)exchangeData:(NSData *)data version:(uint32_t)version error:(NSError **)error {
    try {
        if (!_machine || version != 200 || _exchanges >= 2 || !data.length || data.length > 1024 * 1024)
            throw std::runtime_error("Invalid SAP handshake.");
        auto [output, state] = _machine->Exchange(version, _hardwareID, _context, {static_cast<const uint8_t *>(data.bytes), data.length});
        if (state != (_exchanges == 0 ? 1 : 0)) throw std::runtime_error("Unexpected SAP handshake state.");
        _exchanges++;
        _complete = state == 0;
        return [NSData dataWithBytes:output.data() length:output.size()];
    } catch (const std::exception &exception) {
        SetError(error, exception);
        return nil;
    }
}

- (NSData *)signData:(NSData *)data error:(NSError **)error {
    try {
        if (!_complete || data.length > 1024 * 1024) throw std::runtime_error("SAP session is not ready.");
        auto signature = _machine->Sign(_context, {static_cast<const uint8_t *>(data.bytes), data.length});
        if (signature.empty()) throw std::runtime_error("SAP returned an empty signature.");
        return [NSData dataWithBytes:signature.data() length:signature.size()];
    } catch (const std::exception &exception) {
        SetError(error, exception);
        return nil;
    }
}

- (void)dealloc {
    if (_machine && _context) {
        try { _machine->Teardown(_context); } catch (...) { /* Destructors must not throw. */ }
    }
}
@end
