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
}

public enum NetworkServiceError: Error {
    case emptyResponse
    case statusCode(Int, String?)
    case urlSessionError(Error)
    case emptyResponseData
    case mapError
}

public class NetworkService {
    public init () {}
    
    public func request<T: Decodable>(_ endpoint: NetworkEndpoint, responseType: T.Type, completion: @escaping (Result<T, NetworkServiceError>) -> Void) {
        let request = prepareRequest(from: endpoint)
        
        requestData(request: request) { result in
            switch result {
            case .success(let data):
                if let mapped = self.map(data, type: T.self) {
                    completion(.success(mapped))
                } else {
                    completion(.failure(.mapError))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func request(_ endpoint: NetworkEndpoint, completion: @escaping (Result<Data, NetworkServiceError>) -> Void) {
        let request = prepareRequest(from: endpoint)
        requestData(request: request, completion: completion)
    }
    
    @available(iOS 13.0, *)
    public func requestPublisher(_ endpoint: NetworkEndpoint) -> AnyPublisher<Data, NetworkServiceError> {
        let request = prepareRequest(from: endpoint)
        return requestDataPublisher(request: request)
    }
    
    private func requestData(request: URLRequest, completion: @escaping (Result<Data, NetworkServiceError>) -> Void) {
        print("request to: \(request.url!)")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(NetworkServiceError.urlSessionError(error)))
                print(error.localizedDescription)
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                completion(.failure(NetworkServiceError.emptyResponse))
                return
            }
            
            guard (200 ..< 300) ~= response.statusCode else {
                completion(.failure(NetworkServiceError.statusCode(response.statusCode, String(data: data ?? Data(), encoding: .utf8))))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkServiceError.emptyResponseData))
                return
            }
            
            print("status code: \(response.statusCode), response: \(String(data: data, encoding: .utf8) ?? "" )")
            completion(.success(data))
        }.resume()
    }
    
    @available(iOS 13.0, *)
    private func requestDataPublisher(request: URLRequest) -> AnyPublisher<Data, NetworkServiceError> {
        print("request to: \(request.url!)")
        return URLSession.shared.dataTaskPublisher(for: request)
            .subscribe(on: DispatchQueue.global())
            .tryMap { data, response -> Data in
                guard let response = response as? HTTPURLResponse else {
                    throw NetworkServiceError.emptyResponse
                }
                
                guard (200 ..< 300) ~= response.statusCode else {
                    throw NetworkServiceError.statusCode(response.statusCode, String(data: data, encoding: .utf8))
                }
                
                print("status code: \(response.statusCode), response: \(String(data: data, encoding: .utf8) ?? "" )")
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
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
