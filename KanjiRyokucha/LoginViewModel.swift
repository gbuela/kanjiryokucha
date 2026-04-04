//
//  LoginController.swift
//  KanjiRyokucha
//
//  Created by German Buela on 3/4/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import Foundation
import ReactiveSwift
import RealmSwift

enum LoginState {
    case loggingIn
    case loggedIn
    case failure(String)
    
    func isLoggingIn() -> Bool {
        guard case .loggingIn = self else { return false }
        return true
    }
    
    func isFailure() -> Bool {
        guard case .failure(_) = self else { return false }
        return true
   }
}

struct LoginViewModel : BackendAccess {
    let state: MutableProperty<LoginState> = MutableProperty(.loggingIn)
    let credentialsRequired: MutableProperty<Bool> = MutableProperty(false)
    
    let sendLoginNotification: Bool
 
    func autologin() {
        let defaults = UserDefaults()
        if let username = defaults.object(forKey: usernameKey) as? String,
            let password = defaults.object(forKey: passwordKey) as? String {
            attemptLogin(withUsername: username, password: password)
        } else {
            credentialsRequired.value = true
        }
    }
    
    func attemptLogin(withUsername username: String, password: String) {
        state.value = .loggingIn
        
        callLogin(username: username, password: password, handler: loginHandler)
    }
    
    func loginHandler(success: Bool, username: String?) {
        if success,
            let username = username {
            setDefaultRealmForUser(username: username)
            if sendLoginNotification {
                NotificationCenter.default.post(name: NSNotification.Name(sessionStartedNotification), object: username)
            }
        }
    }
    
    private func setDefaultRealmForUser(username: String) {
        var config = Realm.ConfigurationWithMigration()
        
        config.fileURL = config.fileURL!.deletingLastPathComponent()
            .appendingPathComponent("\(username).realm")
        
        Realm.Configuration.defaultConfiguration = config
        Global.username = username
    }
    
    private func callLogin(username:String, password:String, handler:@escaping ((Bool,String?) -> Void)) {
        clearSessionCookies()
        let loginPageRequest = LoginPageRequest()
        if let sp = loginPageRequest.requestProducer()?.observe(on: UIScheduler()) {
            sp.startWithResult { (result: Result<Response, FetchError>) in
                switch result {
                case .success(let response):
                    let html = response.string ?? ""
                    let formDetails = self.parseLoginFormDetails(from: html)
                    let hiddenParams = formDetails.hiddenParams
                        .merged(with: self.parseHiddenInputs(from: html))
                    let csrfParams = self.parseCsrfMeta(from: html)
                    let scriptCsrfParams = self.parseCsrfScript(from: html)
                    let mergedParams = hiddenParams
                        .merged(with: csrfParams)
                        .merged(with: scriptCsrfParams)
                    if !mergedParams.isEmpty {
                        log("login page hidden params: \(mergedParams.keys.sorted().joined(separator: ", "))")
                    }
                    if !formDetails.inputNames.isEmpty {
                        log("login form inputs: \(formDetails.inputNames.sorted().joined(separator: ", "))")
                    }
                    let loginAction = formDetails.action ?? self.parseLoginFormAction(from: html)
                    if let loginAction = loginAction {
                        log("login form action: \(loginAction)")
                    }
                    self.logLoginPageHints(from: html)
                    self.performLogin(username: username,
                                      password: password,
                                      hiddenParams: mergedParams,
                                      loginAction: loginAction,
                                      usernameFieldName: formDetails.usernameFieldName,
                                      passwordFieldName: formDetails.passwordFieldName,
                                      submitParams: formDetails.submitParams,
                                      handler: handler)
                case .failure(let error):
                    handler(false, nil)
                    self.state.value = .failure("\(error.errorText())  🔥")
                }
            }
        }
    }

    private func performLogin(username: String,
                              password: String,
                              hiddenParams: ParamSet,
                              loginAction: String?,
                              usernameFieldName: String?,
                              passwordFieldName: String?,
                              submitParams: ParamSet,
                              handler:@escaping ((Bool,String?) -> Void)) {
        let loginRq = LoginRequest(username: username,
                                   password: password,
                                   usernameFieldName: usernameFieldName ?? "username",
                                   passwordFieldName: passwordFieldName ?? "password",
                                   extraParams: hiddenParams,
                                   submitParams: submitParams,
                                   apiMethod: loginAction ?? "/login")
        
        if let sp = loginRq.requestProducer()?.observe(on: UIScheduler()) {
            
            sp.startWithResult { (result: Result<Response, FetchError>) in
                switch result {
                case .success(let response):
                    let location = response.headers[HeaderKeys.location] as? String ?? ""
                    let hasCookie = (response.headers[HeaderKeys.setCookie] as? String) != nil
                    log("login response status=\(response.statusCode) location=\(location) set-cookie=\(hasCookie)")
                    if let body = response.string {
                        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
                        let prefix = String(trimmed.prefix(200))
                        if !prefix.isEmpty {
                            log("login response body prefix=\(prefix)")
                        }
                    }

                    if response.statusCode == httpStatusMovedTemp,
                        location.hasPrefix(self.backendHost) {
                        if let cookie = response.headers[HeaderKeys.setCookie] as? String {
                            Response.latestCookies = [ cookie ]
                        }
                        self.fetchRedirectTargetIfNeeded(location: location) {
                            self.verifySession(expectedUsername: username, handler: handler)
                        }
                    } else {
                        handler(false, nil)
                        self.state.value = .failure("Could not login 🤔")
                    }
                case .failure(let error):
                    handler(false, nil)
                    self.state.value = .failure("\(error.errorText())  🔥")
                }
            }
        }
    }

    private func verifySession(expectedUsername: String?, handler:@escaping ((Bool,String?) -> Void)) {
        let verifyRq = AccountInfoRequest()
        if let sp = verifyRq.requestProducer()?.observe(on: UIScheduler()) {
            sp.startWithResult { (result: Result<Response, FetchError>) in
                switch result {
                case .success(let response):
                    let username = (response.model as? AccountInfoModel)?.username ?? expectedUsername
                    if let username = username, !username.isEmpty {
                        handler(true, username)
                        self.state.value = .loggedIn
                    } else {
                        log("login verify succeeded without username")
                        handler(false, nil)
                        self.state.value = .failure("Could not login 🤔")
                    }
                case .failure(let error):
                    log("login verify failed: \(error.errorText())")
                    handler(false, nil)
                    self.state.value = .failure("Could not login 🤔")
                }
            }
        } else {
            handler(false, nil)
            self.state.value = .failure("Could not login 🤔")
        }
    }

    private func clearSessionCookies() {
        let storage = HTTPCookieStorage.shared
        let allCookies = storage.cookies ?? []
        for cookie in allCookies where cookie.domain.contains(backendDomain) {
            storage.deleteCookie(cookie)
        }
        Response.latestCookies = nil
    }

    private func fetchRedirectTargetIfNeeded(location: String, completion: @escaping () -> Void) {
        guard let url = URL(string: location) else {
            completion()
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: request) { data, response, error in
            let status = response.flatMap { $0 as? HTTPURLResponse }?.statusCode ?? 0
            let headers = (response as? HTTPURLResponse)?.allHeaderFields ?? [:]
            let hasCookie = headers[HeaderKeys.setCookie] != nil
            log("login redirect fetch status=\(status) set-cookie=\(hasCookie) data-bytes=\(data?.count ?? 0)")
            if let error = error {
                log("login redirect fetch error=\(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                completion()
            }
        }
        task.resume()
    }

    private func parseHiddenInputs(from html: String) -> ParamSet {
        var params: ParamSet = [:]
        let pattern = "<input[^>]*type=[\\\"\\']hidden[\\\"][^>]*>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return params
        }

        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, options: [], range: range)
        for match in matches {
            guard let matchRange = Range(match.range, in: html) else { continue }
            let inputTag = String(html[matchRange])
            guard let name = extractAttribute("name", from: inputTag) else { continue }
            let value = extractAttribute("value", from: inputTag) ?? ""
            params[name] = decodeHtmlEntities(value)
        }
        return params
    }

    private func parseCsrfMeta(from html: String) -> ParamSet {
        var params: ParamSet = [:]
        guard let csrfParam = extractMetaContent(name: "csrf-param", from: html),
              let csrfToken = extractMetaContent(name: "csrf-token", from: html) else {
            return params
        }
        params[csrfParam] = decodeHtmlEntities(csrfToken)
        return params
    }

    private func parseLoginFormDetails(from html: String) -> (action: String?, inputNames: [String], usernameFieldName: String?, passwordFieldName: String?, hiddenParams: ParamSet, submitParams: ParamSet) {
        guard let formHtml = extractFirstForm(from: html) else {
            return (nil, [], nil, nil, [:], [:])
        }

        let inputTags = extractInputTags(from: formHtml)
        var inputNames: [String] = []
        var hiddenParams: ParamSet = [:]
        var submitParams: ParamSet = [:]
        var usernameFieldName: String?
        var passwordFieldName: String?

        for tag in inputTags {
            let name = extractAttribute("name", from: tag)
            let value = extractAttribute("value", from: tag) ?? ""
            let type = (extractAttribute("type", from: tag) ?? "").lowercased()

            if let name = name, !name.isEmpty {
                inputNames.append(name)
            }

            if type == "hidden", let name = name {
                hiddenParams[name] = decodeHtmlEntities(value)
            }

            if type == "submit", let name = name {
                submitParams[name] = decodeHtmlEntities(value)
            }

            if passwordFieldName == nil, type == "password", let name = name {
                passwordFieldName = name
            }

            if usernameFieldName == nil,
               let name = name,
               (type == "text" || type == "email" || type.isEmpty) {
                let lowerName = name.lowercased()
                if lowerName.contains("user") || lowerName.contains("login") || lowerName.contains("email") {
                    usernameFieldName = name
                }
            }
        }

        let action = extractAttribute("action", from: formHtml).flatMap { normalizeFormAction($0) }
        return (action, inputNames, usernameFieldName, passwordFieldName, hiddenParams, submitParams)
    }

    private func parseCsrfScript(from html: String) -> ParamSet {
        var params: ParamSet = [:]
        if let token = matchFirst(in: html, pattern: "csrf-token\"\\s*:\\s*\"([^\"]+)") {
            params["authenticity_token"] = decodeHtmlEntities(token)
            return params
        }
        if let token = matchFirst(in: html, pattern: "csrfToken\"\\s*:\\s*\"([^\"]+)") {
            params["authenticity_token"] = decodeHtmlEntities(token)
            return params
        }
        if let token = matchFirst(in: html, pattern: "csrfToken\\s*=\\s*\"([^\"]+)") {
            params["authenticity_token"] = decodeHtmlEntities(token)
            return params
        }
        if let token = matchFirst(in: html, pattern: "csrf-token\\s*\"?\\s*content=\\\"([^\\\"]+)") {
            params["authenticity_token"] = decodeHtmlEntities(token)
            return params
        }
        return params
    }

    private func parseLoginFormAction(from html: String) -> String? {
        let pattern = "<form[^>]*>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let range = NSRange(html.startIndex..., in: html)
        guard let match = regex.firstMatch(in: html, options: [], range: range),
              let tagRange = Range(match.range, in: html) else {
            return nil
        }
        let formTag = String(html[tagRange])
        guard let action = extractAttribute("action", from: formTag) else {
            return nil
        }
        return normalizeFormAction(action)
    }

    private func extractMetaContent(name: String, from html: String) -> String? {
        let pattern = "<meta[^>]*name=[\\\"\\']\(name)[\\\"\\'][^>]*>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let range = NSRange(html.startIndex..., in: html)
        guard let match = regex.firstMatch(in: html, options: [], range: range),
              let tagRange = Range(match.range, in: html) else {
            return nil
        }
        let metaTag = String(html[tagRange])
        return extractAttribute("content", from: metaTag)
    }

    private func extractFirstForm(from html: String) -> String? {
        guard let formStartRange = html.range(of: "<form", options: [.caseInsensitive]) else {
            return nil
        }
        guard let formEndRange = html.range(of: "</form>", options: [.caseInsensitive], range: formStartRange.lowerBound..<html.endIndex) else {
            return nil
        }
        return String(html[formStartRange.lowerBound..<formEndRange.upperBound])
    }

    private func extractInputTags(from html: String) -> [String] {
        let pattern = "<input[^>]*>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return []
        }
        let range = NSRange(html.startIndex..., in: html)
        return regex.matches(in: html, options: [], range: range).compactMap { match in
            guard let tagRange = Range(match.range, in: html) else { return nil }
            return String(html[tagRange])
        }
    }

    private func normalizeFormAction(_ action: String) -> String? {
        if action.isEmpty {
            return nil
        }
        if let url = URL(string: action), url.host != nil {
            return url.path.isEmpty ? "/" : url.path
        }
        if action.hasPrefix("/") {
            return action
        }
        return "/" + action
    }

    private func extractAttribute(_ attribute: String, from input: String) -> String? {
        let pattern = "\\b\(attribute)=[\\\"\\']([^\\\"\\']*)[\\\"\\']"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let range = NSRange(input.startIndex..., in: input)
        guard let match = regex.firstMatch(in: input, options: [], range: range),
              match.numberOfRanges > 1,
              let valueRange = Range(match.range(at: 1), in: input) else {
            return nil
        }
        return String(input[valueRange])
    }

    private func matchFirst(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              match.numberOfRanges > 1,
              let valueRange = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[valueRange])
    }

    private func decodeHtmlEntities(_ string: String) -> String {
        let decoded = string.replacingOccurrences(of: "&amp;", with: "&")
        return decoded.replacingOccurrences(of: "&#43;", with: "+")
    }

    private func logLoginPageHints(from html: String) {
        let needles = ["csrf", "token", "authenticity", "session", "login"]
        for needle in needles {
            if let snippet = findSnippet(needle: needle, in: html) {
                log("login page hint [\(needle)]: \(snippet)")
            }
        }
    }

    private func findSnippet(needle: String, in text: String) -> String? {
        guard let range = text.range(of: needle, options: [.caseInsensitive]) else {
            return nil
        }
        let start = text.index(range.lowerBound, offsetBy: -80, limitedBy: text.startIndex) ?? text.startIndex
        let end = text.index(range.upperBound, offsetBy: 80, limitedBy: text.endIndex) ?? text.endIndex
        let snippet = String(text[start..<end])
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
        return snippet
    }
}

