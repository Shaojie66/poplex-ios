import Foundation
import Security

enum MiniMaxKeySource: String, Sendable {
    case environment
    case keychain
    case none
}

struct MiniMaxCredentialState: Sendable {
    let source: MiniMaxKeySource
    let sourceLabel: String
    let helperMessage: String
    let warningMessage: String?
    let isConfigured: Bool
    let hasSavedKey: Bool
}

enum MiniMaxCredentialError: LocalizedError {
    case emptyKey
    case saveFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .emptyKey:
            return "Paste a MiniMax API key first."
        case .saveFailed:
            return "The key couldn’t be saved to the device keychain."
        }
    }
}

actor MiniMaxCredentialStore {
    static let environmentVariable = "MINIMAX_API_KEY"

    private let service = "com.codex.poplex.minimax"
    private let account = "default"

    func currentState() -> MiniMaxCredentialState {
        let environmentKey = environmentAPIKey()
        let savedKey = keychainAPIKey()

        if let apiKey = environmentKey {
            return MiniMaxCredentialState(
                source: .environment,
                sourceLabel: "Using environment variable",
                helperMessage: savedKey == nil
                    ? "MiniMax is ready through the `MINIMAX_API_KEY` environment variable."
                    : "MiniMax is currently using `MINIMAX_API_KEY`. A fallback key is also saved locally on this device.",
                warningMessage: warningMessage(for: apiKey),
                isConfigured: true,
                hasSavedKey: savedKey != nil
            )
        }

        if let apiKey = savedKey {
            return MiniMaxCredentialState(
                source: .keychain,
                sourceLabel: "Saved on this device",
                helperMessage: "MiniMax is ready. The key lives in your local keychain, not in the repo.",
                warningMessage: warningMessage(for: apiKey),
                isConfigured: true,
                hasSavedKey: true
            )
        }

        return MiniMaxCredentialState(
            source: .none,
            sourceLabel: "Not configured",
            helperMessage: "Add a MiniMax API key to unlock live definitions and images. Until then, PopLex stays in preview mode.",
            warningMessage: nil,
            isConfigured: false,
            hasSavedKey: false
        )
    }

    func apiKey() -> String? {
        environmentAPIKey() ?? keychainAPIKey()
    }

    func saveAPIKey(_ apiKey: String) throws {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw MiniMaxCredentialError.emptyKey
        }

        let data = Data(trimmed.utf8)
        let query = keychainQuery()

        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = data

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw MiniMaxCredentialError.saveFailed(status)
        }
    }

    func clearSavedAPIKey() {
        SecItemDelete(keychainQuery() as CFDictionary)
    }

    private func environmentAPIKey() -> String? {
        let value = ProcessInfo.processInfo.environment[Self.environmentVariable]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return value?.isEmpty == false ? value : nil
    }

    private func keychainAPIKey() -> String? {
        var query = keychainQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    private func warningMessage(for apiKey: String) -> String? {
        _ = apiKey
        return nil
    }

    private func keychainQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
    }
}
