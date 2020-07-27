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

protocol BackendAccess {
    var backendDomain: String { get }
    var backendProtocol: String { get }
    var backendHost: String { get }
}

extension BackendAccess {
    var backendDomain: String {
        switch buildType {
        case .production:
            return "kanji.koohii.com"
        case .development:
            return "localhost:8888"
        case .staging:
            return "staging.koohii.com"
        }
    }
    
    var backendProtocol: String {
        switch buildType {
        case .development:
            return "http"
        default:
            return "https"
        }
    }
    
    var backendHost: String {
        return backendProtocol + "://" + backendDomain
    }
}

protocol KoohiiRequest : Request, BackendAccess {
    var endpoint: String { get }
}

extension KoohiiRequest {
    
    var endpoint: String {
        return backendHost + "/api/v1/"
    }
}

extension KoohiiRequest {
    
    private func isSessionExpired(data: Data) -> Bool {
        let decoder = JSONDecoder()
        let statResult: StatResult
        do {
            statResult = try decoder.decode(StatResult.self, from: data)
            if statResult.status == "fail",
                statResult.code == 96 {
                return true
            }
            return false
        } catch {
            return false
        }
    }
    
    func requestProducer() -> SignalProducer<Response, FetchError>? {
        guard let rq = self.urlRequest else {
            return nil
        }
        
        return SignalProducer { sink, disposable in
            let session = URLSession.init(configuration: .default,
                                          delegate: NoRedirectSessionDelegate(),
                                          delegateQueue: .main)
            
            Global.latestRequestDate = Date()
            
            let task = session.dataTask(with: rq) { (data, response, error) -> Void in
                
                let status = self.statusCode(response)
                let headers = self.headerFields(response)
                
                switch (data, error) {
                case (_, let error?):
                    log("task failed! \(error)")
                    sink.send(error: .connectionError(error: error))
                case (let data?, _):
                    log("task completed")
                    if self.isSessionExpired(data: data) {
                        log("Session expired found in \(self.apiMethod)")
                        
                        if self is AccountInfoRequest {
                            log("Delaying expiration result")
                            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                                sink.send(error: .notAuthenticated)
                                NotificationCenter.default.post(name: NSNotification.Name(sessionExpiredNotification), object: nil)
                            })
                        } else {
                            sink.send(error: .notAuthenticated)
                            NotificationCenter.default.post(name: NSNotification.Name(sessionExpiredNotification), object: nil)
                        }
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
    
    var isApiPublic: Bool {
        return true
    }
    
    var urlRequest: URLRequest? {
        let qsParams = sendApiKey && !isApiPublic ? querystringParams.merged(with: ["api_key":ApiKeys.koohii]) : querystringParams
        
        let uriQs = (useEndpoint ? endpoint : backendHost) + apiMethod + "?" + joinParams(qsParams)
        
        guard let url = URL(string: uriQs),
            let bodyParams = self.httpBodyParams else {
                return nil
        }
        
        var rq = URLRequest(url: url)
        rq.httpMethod = self.httpMethod
        rq.httpBody = contentType == .json ? jsonObject?.toJsonData() : bodyParams
        rq.cachePolicy = .reloadIgnoringLocalCacheData
        
        for header in headers {
            rq.setValue(header.value, forHTTPHeaderField: header.key)
        }
        
        rq.setValue(contentTypeValue(contentType: contentType), forHTTPHeaderField: HeaderKeys.contentType)
        rq.setValue("utf-8", forHTTPHeaderField: HeaderKeys.charset)
        return rq
    }
}
