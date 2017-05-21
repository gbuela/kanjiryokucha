//
//  Services.swift
//  github-users
//
//  Created by German Buela on 5/19/16.
//  Copyright © 2016 German Buela. All rights reserved.
//

import Foundation
import ReactiveSwift
import Gloss
import Result

var times = -1

struct HeaderKeys {
    static let location = "Location"
    static let setCookie = "Set-Cookie"
    static let contentType = "Content-Type"
    static let charset = "charset"
}

enum FetchError : Error {
    case backendMessage(message:String)
    case connectionError(error:Error)
    case parseError
    case notAuthenticated
}

extension FetchError {
    var uiMessage: String {
        switch self {
        case .connectionError(error: let error): return error.localizedDescription
        case .parseError: return "Error parsing result"
        case .notAuthenticated: return "No active session! You need to login"
        case .backendMessage: return "Stroke order not available for this kanji"
        }
    }
}

extension Dictionary {
    func merged(with dictionary: Dictionary<Key,Value>) -> Dictionary<Key,Value> {
        var copy = self
        dictionary.forEach { copy.updateValue($1, forKey: $0) }
        return copy
    }
}

extension Data {
    func toJSON() -> JSON? {
        do {
            let object = try JSONSerialization.jsonObject(with: self, options: .allowFragments)
            if let dict = object as? JSON {
                return dict
            }
            return nil
        } catch {
            return nil
        }
    }
}

extension Encodable {
    func toJsonData() -> Data? {
        guard let jsonDict = self.toJSON() else {
            return nil
        }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
            return jsonData
        } catch {
            return nil
        }
    }
}

struct Response {
    let statusCode: Int
    let string: String?
    let data: Data?
    let model: Decodable?
    let headers: [AnyHashable : Any]
    
    static var latestCookies: [String]?
    
    func saveCookies() {
        var cookies: [String] = []
        for header in headers {
            if let key = header.key as? String,
                key == HeaderKeys.setCookie,
                let value = header.value as? String {
                cookies.append(value)
            }
        }
        if cookies.count > 0 {
            Response.latestCookies = cookies
        }
    }
}

class NoRedirectSessionDelegate : NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}

struct StatResult: Decodable {
    let status: String?
    let code: Int?
    
    init?(json: JSON) {
        self.status = "stat" <~~ json
        self.code = "code" <~~ json
    }
}

enum RequestMethod {
    case get
    case post
}
enum ContentType {
    case form
    case json
}

typealias ParamSet = [String:String]

protocol Request {
    associatedtype ModelType: Decodable
    var apiMethod: String { get }
    var useEndpoint: Bool { get }
    var sendApiKey: Bool { get }
    var method: RequestMethod { get }
    var contentType: ContentType { get }
    var jsonObject: Encodable? { get }
    var querystringParams: ParamSet { get }
    var postParams: ParamSet { get }
    var headers: ParamSet { get }
    
    func requestProducer() -> SignalProducer<Response, FetchError>?
}

extension Request {
    
    var jsonObject: Encodable? {
        return nil
    }
    
    var querystringParams: ParamSet {
        return [:]
    }
    
    var postParams: ParamSet {
        return [:]
    }
    
    var headers: ParamSet {
        return [:]
    }
    
    func modelFrom(data: Data) -> ModelType? {
        if let json = data.toJSON() {
            return ModelType(json: json)
        } else {
            return nil
        }
    }
    
    func statusCode(_ urlResponse: URLResponse?) -> Int {
        if let httpResponse = urlResponse as? HTTPURLResponse {
            return httpResponse.statusCode
        } else {
            return 0
        }
    }
    
    func headerFields(_ urlResponse: URLResponse?) -> [AnyHashable : Any] {
        if let httpResponse = urlResponse as? HTTPURLResponse {
            return httpResponse.allHeaderFields
        } else {
            return [:]
        }
    }
    
    var httpMethod: String {
        get {
            switch(method) {
            case .get: return "GET"
            case .post: return "POST"
            }
        }
    }
    
    func joinParams(_ paramsDict: ParamSet) -> String {
        let params = paramsDict.map { (key: String, value: String) -> String in
            if let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                let encodedValue = value.addingPercentEncodingForURLQueryValue() {
                return encodedKey + "=" + encodedValue
            } else {
                return ""
            }
        }
        let joined = params.joined(separator: "&")
        return joined
    }
    
    var httpBodyParams: Data? {
        get {
            let joined = joinParams(postParams)
            return joined.data(using: .utf8)
        }
    }
    
    func contentTypeValue(contentType: ContentType) -> String {
        switch contentType {
        case .form:
            return "application/x-www-form-urlencoded"
        case .json:
            return "application/json"
        }
    }
}


/*
 From http://stackoverflow.com/a/35912606/17138
 This solves escaping issues, eg with passwords containing characters like &
 */

extension String {
    
    /// Returns a new string made from the `String` by replacing all characters not in the unreserved
    /// character set (as defined by RFC3986) with percent encoded characters.
    
    func addingPercentEncodingForURLQueryValue() -> String? {
        let allowedCharacters = CharacterSet.urlQueryValueAllowed()
        return addingPercentEncoding(withAllowedCharacters: allowedCharacters)
    }
    
}

extension CharacterSet {
    
    /// Returns the character set for characters allowed in the individual parameters within a query URL component.
    ///
    /// The query component of a URL is the component immediately following a question mark (?).
    /// For example, in the URL `http://www.example.com/index.php?key1=value1#jumpLink`, the query
    /// component is `key1=value1`. The individual parameters of that query would be the key `key1`
    /// and its associated value `value1`.
    ///
    /// According to RFC 3986, the set of unreserved characters includes
    ///
    /// `ALPHA / DIGIT / "-" / "." / "_" / "~"`
    ///
    /// In section 3.4 of the RFC, it further recommends adding `/` and `?` to the list of unescaped characters
    /// for the sake of compatibility with some erroneous implementations, so this routine also allows those
    /// to pass unescaped.
    
    
    static func urlQueryValueAllowed() -> CharacterSet {
        return CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~/?")
    }
    
}
