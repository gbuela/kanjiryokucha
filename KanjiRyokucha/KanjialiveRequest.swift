//
//  KanjialiveRequest.swift
//  KanjiRyokucha
//
//  Created by German Buela on 2/12/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import ReactiveSwift
import Gloss

let kanjialiveDomain = "kanjialive-api.p.mashape.com"
let kanjialiveHost = "https://" + kanjialiveDomain
fileprivate let endpoint = kanjialiveHost + "/api/public/"
let mashapeHeaderKey = "X-Mashape-Key"

protocol KanjialiveRequest : Request {}

extension KanjialiveRequest {
    func requestProducer() -> SignalProducer<Response, FetchError>? {
        guard let rq = self.urlRequest else {
            return nil
        }
        
        return SignalProducer { sink, disposable in
            let session = URLSession.init(configuration: .default,
                                          delegate: NoRedirectSessionDelegate(),
                                          delegateQueue: .main)
            
            let task = session.dataTask(with: rq) { (data, response, error) -> Void in
                
                let status = self.statusCode(response)
                let headers = self.headerFields(response)
                
                switch (data, error) {
                case (_, let error?):
                    sink.send(error: .connectionError(error: error))
                case (let data?, _):
                    log("task completed")
                    let model = self.modelFrom(data: data)
                    
                    if model == nil,
                        let json = data.toJSON(),
                        let error: String = "error" <~~ json {
                        sink.send(error: .backendMessage(message: error))
                    } else {
                        let resp = Response(statusCode: status,
                                            string: String(data:data, encoding:.utf8),
                                            data: data,
                                            model: model,
                                            headers: headers)
                        sink.send(value: resp)
                        sink.sendCompleted()
                    }
                default:
                    sink.sendCompleted()
                }
            }
            log("launching task " + (rq.url?.absoluteString ?? ""))
            
            task.resume()
            session.finishTasksAndInvalidate()
        }
    }
}

private extension KanjialiveRequest {

    var urlRequest: URLRequest? {
        
        guard let encodedApi = apiMethod.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else { return nil }
        
        let uriQs = endpoint + encodedApi + "?" + joinParams(querystringParams)
        
        guard let url = URL(string: uriQs),
            let bodyParams = self.httpBodyParams else {
                return nil
        }
        
        let jsonData = jsonObject?.toJsonData()
        
        var rq = URLRequest(url: url)
        rq.httpMethod = self.httpMethod
        rq.httpBody = contentType == .json ? jsonData : bodyParams
        rq.cachePolicy = .reloadIgnoringLocalCacheData
        
        for header in headers {
            rq.setValue(header.value, forHTTPHeaderField: header.key)
        }
        rq.setValue(ApiKeys.mashape, forHTTPHeaderField: mashapeHeaderKey)
        
        rq.setValue(contentTypeValue(contentType: contentType), forHTTPHeaderField: contentTypeHeaderKey)
        rq.setValue("utf-8", forHTTPHeaderField: "charset") // TODO: needed?
        return rq
    }
}
