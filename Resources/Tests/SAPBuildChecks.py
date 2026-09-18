"""Offline build-script regression tests; no Xcode build or downloads required."""
import hashlib
import importlib.util
import io
from pathlib import Path
import tempfile
import unittest
import unittest.mock

spec = importlib.util.spec_from_file_location("sap_build", Path(__file__).parents[1] / "Scripts/prepare.sap.py")
sap = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sap)


class SAPBuildChecks(unittest.TestCase):
    def test_prefix_reader_preserves_requested_sizes(self):
        reader = sap.PrefixedReader(io.BytesIO(b"payload"))
        self.assertEqual(reader.read(0), b"")
        self.assertEqual(reader.read(2), b"BZ")
        self.assertEqual(reader.read(3), b"h9p")
        self.assertEqual(reader.read(), b"ayload")

    def test_exact_handles_short_reads_and_truncation(self):
        class ShortReads(io.BytesIO):
            def read(self, size=-1):
                return super().read(min(size, 2))
        self.assertEqual(sap.exact(ShortReads(b"abcdef"), 6), b"abcdef")
        with self.assertRaises(RuntimeError):
            sap.exact(ShortReads(b"abc"), 4)

    def test_cache_changes_with_sdk_compiler_and_options(self):
        command = ["cmake", "sdk-one", "arm64", "target=17.0"]
        key = sap.build_signature(command, "Apple clang one")
        for different in [command + ["new-option"], command[:-1] + ["target=18.0"], ["cmake", "sdk-two", "x86_64"]]:
            self.assertNotEqual(key, sap.build_signature(different, "Apple clang one"))
        self.assertNotEqual(key, sap.build_signature(command, "Apple clang two"))

    def test_atomic_assets_are_checked_by_size_and_hash(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "asset"
            data = b"verified fixture"
            expected = (len(data), hashlib.sha256(data).hexdigest())
            sap.atomic_write(path, data)
            self.assertTrue(sap.valid_asset(path, expected))
            sap.atomic_write(path, b"invalid fixture!")
            self.assertFalse(sap.valid_asset(path, expected))
            self.assertEqual(list(Path(directory).iterdir()), [path])

    def test_container_magic_never_looks_like_macho(self):
        self.assertNotIn(sap.CONTAINER_MAGIC[:4], (b"\xca\xfe\xba\xbe", b"\xcf\xfa\xed\xfe", b"\xfe\xed\xfa\xcf"))
        self.assertEqual(len(sap.CONTAINER_MAGIC), 9)

    def test_pack_assets_roundtrip_preserves_verified_bytes(self):
        fake = {'A': (3, hashlib.sha256(b'abc').hexdigest()),
                'B.bin': (5, hashlib.sha256(b'hello').hexdigest())}
        payloads = {'A': b'abc', 'B.bin': b'hello'}
        with tempfile.TemporaryDirectory() as directory, unittest.mock.patch.object(sap, 'ASSETS', fake):
            root = Path(directory)
            for name, spec in fake.items():
                sap.atomic_write(root / name, payloads[name])
                self.assertTrue(sap.valid_asset(root / name, spec))
            blob = sap.pack_assets(root)
        self.assertTrue(blob.startswith(sap.CONTAINER_MAGIC))
        cursor = len(sap.CONTAINER_MAGIC)
        for name in ('A', 'B.bin'):
            (name_length,) = __import__('struct').unpack('>I', blob[cursor:cursor + 4])
            cursor += 4
            self.assertEqual(blob[cursor:cursor + name_length].decode(), name)
            cursor += name_length
            (data_length,) = __import__('struct').unpack('>Q', blob[cursor:cursor + 8])
            cursor += 8
            expected = payloads[name]
            self.assertEqual(data_length, len(expected))
            self.assertEqual(blob[cursor:cursor + data_length], expected)
            cursor += data_length
        self.assertEqual(cursor, len(blob))

    def test_pack_assets_rejects_unverified_assets(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "CoreFP").write_bytes(b"tampered")
            with self.assertRaises(RuntimeError):
                sap.pack_assets(root)


if __name__ == "__main__":
    unittest.main()
