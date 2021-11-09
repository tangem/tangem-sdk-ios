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
    var url: URL {get}
    var method: String {get}
    var body: Data? {get}
    var headers: [String:String] {get}
    var configuration: URLSessionConfiguration? { get }
}

public enum NetworkServiceError: Error, LocalizedError {
    case emptyResponse
    case statusCode(Int, String?)
    case urlSessionError(Error)
    case emptyResponseData
    case mappingError(Error)
    case underliying(Error)
    
    public var errorDescription: String? {
        switch self {
        case .urlSessionError(let error):
            return error.localizedDescription
        default:
            return "\(self)"
        }
    }
    
    static func fromError(_ error: Error) -> NetworkServiceError{
        if let ne = error as? NetworkServiceError {
            return ne
        } else {
            return .underliying(error)
        }
    }
}

@available(iOS 13.0, *)
public class NetworkService {
    private let configuration: URLSessionConfiguration?
    
    /// Pass configuration to override default configuration
    public init (configuration: URLSessionConfiguration? = nil) {
        self.configuration = configuration
    }
    
    public func requestPublisher(_ endpoint: NetworkEndpoint) -> AnyPublisher<Data, NetworkServiceError> {
        let request = prepareRequest(from: endpoint)
        let configuration: URLSessionConfiguration = self.configuration ?? endpoint.configuration ?? .default
        return requestDataPublisher(request: request, configuration: configuration)
    }
    
    private func requestDataPublisher(request: URLRequest, configuration: URLSessionConfiguration) -> AnyPublisher<Data, NetworkServiceError> {
        Log.network("request to: \(request.url!)")
        
        return URLSession(configuration: configuration)
            .dataTaskPublisher(for: request)
            .subscribe(on: DispatchQueue.global())
            .tryMap { data, response -> Data in
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
            .mapError { error in
                if let nse = error as? NetworkServiceError {
                    return nse
                } else {
                    return NetworkServiceError.urlSessionError(error)
                }
            }
            .eraseToAnyPublisher()
    }
    
    private func prepareRequest(from endpoint: NetworkEndpoint) -> URLRequest {
        var urlRequest = URLRequest(url: endpoint.url)
        urlRequest.httpMethod = endpoint.method
        urlRequest.httpBody = endpoint.body
        
        for header in endpoint.headers {
            urlRequest.addValue(header.key, forHTTPHeaderField: header.value)
        }
        
        return urlRequest
    }
    
    private func map<T: Decodable>(_ data: Data, type: T.Type) -> T? {
        try? JSONDecoder().decode(T.self, from: data)
    }
}
