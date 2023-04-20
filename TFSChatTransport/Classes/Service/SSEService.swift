//
//  SSEService.swift
//  TFSChatTransport
//
//  Created by Aleksandr Lis on 26.03.2023.
//

import Combine
import Foundation

public class SSEService: NSObject {
    
    private var publisher: PassthroughSubject<ChatEvent, Error> = .init()
    
    private var urlSession: URLSession!
    
    private let host: String
    private let port: Int
    
    public init(host: String, port: Int) {
        self.host = host
        self.port = port
        
        super.init()
        
        urlSession = URLSession(
            configuration: .default,
            delegate: self,
            delegateQueue: nil
        )
    }

    /// Создает подписку на события о изменениях в списке каналов
    public func subscribeOnEvents() -> AnyPublisher<ChatEvent, Error> {
        guard let request = request(with: "/channels/events") else {
            return Fail(error: NSError(domain: "SSEService",
                                code: -1,
                                userInfo: [NSLocalizedFailureReasonErrorKey: "Could not construct url with components"]))
                    .eraseToAnyPublisher()
        }
        
        urlSession.dataTask(with: request).resume()

        return publisher
            .eraseToAnyPublisher()
    }

    /// Останавливает прием событий и разрывает цикл сильных ссылок в URLSession
    /// ВАЖНО! Необходимо вызывать перед удалением последней сильной ссылки на сервис
    public func cancelSubscription() {
        publisher.send(completion: .finished)
        urlSession.invalidateAndCancel()
    }
}

extension SSEService: URLSessionDelegate, URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let string = String(data: data, encoding: .utf8)?
            .replacingOccurrences(of: "data:", with: "")
        
        guard
            let data = string?.data(using: .utf8),
            let object = try? JSONDecoder().decode(ChatEvent.self, from: data)
        else {
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
