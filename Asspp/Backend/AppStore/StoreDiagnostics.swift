import Foundation

enum StoreDiagnostics {
    /// NSError userInfo and localized descriptions may contain account names,
    /// signed URLs or Apple response messages. Keep those out of retained logs.
    static func errorSummary(_ error: Error) -> String {
        if let auth = error as? StoreAuthenticationError {
            let detail: String
            switch auth {
            case .rejected:
                detail = "rejected"
            case let .serviceResponse(status):
                detail = "serviceResponse(\(status))"
            default:
                detail = String(describing: auth)
            }
            return "type=StoreAuthenticationError case=\(detail) code=\((error as NSError).code)"
        }
        return "type=\(String(describing: type(of: error))) code=\((error as NSError).code)"
    }
}
