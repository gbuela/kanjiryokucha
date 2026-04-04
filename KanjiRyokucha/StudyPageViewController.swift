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

protocol StudyPageDelegate: AnyObject {
    func studyPageMarkLearnedTapped(indexPath: IndexPath)
}

class StudyPageViewController: UIViewController, WKNavigationDelegate {
    
    var urlToOpen: String?
    weak var delegate: StudyPageDelegate?
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var toolbarHeightConstraint: NSLayoutConstraint!
    var indexPath: IndexPath?
    var mode: StudyPageMode = .study
    var isPreviewing: MutableProperty<Bool> = MutableProperty(false)
    
    private class func loadFromStoryboard() -> StudyPageViewController {
        let studyStoryboard = UIStoryboard(name: "Study", bundle: nil)
        let instance = studyStoryboard.instantiateViewController(withIdentifier: "studyDetail") as! StudyPageViewController
        return instance
    }
    
    public class func instanceForReview(urlString: String) -> StudyPageViewController {
        let instance = loadFromStoryboard()
        instance.urlToOpen = urlString
        instance.mode = .review
        log("study page: " + urlString)
        return instance
    }

    public class func instanceForStudy(urlString: String, keyword: String, isLearned: Bool, indexPath: IndexPath, delegate: StudyPageDelegate?) -> StudyPageViewController {
        let instance = loadFromStoryboard()
        instance.setupInStudy(urlString: urlString,
                              keyword: keyword,
                              isLearned: isLearned,
                              indexPath: indexPath,
                              delegate: delegate)
        log("study page: " + urlString)
        return instance
    }
    
    public func setupInStudy(urlString: String, keyword: String, isLearned: Bool, indexPath: IndexPath, delegate: StudyPageDelegate?) {
        self.urlToOpen = urlString
        self.title = keyword
        self.mode = isLearned ? .studyLearned : .study
        self.indexPath = indexPath
        self.delegate = delegate
        log("study page: " + urlString)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigationBarAppearance()
        edgesForExtendedLayout = []
        
        containerView.backgroundColor = .background

        if case .study = mode {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "MARK LEARNED", style: .plain, target: self, action: #selector(learnedTapped))
        } else if case .review = mode {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "OK", style: .plain, target: self, action: #selector(okTapped))
        }
        
        activityIndicator.isHidden = true
        
        if let urlToOpen = urlToOpen,
            let url = URL(string: urlToOpen) {
            var request = URLRequest(url: url)

            if let latestCookies = Response.latestCookies {
                for cookie in latestCookies {
                    request.addValue(cookie, forHTTPHeaderField: "Cookie")
                }
            }
            
            activityIndicator.isHidden = false

            let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
            webView.load(request)
            webView.navigationDelegate = self
            webView.isHidden = true
            containerView.addSubview(webView)
            webView.scrollView.zoomScale = 2.0

            webView.translatesAutoresizingMaskIntoConstraints = false
            let height = NSLayoutConstraint(item: webView, attribute: .height, relatedBy: .equal, toItem: containerView, attribute: .height, multiplier: 1, constant: 0)
            let width = NSLayoutConstraint(item: webView, attribute: .width, relatedBy: .equal, toItem: containerView, attribute: .width, multiplier: 1, constant: 0)
            containerView.addConstraints([height, width])
        }
        
        let isPad = traitCollection.userInterfaceIdiom == .pad

        if mode == .study || mode == .studyLearned {
            if isPad {
                toolbarHeightConstraint.constant = 0
                toolbar.isHidden = true
                navigationItem.leftBarButtonItem = UIBarButtonItem(title: "OPEN IN SAFARI", style: .plain, target: self, action: #selector(openInSafari))
            } else {
                toolbar.isHidden = false
                navigationItem.leftBarButtonItem = nil
                toolbarHeightConstraint.reactive.constant <~ isPreviewing.map { $0 ? 0 : 46 }
            }
        } else {
            if isPad {
                toolbarHeightConstraint.constant = 0
                toolbar.isHidden = true
            } else {
                toolbar.isHidden = false
                toolbarHeightConstraint.reactive.constant <~ isPreviewing.map { $0 ? 0 : 46 }
            }
        }
    }
    
    override var hidesBottomBarWhenPushed: Bool {
        get { return true }
        set { super.hidesBottomBarWhenPushed = newValue }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBarAppearance()
    }
    
    @objc func learnedTapped() {
        if let indexPath = indexPath {
            delegate?.studyPageMarkLearnedTapped(indexPath: indexPath)
        }
    }
    
    @objc func okTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    private func configureNavigationBarAppearance() {
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .ryokuchaDark

            navigationItem.standardAppearance = appearance
            navigationItem.scrollEdgeAppearance = appearance

            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
            navigationController?.navigationBar.compactAppearance = appearance

            if #available(iOS 15.0, *) {
                navigationItem.compactScrollEdgeAppearance = appearance
                navigationController?.navigationBar.compactScrollEdgeAppearance = appearance
            }
        } else {
            navigationController?.navigationBar.barTintColor = .ryokuchaDark
            navigationController?.navigationBar.backgroundColor = .ryokuchaDark
        }
        navigationController?.navigationBar.isTranslucent = false
    }
    
    @IBAction func openInSafari() {
        if let urlToOpen = urlToOpen,
            let url = URL(string: urlToOpen) {
            UIApplication.shared.open(url)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.isHidden = false
    }
}
