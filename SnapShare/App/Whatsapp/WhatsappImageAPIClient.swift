//
//  WhatsappMediaAPIClient.swift
//  SnapShare
//
//  Created by Faraz Malik on 04/07/2022.
//

import Foundation
import UIKit

enum WhatsappImageError: Error {
    case requestFailed
    case responseUnsuccessful(statusCode: Int)
    case jsonParsingFailure
    case invalidURL
}

class WhatsappImageAPIClient {
    private let whatsappPhoneID = "111101394989431"
    
    // returns the base url string with the phone ID attached, when accessed
    private lazy var urlString: String = {
        return "https://graph.facebook.com/v13.0/\(whatsappPhoneID)/media"
    }()
    
    let decoder = JSONDecoder()
    let session: URLSession
    
    init(withConfiguration configuration: URLSessionConfiguration = .default) {
        self.session = URLSession(configuration: configuration)
    }
    
    // MARK: Typealiases
    
    typealias WhatsappImageCompletionHandler = (WhatsappImage?, Error?) -> Void
    
    
    // MARK: Post Whatsapp Image
    // called to upload image to WhatsApp via Facebook Graph API
    // calls escaping completion handler to pass up data or error appropriately.
    public func postWhatsappImage(withAccessToken accessToken: String, imageData: Data, completionHandler completion: @escaping WhatsappImageCompletionHandler) {
        
        // creates URL from URL string
        guard let url = URL(string: urlString) else {
            completion(nil, WhatsappImageError.invalidURL)
            return
        }
        
        // gets a boundary string to work with for this request
        let boundaryString = getBoundaryString()
        
        // creates a request
        var request = URLRequest(url: url)
        
        // adds access token and content type as fields in the header
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundaryString)", forHTTPHeaderField: "Content-Type")
        
        // required parameter for form-data in body
        //let parameters = ["messaging_product": "whatsapp", "type": "image/jpeg"]
        let parameters: [[String: Any]] = [
            [
                "key": "messaging_product",
                "value": "whatsapp",
                "type": "text"
            ],
            [
                "key": "type",
                "value": "image/jpeg",
                "type": "text"
            ],
            [
                "key": "file",
                "type": "file"
            ]
        ]
        
        // gets and assigns body, formatted to form-data with parameters and image data
        let requestData = createBody(withParameters: parameters, imageData: imageData, boundary: boundaryString)

        request.httpMethod = "POST"
        request.httpBody = requestData
        
        // sends request asynchronously (i.e. background)
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                // if we got a response
                if let data = data {
                    // if we can cast response as HTTPURLResponse
                    guard let httpResponse = response as? HTTPURLResponse else {
                        completion(nil, WhatsappImageError.requestFailed)
                        return
                    }
                    // if it's ok
                    if httpResponse.statusCode == 200 {
                        do {
                            // try to decode it
                            let whatsappImageID = try self.decoder.decode(WhatsappImage.self, from: data)
                            // pass up to completion handler
                            completion(whatsappImageID, nil)
                        } catch {
                            // pass up to completion handler
                            completion(nil, WhatsappImageError.jsonParsingFailure)
                        }
                    } else {
                        // pass up to completion handler
                        completion(nil, WhatsappImageError.responseUnsuccessful(statusCode: httpResponse.statusCode))
                    }
                    
                } else if let error = error {
                    // pass up error
                    completion(nil, error)
                }
            }
        }
        
        task.resume()
    }
    
    // creates body data (error could very well lie here because 400 bad request means body is malformed)
    // please give this a look (image is always jpeg)
    private func createBody(withParameters parameters: [[String: Any]], imageData: Data, boundary: String) -> Data {
        
        let body = NSMutableData()
        let contentType = "image/jpeg"
                
        for param in parameters {
            if param["disabled"] == nil {
                let paramName = param["key"]!
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition:form-data; name=\"\(paramName)\"".data(using: .utf8)!)
                if param["contentType"] != nil {
                    body.append("\r\nContent-Type: \(param["contentType"] as! String)".data(using: .utf8)!)
                }
                let paramType = param["type"] as! String
                if paramType == "text" {
                    let paramValue = param["value"] as! String
                    body.append("\r\n\r\n\(paramValue)\r\n".data(using: .utf8)!)
                } else {
                    let filename = "upload.jpeg"

                    body.append("; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
                    body.append("Content-Type: \(contentType)\r\n\r\n".data(using: .utf8)!)
                    body.append(imageData)
                    body.append("\r\n".data(using: .utf8)!)
                }
            }
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body as Data
    }
    
    private func getBoundaryString() -> String {
        let boundary = UUID().uuidString
        return boundary
    }
}
