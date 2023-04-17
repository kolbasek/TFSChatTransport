//
//  SSEService.swift
//  TFSChatTransport
//
//  Created by Aleksandr Lis on 26.03.2023.
//

import Combine
import Foundation

public class SSEService: NSObject {
    
    private var publisher: PassthroughSubject<SSEEvent, Error> = .init()
    
    private var urlSession: URLSession!
    
    private let host: String
    private let port: Int
    
    init(host: String, port: Int) {
        self.host = host
        self.port = port
        
        super.init()
        
        urlSession = URLSession(
            configuration: .default,
            delegate: self,
            delegateQueue: nil
        )
    }
    
    func subscribeOnEvents() throws -> AnyPublisher<SSEEvent, Error> {
        guard let request = request(with: "/channels/events") else {
            throw TFSError.makeRequest
        }
        
        urlSession.dataTask(with: request).resume()
        
        return publisher
            .eraseToAnyPublisher()
    }
}

extension SSEService: URLSessionDelegate, URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        print(data)
        let string = String(data: data, encoding: .utf8)?
            .replacingOccurrences(of: "data:", with: "")
        
        guard let data = string?.data(using: .utf8) else {
            return
        }
        
        guard let object = try? JSONDecoder().decode(SSEEvent.self, from: data) else {
            return
        }
        
        publisher.send(object)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else {
            return
        }
        
        publisher.send(completion: .failure(error))
    }
}

private extension SSEService {
    private func request(with path: String) -> URLRequest? {
        var urlComponents = URLComponents()
        urlComponents.scheme = "http"
        urlComponents.host = host
        urlComponents.port = port
        urlComponents.path = path
        
        guard let url = urlComponents.url else {
            return nil
        }
        
        return URLRequest(url: url)
    }
}
