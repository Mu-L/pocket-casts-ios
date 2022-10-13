import Foundation
import PocketCastsDataModel
import PocketCastsUtils

public extension ApiServerHandler {
    func validateLogin(identityToken: Data?, completion: @escaping (Result<AuthenticationResponse, APIError>) -> Void) {
        guard let identityToken = identityToken,
              let token = String(data: identityToken, encoding: .utf8),
              let request = tokenRequest(identityToken: token)
        else {
            FileLog.shared.addMessage("Unable to create protobuffer request to obtain token via Apple SSO")
            completion(.failure(.UNKNOWN))
            return
        }

        obtainToken(request: request, completion: completion)
    }

    func refreshIdentityToken(completion: @escaping (Result<String?, APIError>) -> Void) {
        guard
            let identityToken = ServerSettings.appleAuthIdentityToken,
            let request = tokenRequest(identityToken: identityToken, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30.seconds)
        else {
            FileLog.shared.addMessage("Unable to locate Apple SSO token in Keychain")
            completion(.failure(.UNKNOWN))
            return
        }

        obtainToken(request: request) { result in
            switch result {
            case .success(let response):
                completion(.success(response.token))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func tokenRequest(identityToken: String?, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, timeoutInterval: TimeInterval = 15.seconds) -> URLRequest? {
        let url = ServerHelper.asUrl(ServerConstants.Urls.api() + "user/login_apple")
        guard let identityToken = identityToken,
            var request = ServerHelper.createEmptyProtoRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
        else { return nil }

        request.setValue("Bearer \(identityToken)", forHTTPHeaderField: ServerConstants.HttpHeaders.authorization)
        return request
    }
}