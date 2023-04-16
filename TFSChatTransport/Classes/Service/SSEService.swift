//
//  SSEService.swift
//  TFSChatTransport
//
//  Created by Aleksandr Lis on 26.03.2023.
//

import Combine
import Foundation

public class SSEService: NSObject {
    
    private var channelPublisher: PassthroughSubject<ChannelEvent, Error> = .init()
    private var messagePublisher: PassthroughSubject<MessageEvent, Error> = .init()
    
    private var identifiers: [Int: TaskType] = [:]
    
    private var urlSession: URLSession!
    
    private let baseUrl: String
    private let port: Int
    
    init(baseUrl: String, port: Int) {
        self.baseUrl = baseUrl
        self.port = port
        
        super.init()
        
        urlSession = URLSession(
            configuration: .default,
            delegate: self,
            delegateQueue: nil
        )
    }
    
    func subscribeOnChannelsEvens() throws -> AnyPublisher<ChannelEvent, Error> {
        guard let request = request(with: "/channels/events") else {
            throw TFSError.makeRequest
        }
        
        sendRequest(request, with: .channel)
        
        return channelPublisher
            .eraseToAnyPublisher()
    }
    
    func subscribeOnChannelEvens(channelId: String) throws -> AnyPublisher<MessageEvent, Error> {
        guard let request = request(with: "/channels/\(channelId)/events") else {
            throw TFSError.makeRequest
        }
        
        sendRequest(request, with: .message)
        
        return messagePublisher
            .eraseToAnyPublisher()
    }
    
    private func sendRequest(_ request: URLRequest, with taskType: TaskType) {
        let task = urlSession.dataTask(with: request)
        identifiers[task.taskIdentifier] = taskType
        task.resume()
    }
}

extension SSEService: URLSessionDelegate, URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let string = String(data: data, encoding: .utf8)?
            .replacingOccurrences(of: "data:", with: "")
        
        guard let data = string?.data(using: .utf8) else {
            return
        }
        
        if let object = try? JSONDecoder().decode(ChannelEvent.self, from: data) {
            channelPublisher.send(object)
        } else if let object = try? JSONDecoder().decode(MessageEvent.self, from: data) {
            messagePublisher.send(object)
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let type = identifiers[task.taskIdentifier] else {
            return
        }
        
        let err = error ?? TFSError.other
        
        switch type {
        case .channel:
            channelPublisher.send(completion: .failure(err))
        case .message:
            messagePublisher.send(completion: .failure(err))
        }
    }
}

private extension SSEService {
    private func request(with path: String) -> URLRequest? {
        var urlComponents = URLComponents()
        urlComponents.scheme = "http"
        urlComponents.host = baseUrl
        urlComponents.path = path
        urlComponents.port = port
        
        guard let url = urlComponents.url else {
            return nil
        }
        
        return URLRequest(url: url)
    }
}

private enum TaskType {
    case channel
    case message
}
