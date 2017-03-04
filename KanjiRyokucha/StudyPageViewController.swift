//
//  StudyPageViewController.swift
//  KanjiRyokucha
//
//  Created by German Buela on 2/17/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import UIKit
import WebKit

enum StudyPageMode {
    case study
    case studyLearned
    case review
}

protocol StudyPageDelegate: class {
    func studyPageMarkLearnedTapped(indexPath: IndexPath)
}

class StudyPageViewController: UIViewController {
    
    var urlToOpen: String?
    weak var delegate: StudyPageDelegate?
    var indexPath: IndexPath?
    var mode: StudyPageMode = .study

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if case .study = mode {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Mark learned", style: .plain, target: self, action: #selector(learnedTapped))
        } else if case .review = mode {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "OK", style: .plain, target: self, action: #selector(okTapped))
        }
        
        if let urlToOpen = urlToOpen,
            let url = URL(string: urlToOpen) {
            var request = URLRequest(url: url)

            if let latestCookies = Response.latestCookies {
                for cookie in latestCookies {
                    request.addValue(cookie, forHTTPHeaderField: "Cookie")
                }
            }
 
            let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
            webView.load(request)
            view.addSubview(webView)
            
            webView.translatesAutoresizingMaskIntoConstraints = false
            let height = NSLayoutConstraint(item: webView, attribute: .height, relatedBy: .equal, toItem: view, attribute: .height, multiplier: 1, constant: 0)
            let width = NSLayoutConstraint(item: webView, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1, constant: 0)
            view.addConstraints([height, width])
        }
    }
    
    func learnedTapped() {
        if let indexPath = indexPath {
            delegate?.studyPageMarkLearnedTapped(indexPath: indexPath)
        }
    }
    
    func okTapped() {
        dismiss(animated: true, completion: nil)
    }
}
