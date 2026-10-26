import Foundation

private final class RuleNoRedirect: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}

/// Streams bounded responses off the UI actor; cookies, cache and redirects are disabled.
actor RuleHTTPClient {
    private let session: URLSession
    private let redirect = RuleNoRedirect()
    private let origin: URL
    init(origin: URL, configuration: URLSessionConfiguration) {
        self.origin = origin
        configuration.urlCache = nil
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        session = URLSession(configuration: configuration)
    }
    deinit { session.invalidateAndCancel() }
    func fetch(_ component: String, maximumBytes: Int) async throws -> Data {
        guard origin.scheme == "https", origin.host != nil, origin.user == nil, origin.password == nil,
              !component.isEmpty, !component.contains("/"), component != ".", component != ".." else {
            throw RuleUpdateFailure.invalidManifest
        }
        var request = URLRequest(url: origin.appendingPathComponent(component))
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (stream, response) = try await session.bytes(for: request, delegate: redirect)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200,
              response.url?.host == origin.host, response.url?.scheme == "https",
              response.url?.port == origin.port,
              response.expectedContentLength <= maximumBytes else { throw RuleUpdateFailure.invalidManifest }
        var data = Data()
        if response.expectedContentLength > 0 { data.reserveCapacity(Int(response.expectedContentLength)) }
        for try await byte in stream {
            try Task.checkCancellation()
            guard data.count < maximumBytes else { throw RuleUpdateFailure.invalidManifest }
            data.append(byte)
        }
        return data
    }
}

enum RuleBackground {
    static func run<Value: Sendable>(_ operation: @escaping @Sendable () throws -> Value) async throws -> Value {
        let task = Task.detached(priority: .utility, operation: operation)
        return try await withTaskCancellationHandler(operation: { try await task.value }, onCancel: { task.cancel() })
    }
}
