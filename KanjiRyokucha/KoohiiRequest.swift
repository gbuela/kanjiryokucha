//
//  KoohiiRequest.swift
//  KanjiRyokucha
//
//  Created by German Buela on 2/12/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import ReactiveSwift

func resolveDomain() -> String {
    if let dev = Bundle.main.infoDictionary?["DEVBUILD"] as? Bool,
        dev {
        return "localhost:8888"
    } else {
        return "kanji.koohii.com"
    }
}

let koohiiDomain = resolveDomain()
let koohiiHost = "http://" + koohiiDomain
fileprivate let endpoint = koohiiHost + "/api/v1/"

protocol KoohiiRequest : Request {}

extension KoohiiRequest {
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
                    print("task completed")
                    if let json = data.toJSON(),
                        let statResult = StatResult(json: json),
                        statResult.status == "fail",
                        statResult.code == 96 {
                        sink.send(error: .notAuthenticated)
                        NotificationCenter.default.post(name: NSNotification.Name(sessionExpiredNotification), object: nil)
                    }
                    else {
                        let model = self.modelFrom(data: data)
                        let resp = Response(statusCode: status,
                                            string: String(data:data, encoding:.utf8),
                                            data: data,
                                            model: model,
                                            headers: headers)
                        resp.saveCookies()
                        sink.send(value: resp)
                        sink.sendCompleted()
                    }
                default:
                    sink.sendCompleted()
                }
            }
            print("launching task " + (rq.url?.absoluteString ?? ""))
            
            task.resume()
            session.finishTasksAndInvalidate()
        }
    }
}

private extension KoohiiRequest {
    
    var urlRequest: URLRequest? {
        let qsParams = sendApiKey ? querystringParams.merged(with: ["api_key":ApiKeys.koohii]) : querystringParams
        
        let uriQs = (useEndpoint ? endpoint : koohiiHost) + apiMethod + "?" + joinParams(qsParams)
        
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
        
        rq.setValue(contentTypeValue(contentType: contentType), forHTTPHeaderField: contentTypeHeaderKey)
        rq.setValue("utf-8", forHTTPHeaderField: "charset")
        return rq
    }
}
