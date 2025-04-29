//
//  NetworkService.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 07.08.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public protocol NetworkEndpoint {
    var baseUrl: String {get}
    var path: String {get}
    var queryItems: [URLQueryItem]? {get}
    var method: String {get}
    var body: Data? {get}
    var headers: [String:String] {get}
}

public enum NetworkServiceError: Error, LocalizedError {
    case emptyResponse
    case statusCode(Int, String?)
    case urlSessionError(Error)
    case emptyResponseData
    case mappingError(Error)
    case failedToMakeRequest
    case ctDisabled

    public var errorDescription: String? {
        switch self {
        case .urlSessionError(let error):
            return error.localizedDescription
        default:
            return "\(self)"
        }
    }

}

public class NetworkService {
    private let session: URLSession

    public init() {
        session = ForcedCTURLSessionBuilder.makeSession(configuration: .defaultTangemSDKConfiguration)
    }

    public init(session: URLSession) {
        self.session = session
    }
    
    deinit {
        Log.debug("NetworkService deinit")
    }
    
    public func requestPublisher(_ endpoint: NetworkEndpoint) -> AnyPublisher<Data, NetworkServiceError> {
        guard let request = prepareRequest(from: endpoint) else {
            return Fail(error: NetworkServiceError.failedToMakeRequest).eraseToAnyPublisher()
        }

        return requestDataPublisher(request: request)
    }
    
    private func requestDataPublisher(request: URLRequest) -> AnyPublisher<Data, NetworkServiceError> {
        Log.network("request to: \(request)")
        
        return session
            .dataTaskPublisher(for: request)
            .subscribe(on: DispatchQueue.global())
            .tryMap { data, response -> Data in
                Log.network("response: \(response)")
                guard let response = response as? HTTPURLResponse else {
                    let error = NetworkServiceError.emptyResponse
                    Log.network(error.localizedDescription)
                    throw error
                }
                
                guard (200 ..< 300) ~= response.statusCode else {
                    let error = NetworkServiceError.statusCode(response.statusCode, String(data: data, encoding: .utf8))
                    Log.network(error.localizedDescription)
                    throw error
                }
                
                Log.network("status code: \(response.statusCode), response: \(String(data: data, encoding: .utf8) ?? "" )")
                return data
            }
            .mapError { $0 as? NetworkServiceError ?? NetworkServiceError.urlSessionError($0) }
            .eraseToAnyPublisher()
    }
    
    private func prepareRequest(from endpoint: NetworkEndpoint) -> URLRequest? {
        guard var urlComponents = URLComponents(string: endpoint.baseUrl + endpoint.path) else {
            return nil
        }
        
        urlComponents.queryItems = endpoint.queryItems

        guard let url = urlComponents.url else {
            return nil
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.method
        urlRequest.httpBody = endpoint.body
        
        for header in endpoint.headers {
            urlRequest.addValue(header.value, forHTTPHeaderField: header.key)
        }
        
        return urlRequest
    }
    
    private func map<T: Decodable>(_ data: Data, type: T.Type) -> T? {
        try? JSONDecoder().decode(T.self, from: data)
    }
}


fileprivate extension URLSessionConfiguration {
    static var defaultTangemSDKConfiguration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 30
        return configuration
    }
}
