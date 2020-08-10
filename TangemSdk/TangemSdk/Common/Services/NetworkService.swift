//
//  NetworkService.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 07.08.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

protocol NetworkEndpoint {
    var url: URL {get}
    var method: String {get}
    var body: Data? {get}
    var headers: [String:String] {get}
}

enum NetworkServiceError: Error {
    case emptyResponse
    case statusCode(Int, String?)
    case urlSessionError(Error)
    case emptyResponseData
    case mapError
}

class NetworkService {
    func request<T: Decodable>(_ endpoint: NetworkEndpoint, responseType: T.Type, completion: @escaping (Result<T, NetworkServiceError>) -> Void) {
        let request = prepareRequest(from: endpoint)
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
            
            print("status code: \(response.statusCode), response: \(String(data: data, encoding: .utf8))")
            
            if let mapped = self.map(data, type: T.self) {
                completion(.success(mapped))
            } else {
                completion(.failure(.mapError))
            }
        }.resume()
        
    }
    
    private func prepareRequest(from endpoint: NetworkEndpoint) -> URLRequest {
        var urlRequest = URLRequest(url: endpoint.url)
        urlRequest.httpMethod = endpoint.method
        urlRequest.httpBody = endpoint.body
        
        for header in endpoint.headers {
            urlRequest.addValue(header.key, forHTTPHeaderField: header.value)
        }
        
        if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return urlRequest
    }
    
    private func map<T: Decodable>(_ data: Data, type: T.Type) -> T? {
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
