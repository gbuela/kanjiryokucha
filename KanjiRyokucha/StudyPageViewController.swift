//
//  StudyPageViewController.swift
//  KanjiRyokucha
//
//  Created by German Buela on 2/17/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import UIKit
import WebKit
import ReactiveSwift

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
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var toolbarHeightConstraint: NSLayoutConstraint!
    var indexPath: IndexPath?
    var mode: StudyPageMode = .study
    var isPreviewing: MutableProperty<Bool> = MutableProperty(false)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if case .study = mode {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "MARK LEARNED", style: .plain, target: self, action: #selector(learnedTapped))
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
            
            containerView.addSubview(webView)
            webView.scrollView.zoomScale = 2.0

            webView.translatesAutoresizingMaskIntoConstraints = false
            let height = NSLayoutConstraint(item: webView, attribute: .height, relatedBy: .equal, toItem: containerView, attribute: .height, multiplier: 1, constant: 0)
            let width = NSLayoutConstraint(item: webView, attribute: .width, relatedBy: .equal, toItem: containerView, attribute: .width, multiplier: 1, constant: 0)
            containerView.addConstraints([height, width])
        }
        
        toolbarHeightConstraint.reactive.constant <~ isPreviewing.map { $0 ? 0 : 46 }
    }
    
    override var hidesBottomBarWhenPushed: Bool {
        get { return true }
        set { super.hidesBottomBarWhenPushed = newValue }
    }
    
    func learnedTapped() {
        if let indexPath = indexPath {
            delegate?.studyPageMarkLearnedTapped(indexPath: indexPath)
        }
    }
    
    func okTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func openInSafari() {
        if let urlToOpen = urlToOpen,
            let url = URL(string: urlToOpen) {
            UIApplication.shared.openURL(url)
        }
    }
}
