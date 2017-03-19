//
//  AboutViewController.swift
//  KanjiRyokucha
//
//  Created by German Buela on 3/19/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {
    
    @IBOutlet weak var webView: UIWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let path = Bundle.main.path(forResource: "about", ofType: "rtf"),
            let url = URL(string: path) {
            let request = URLRequest(url: url)
            webView.loadRequest(request)
        }
    }
}
