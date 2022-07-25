//
//  WhatsappMessageAPIClient.swift
//  SnapShare
//
//  Created by Faraz Malik on 04/07/2022.
//

import Foundation

enum WhatsappMessageError: Error {
    case requestFailed
    case responseUnsuccessful(statusCode: Int)
    case jsonParsingFailure
    case jsonEncodingFailure
    case invalidURL
}

class WhatsappMessageAPIClient {
    private let whatsappPhoneID = "111101394989431"
    
    private lazy var urlString: String = {
        return "https://graph.facebook.com/v13.0/\(whatsappPhoneID)/messages"
    }()
    
    let decoder = JSONDecoder()
    let encoder = JSONEncoder()
    let session: URLSession
    
    init(withConfiguration configuration: URLSessionConfiguration = .default) {
        self.session = URLSession(configuration: configuration)
        encoder.keyEncodingStrategy = .convertToSnakeCase
    }
    
    // MARK: Typealiases
    
    typealias WhatsappMessageCompletionHandler = (String?, Error?) -> Void
    
    public func sendWhatsappMessage(withAccessToken accessToken: String, message: WhatsappMessage, completionHandler completion: @escaping WhatsappMessageCompletionHandler) {
        guard let url = URL(string: urlString) else {
            completion(nil, WhatsappMessageError.invalidURL)
            return
        }
        
        var request = URLRequest(url: url)
        
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var requestData: Data
        do {
            requestData = try encoder.encode(message)
        } catch {
            completion(nil, WhatsappMessageError.jsonEncodingFailure)
            return
        }
        
        print(String(decoding: requestData, as: UTF8.self))
        
        request.httpMethod = "POST"
        request.httpBody = requestData
        
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let data = data {
                    guard let httpResponse = response as? HTTPURLResponse else {
                        completion(nil, WhatsappMessageError.requestFailed)
                        return
                    }
                    if httpResponse.statusCode == 200 {
                        do {
                            let info = String(decoding: data, as: UTF8.self)
                            completion(info, nil)
                        } catch {
                            completion(nil, WhatsappMessageError.jsonParsingFailure)
                        }
                    } else {
                        completion(nil, WhatsappMessageError.responseUnsuccessful(statusCode: httpResponse.statusCode))
                    }
                    
                } else if let error = error {
                    completion(nil, error)
                }
            }
        }
        
        task.resume()
    }
}
