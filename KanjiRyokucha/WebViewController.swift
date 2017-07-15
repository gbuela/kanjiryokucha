//
//  WebViewController.swift
//  KanjiRyokucha
//
//  Created by German Buela on 3/19/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import UIKit

class WebViewController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet weak var webView: UIWebView!
    
    var resourceName: String? {
        didSet {
            loadResource()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        webView.delegate = self
        webView.scrollView.bounces = false
        
        loadResource()
    }
    
    func loadResource() {
        guard let name = resourceName,
            webView != nil else { return }
        
        if let path = Bundle.main.path(forResource: name, ofType: "rtf"),
            let url = URL(string: path) {
            let request = URLRequest(url: url)
            webView.loadRequest(request)
        }
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if navigationType == .linkClicked,
            let url = request.url {
            UIApplication.shared.openURL(url)
            return false
        }
        return true
    }
}
