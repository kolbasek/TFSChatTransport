//
//  ChatService.swift
//  Pods-TFSChatTransport_Example
//
//  Created by p.baranov on 06.03.2023.
//

import Foundation
import Combine

public class ChatService {
    
    private let host: String
    private let port: Int
    private let urlSession: URLSession
    
    public init(host: String, port: Int, urlSession: URLSession = URLSession.shared) {
        self.host = host
        self.port = port
        self.urlSession = urlSession
    }
    
    // MARK: - Channels

    /// Создает новый канал и возвращает его модель
    /// - Parameters:
    ///     - name: Имя отправителя
    ///     - logoUrl: Ссылка на логотип
    public func createChannel(name: String, logoUrl: String? = nil) -> AnyPublisher<Channel, Error> {
        let session = self.urlSession
        var object: [String: Codable] = [:]
        object["name"] = name
        object["logoURL"] = logoUrl
        let decoder = makeJSONDecoder()
        return makePostRequest(path: "/channels", bodyObject: object)
            .flatMap { session.dataTaskPublisher(for: $0).mapError { $0 as Error } }
            .tryMap { try ChatService.handleStatusCode($0) }
            .map(\.data)
            .decode(type: Channel.self, decoder: decoder)
            .eraseToAnyPublisher()
    }

    /// Загружает все каналы
    public func loadChannels() -> AnyPublisher<[Channel], Error> {
        let session = self.urlSession
        let decoder = makeJSONDecoder()
        return makeGetRequest(path: "/channels")
            .flatMap { session.dataTaskPublisher(for: $0).mapError { $0 as Error } }
            .tryMap { try ChatService.handleStatusCode($0) }
            .map(\.data)
            .decode(type: [Channel].self, decoder: decoder)
            .eraseToAnyPublisher()
    }

    /// Загружает информацию о канале
    /// - Parameter id: id канала
    public func loadChannel(id: String) -> AnyPublisher<Channel, Error> {
        let session = self.urlSession
        let decoder = makeJSONDecoder()
        return makeGetRequest(path: "/channels/\(id)")
            .flatMap { session.dataTaskPublisher(for: $0).mapError { $0 as Error } }
            .tryMap { try ChatService.handleStatusCode($0) }
            .map(\.data)
            .decode(type: Channel.self, decoder: decoder)
            .eraseToAnyPublisher()
    }

    /// Удаляет канал
    /// - Parameters:
    ///     - id: id канала
    public func deleteChannel(id: String) -> AnyPublisher<Void, Error> {
        let session = self.urlSession
        return makeDeleteRequest(path: "/channels/\(id)")
            .flatMap { session.dataTaskPublisher(for: $0).mapError { $0 as Error } }
            .tryMap { try ChatService.handleStatusCode($0, acceptingStatusCodes: [200, 204]) }
            .map { _ in return () }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Messages

    /// Загружает сообщения из канала
    /// - Parameters:
    ///     - channelId: id канала
    public func loadMessages(channelId: String) -> AnyPublisher<[Message], Error> {
        let session = self.urlSession
        let decoder = makeJSONDecoder()
        return makeGetRequest(path: "/channels/\(channelId)/messages")
            .flatMap { session.dataTaskPublisher(for: $0).mapError { $0 as Error } }
            .tryMap { try ChatService.handleStatusCode($0) }
            .map(\.data)
            .decode(type: [Message].self, decoder: decoder)
            .eraseToAnyPublisher()
    }

    /// Создает новое сообщение и возвращает его модель
    /// - Parameters:
    ///     - text: текст сообщения
    ///     - channelId: id канала
    ///     - userId: id отправителя
    ///     - userName: имя отправителя
    public func sendMessage(text: String, channelId: String, userId: String, userName: String) -> AnyPublisher<Message, Error> {
        let session = self.urlSession
        let decoder = makeJSONDecoder()
        return makePostRequest(path: "/channels/\(channelId)/messages", bodyObject: ["userID": userId, "userName": userName, "text": text])
            .flatMap { session.dataTaskPublisher(for: $0).mapError { $0 as Error } }
            .tryMap { try ChatService.handleStatusCode($0) }
            .map(\.data)
            .decode(type: Message.self, decoder: decoder)
            .eraseToAnyPublisher()
    }
}

private extension ChatService {
    
    // MARK: - Make URL
    
    private func makeUrl(path: String) -> AnyPublisher<URL, Error> {
        var urlComponents = URLComponents()
        urlComponents.scheme = "http"
        urlComponents.host = host
        urlComponents.path = path
        urlComponents.port = port
        
        guard let url = urlComponents.url else {
            let errorMessage = "Could not construct url with components: \(urlComponents)"
            return Fail(error: NSError(domain: "ChatServiceError",
                                       code: -1,
                                      userInfo: [NSLocalizedFailureReasonErrorKey: errorMessage]))
            .eraseToAnyPublisher()
        }
        
        return Just(url)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Make requests
    
    private func makeGetRequest(path: String) -> AnyPublisher<URLRequest, Error> {
        makeUrl(path: path)
            .flatMap {
                var request = URLRequest(url: $0)
                request.httpMethod = "GET"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                return Just(request).setFailureType(to: Error.self)
            }
            .eraseToAnyPublisher()
    }
    
    private func makePostRequest(path: String, bodyObject: [String: Codable]) -> AnyPublisher<URLRequest, Error> {
        makeUrl(path: path)
            .tryMap {
                var request = URLRequest(url: $0)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                request.httpBody = try JSONSerialization.data(withJSONObject: bodyObject)
                return request
            }
            .flatMap {
                Just($0).setFailureType(to: Error.self)
            }
            .eraseToAnyPublisher()
    }
    
    private func makeDeleteRequest(path: String) -> AnyPublisher<URLRequest, Error> {
        makeUrl(path: path)
            .flatMap {
                var request = URLRequest(url: $0)
                request.httpMethod = "DELETE"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                return Just(request).setFailureType(to: Error.self)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Decoding
    
    private func makeJSONDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
          .withFullDate,
          .withFullTime,
          .withFractionalSeconds
          ]

        decoder.dateDecodingStrategy = .custom({ decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
        })
        return decoder
    }
    
    private static func handleStatusCode(_ response: URLSession.DataTaskPublisher.Output,
                                         acceptingStatusCodes: [Int] = [200]) throws -> (URLSession.DataTaskPublisher.Output) {
        guard let httpResponse = response.response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard acceptingStatusCodes.contains(httpResponse.statusCode) else {
            let errorMessage = """
                Wrong response status code. Excepted: \(acceptingStatusCodes), but got: \(httpResponse.statusCode).
                
                Response body: \( String(data: response.data, encoding: .utf8) ?? "" )
                """
            throw NSError(domain: "TFSChatTransportError", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        return response
    }
    
}
