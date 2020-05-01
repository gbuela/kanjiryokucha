//
//  PagedReviewViewController.swift
//  KanjiRyokucha
//
//  Created by German Buela on 12/27/16.
//  Copyright © 2016 German Buela. All rights reserved.
//

import UIKit
import ReactiveSwift
import AVFoundation
import AVKit
import PKHUD
import SafariServices

struct ReviewAnswer {
    let cardId: Int
    let answer: CardAnswer
}

protocol ReviewDelegate: class {
    func userDidAnswer(reviewAnswer: ReviewAnswer)
    func userFinishedReview()
}

class PagedReviewViewController: UIViewController, ButtonHandler, BackendAccess, LookupLabelDelegate {
    
    var cards: [CardModel]?
    weak var delegate: ReviewDelegate?
    var reviewEngine: ReviewEngineProtocol?
    
    @IBOutlet weak var pageContainer: UIView!
    @IBOutlet weak var videoContainer: UIView!
    @IBOutlet weak var videoPanel: UIView!
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var progressView: UIProgressView!
    
    var currentFront: CardFrontView?
    var currentBack: CardBackView?
    var drawingVC: DrawingViewController?
    var showingFront = true
    var currentPage = 0
    var totalCount = 0
    
    var isGradientSetup = false
    
    var player: AVPlayer?
    
    var global: Global!

    override func viewDidLoad() {
        super.viewDidLoad()

        global = Database.getGlobal()
        
        view.backgroundColor = .ryokuchaTranslucent
        
        videoPanel.isHidden = true
        
        if let reviewCount = reviewEngine?.toReviewCount.value {
            totalCount = reviewCount
        }
        showPage()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupGradient()
    }
    
    private func setupGradient() {
        guard !isGradientSetup else { return }
        let gradient = CAGradientLayer()
        gradient.frame = gradientView.bounds
        gradient.colors = [UIColor.ryokuchaDark.withAlphaComponent(0.0).cgColor,
                           UIColor.ryokuchaDark.withAlphaComponent(1.0).cgColor]
        gradient.locations = [0.0, 1.0]
        gradientView.layer.insertSublayer(gradient, at: 0)
        isGradientSetup = true
    }

    private func pageForward() {
        let newPage = currentPage + 1
        
        if let count = cards?.count,
            newPage == count {
            delegate?.userFinishedReview()
            dismiss(animated: global.useAnimations, completion: nil)
            return
        }
        
        if let engine = reviewEngine,
            let cardModels = cards {
            engine.fetchMissingCards(cardModels: cardModels) { [weak self] cardDataModel in
                log("fetched \(cardDataModel.cards.count) additional cards")
                self?.cards?.append(contentsOf: cardDataModel.cards)
            }
        }
        
        // Animated transition to next card 
        currentPage = newPage
        
        if global.useAnimations {
            let originalX = pageContainer.frame.origin.x
            UIView.animate(withDuration: 0.15, animations: { [unowned self] in
                self.pageContainer.frame.origin.x = -(self.pageContainer.frame.width + 30)
                }, completion: { [unowned self] _ in
                    self.pageContainer.frame.origin.x = self.view.frame.width
                    self.showPage()
                    UIView.animate(withDuration: 0.15) { [unowned self] in
                        self.pageContainer.frame.origin.x = originalX
                    }
            })
        } else {
            self.showPage()
        }
    }
    
    private func pageBack() {
        let newPage = currentPage - 1
        
        guard newPage >= 0 else { return }
        
        // Animated transition to previous card
        currentPage = newPage
        
        if global.useAnimations {
            let originalX = pageContainer.frame.origin.x
            UIView.animate(withDuration: 0.15, animations: { [unowned self] in
                self.pageContainer.frame.origin.x = self.view.frame.width
                }, completion: { [unowned self] _ in
                    self.pageContainer.frame.origin.x = -(self.pageContainer.frame.width + 30)
                    self.showPage()
                    UIView.animate(withDuration: 0.15) { [unowned self] in
                        self.pageContainer.frame.origin.x = originalX
                    }
            })
        } else {
            self.showPage()
        }
    }
    
    private func showPage() {
        guard let card = cards?[currentPage] else { return }
        
        currentFront?.removeFromSuperview()
        currentBack?.removeFromSuperview()
        
        let newProgress = Float(currentPage + 1) / Float(totalCount)
        progressView.setProgress(newProgress, animated: true)
        
        let frontView = CardFrontView.loadFromNib()
        let backView = CardBackView.loadFromNib()
        
        frontView.keywordLabel.delegate = self
        backView.keywordLabel.delegate = self
        frontView.keywordLabel.text = card.keyword
        backView.keywordLabel.text = card.keyword
        backView.frameNumLabel.text = "\(card.frameNum)"
        if let scalar = UnicodeScalar(card.cardId) {
            backView.kanjiLabel.text = String(describing: scalar)
        } else {
            backView.kanjiLabel.text = ""
        }
        
        backView.readingsTextView.text = ""
        
        pageContainer.addSubview(frontView)
        pageContainer.layoutAttachAll(subview: frontView)
        frontView.buttonHandler = self
        backView.buttonHandler = self
        showingFront = true
        
        currentFront = frontView
        currentBack = backView
        
        if let dvc = drawingVC {
            remove(childViewController: dvc)
        }
        drawingVC = DrawingViewController()
        if let dvc = drawingVC {
            add(childViewController: dvc, insideView: frontView.drawingContainer)
        }
        
        findReading(card: card)
    }
    
    private func findReading(card: CardModel) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            
            let hexId = String(format:"%x", card.cardId) + ","
            var foundLine: String? = nil
            if let path = Bundle.main.path(forResource: "readings", ofType: "csv"),
                let stream = StreamReader(path: path) {
                while let line = stream.nextLine() {
                    if line.hasPrefix(hexId) {
                        foundLine = line
                        break
                    }
                }
                stream.close()
                
                if let cardBack = self?.currentBack,
                    let line = foundLine,
                    let formatted = self?.formatReadings(line: line) {
                    DispatchQueue.main.async {
                        cardBack.readingsTextView.text = formatted
                    }
                }
            }
        }
    }
    
    private func formatReadings(line: String) -> String {
        let mainComponents = line.components(separatedBy: ",n,")
        let mainReadings = mainComponents[0].components(separatedBy: ",").dropFirst().joined(separator: "\n")
        if mainComponents.count == 2 {
            let nanoriComponent = mainComponents[1]
            let nanoriReadings = nanoriComponent.components(separatedBy: ",").joined(separator: "\n")
            return mainReadings + "\nNanori: \n" + nanoriReadings
        } else {
            return mainReadings
        }
    }
    
    func handle(button: UIView) {
        guard let backView = currentBack,
            let frontView = currentFront else {
                return
        }
        
        if button == frontView.flipButton {
            if showingFront {
                pageContainer.addSubview(backView)
                pageContainer.layoutAttachAll(subview: backView)
                
                backView.drawingImageView.image = drawingVC?.mainImage.image
                backView.readingsTextView.alpha = 0.0
                
                let options: UIView.AnimationOptions = global.useAnimations ? [.transitionFlipFromRight, .showHideTransitionViews] : []
                
                UIView.transition(from: frontView, to: backView, duration: 0.5, options: options, completion: { _ in
                    backView.readingsTextView.setContentOffset(CGPoint.zero, animated: false)
                    UIView.animate(withDuration: 0.1) {
                        backView.readingsTextView.alpha = 1.0
                    }
                })
                showingFront = false
            }
        } else if button == frontView.quitButton ||
            button == backView.quitButton {
            delegate?.userFinishedReview()
            dismiss(animated: global.useAnimations, completion: nil)
        } else if button == frontView.optionsButton {
            showFrontOptions()
        } else if button == backView.optionsButton {
            showBackOptions()
        } else if button == frontView.clearButton {
            drawingVC?.mainImage.image = nil
        } else if button == backView.yesButton {
            userAnswered(answer: .yes)
            pageForward()
        } else if button == backView.noButton {
            userAnswered(answer: .no)
            pageForward()
        } else if button == backView.easyButton {
            userAnswered(answer: .easy)
            pageForward()
        } else if button == backView.hardButton {
            userAnswered(answer: .hard)
            pageForward()
        } else if button == backView.flipBackButton {
            flipBack()
        }
    }
    
    private func showFrontOptions() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alertController.addAction(optionButtonPreviousCard())
        alertController.addAction(optionButtonSkip())
        alertController.addAction(optionButtonDelete())
        alertController.addAction(optionButtonCancel())
        
        alertController.popoverPresentationController?.sourceView = currentFront?.optionsButton

        present(alertController, animated: true, completion: nil)
    }
    
    private func showBackOptions() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alertController.addAction(optionButtonStroke())
        alertController.addAction(optionButtonStudyPage())
        alertController.addAction(optionButtonJisho())
        alertController.addAction(optionButtonSkip())
        alertController.addAction(optionButtonDelete())
        alertController.addAction(optionButtonCancel())
        
        alertController.popoverPresentationController?.sourceView = currentBack?.optionsButton
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func flipBack() {
        guard let backView = currentBack,
            let frontView = currentFront else {
                return
        }
        pageContainer.addSubview(frontView)
        pageContainer.layoutAttachAll(subview: frontView)

        if !showingFront {
            let options: UIView.AnimationOptions = global.useAnimations ? [.transitionFlipFromLeft, .showHideTransitionViews] : []
            
            UIView.transition(from: backView, to: frontView, duration: 0.5, options: options, completion: { [weak self] _ in
                    self?.showingFront = true
            })
        }
    }
    
    private func optionButtonPreviousCard() -> UIAlertAction {
        return UIAlertAction(title: "Previous card", style: .default, handler: { [weak self] (action) -> Void in
            log("Previous card tapped")
            if let sself = self,
                sself.showingFront {
                sself.pageBack()
            }
        })
    }
    
    private func optionButtonSkip() -> UIAlertAction {
        return UIAlertAction(title: "Skip", style: .default, handler: { [weak self] (action) -> Void in
            log("Skip tapped")
            self?.userAnswered(answer: .skip)
            self?.pageForward()
        })
    }
    
    private func optionButtonDelete() -> UIAlertAction {
        return UIAlertAction(title: "Delete", style: .default, handler: { [weak self] (action) -> Void in
            log("Delete tapped")
            self?.userAnswered(answer: .delete)
            self?.pageForward()
       })
    }
    
    private func optionButtonStroke() -> UIAlertAction {
        return UIAlertAction(title: "Stroke order", style: .default, handler: { [weak self] (action) -> Void in
            log("Stroke order tapped")

            guard let sself = self,
                let card = sself.cards?[sself.currentPage],
                let scalar = UnicodeScalar(card.cardId) else { return }
            
            let detailsAction = Action<String,Response,FetchError> { kanji in
               return KanjiDetailsRequest(kanji: kanji).requestProducer()!
            }
            detailsAction.uiReact { [weak self] response in
                HUD.hide()
                if let model = response.model as? KanjiDetailsModel {
                    if let url = model.videoUrl {
                        self?.playVideo(url: NSURL(string: url)!)
                    }
                }
            }
            detailsAction.errors.uiReact { [weak self] fetchError in
                HUD.hide()
                self?.showAlert(fetchError.uiMessage)
            }
            HUD.show(.systemActivity)
            detailsAction.apply(String(scalar)).start()
        })
    }
    
    func lookupRequested(forTerm term: String) {
        let ref = UIReferenceLibraryViewController(term: term)
        present(ref, animated: true, completion: nil)
    }
    
    private func playVideo(url: NSURL){
        player = AVPlayer(url: url as URL)
        let playerController = AVPlayerViewController()
        
        playerController.player = player
        addChild(playerController)
        videoContainer.addSubview(playerController.view)
        playerController.view.frame = videoContainer.bounds
        playerController.view.backgroundColor = .ryokuchaFaint
        videoPanel.isHidden = false

        player?.play()
    }
    
    @IBAction func doneWithVideo() {
        videoPanel.isHidden = true
        videoContainer.subviews.forEach { view in
            view.removeFromSuperview()
        }
        player = nil
    }

    private func optionButtonJisho() -> UIAlertAction {
        return UIAlertAction(title: "Jisho.org", style: .default, handler: { [weak self] (action) -> Void in
            log("Jisho page tapped")
            
            guard let sself = self,
                let card = sself.cards?[sself.currentPage],
                let scalar = UnicodeScalar(card.cardId),
                let encoded = String(scalar).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else { return }
            
            let urlString =  "http://jisho.org/search/" + encoded
            guard let url = URL(string: urlString)
                else { return }
            let safariVC = SFSafariViewController(url: url)
            if #available(iOS 10.0, *) {
                safariVC.preferredBarTintColor = .ryokuchaDark
                safariVC.preferredControlTintColor = .white
            } else {
                safariVC.view.tintColor = .ryokuchaDark
            }
            sself.present(safariVC, animated: true, completion: nil)
        })
    }
    private func optionButtonStudyPage() -> UIAlertAction {
        return UIAlertAction(title: "Study page", style: .default, handler: { [weak self] (action) -> Void in
            log("Study page tapped")
            
            guard let sself = self,
                let card = sself.cards?[sself.currentPage],
                let scalar = UnicodeScalar(card.cardId),
                let encoded = String(scalar).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else { return }
            
            let urlString = sself.backendHost + "/study/kanji/" + encoded
            let studyPageVC = StudyPageViewController.instanceForReview(urlString: urlString)
            studyPageVC.title = card.keyword
            let navController = UINavigationController(rootViewController: studyPageVC)
            sself.present(navController, animated: true, completion: nil)
        })
    }
    
    private func open(scheme: String) {
        if let url = URL(string: scheme) {
            if #available(iOS 10, *) {
                UIApplication.shared.open(url, options: [:],
                                          completionHandler: {
                                            (success) in
                                            log("Open \(scheme): \(success)")
                })
            } else {
                let success = UIApplication.shared.openURL(url)
                log("Open \(scheme): \(success)")
            }
        }
    }
    
    private func optionButtonCancel() -> UIAlertAction {
        return UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
            log("Cancel button tapped")
        })
    }

    func userAnswered(answer: CardAnswer) {
        guard let card = cards?[currentPage] else {
            return
        }
        let reviewAnswer = ReviewAnswer(cardId: card.cardId, answer: answer)
        delegate?.userDidAnswer(reviewAnswer: reviewAnswer)
    }
}
