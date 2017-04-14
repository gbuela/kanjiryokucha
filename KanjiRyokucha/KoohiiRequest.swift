//
//  KoohiiRequest.swift
//  KanjiRyokucha
//
//  Created by German Buela on 2/12/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import ReactiveSwift

enum BuildType {
    case production
    case development
    case staging
}

let buildType: BuildType = {
    if let buildType = Bundle.main.infoDictionary?["BUILDTYPE"] as? String {
        if buildType == "DEV" {
            return .development
        } else if buildType == "STAGING" {
            return .staging
        } else if buildType == "PROD" {
            return .production
        }
    }
    fatalError("Undefined or unknown BUILDTYPE in Info.plist!")
}()

let koohiiDomain: String = {
    switch buildType {
    case .production:
        return "kanji.koohii.com"
    case .development:
        return "localhost:8888"
    case .staging:
        return "staging.koohii.com"
    }
}()

let koohiiProtocol: String = {
    switch buildType {
    case .production:
        return "http"
    default:
        return "http"
    }
}()

let koohiiHost = koohiiProtocol + "://" + koohiiDomain
fileprivate let endpoint = koohiiHost + "/api/v1/"

protocol KoohiiRequest : Request {
    var guestResult: String? { get }
}

extension KoohiiRequest {
    func guestProducer() -> SignalProducer<Response, FetchError>? {
        guard let result = guestResult,
            let data = result.data(using: .utf8) else { return nil }
        let model = self.modelFrom(data: data)
        let resp = Response(statusCode: 200,
                            string: result,
                            data: data,
                            model: model,
                            headers: headers)

        return SignalProducer { sink, disposable in
            sink.send(value: resp)
            sink.sendCompleted()
        }
    }
}

extension KoohiiRequest {
    func requestProducer() -> SignalProducer<Response, FetchError>? {
        
        guard !Global.isGuest() else {
            return guestProducer()
        }
        
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
                    log("task failed! \(error)")
                    sink.send(error: .connectionError(error: error))
                case (let data?, _):
                    log("task completed")
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
            log("launching task " + (rq.url?.absoluteString ?? ""))
            
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
