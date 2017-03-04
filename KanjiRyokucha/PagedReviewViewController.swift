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

class PagedReviewViewController: UIViewController, ButtonHandler {
    
    var cards: [CardModel]?
    weak var delegate: ReviewDelegate?
    var reviewEngine: ReviewEngineProtocol?
    
    @IBOutlet weak var pageContainer: UIView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var videoContainer: UIView!
    @IBOutlet weak var videoPanel: UIView!
    
    var currentFront: CardFrontView?
    var currentBack: CardBackView?
    var showingFront = true
    
    var lastPoint = CGPoint.zero
    var brushWidth: CGFloat = 5.0
    var opacity: CGFloat = 1.0
    var swiped = false
    
    var player: AVPlayer?
    
    var global: Global!

    override func viewDidLoad() {
        super.viewDidLoad()

        global = Database.getGlobal()
        
        self.view.backgroundColor = UIColor.ryokuchaTranslucent
        
        self.videoPanel.isHidden = true
        pageControl.numberOfPages = cards?.count ?? 0
        showPage()
    }

    func pageForward() {
        let newPage = pageControl.currentPage + 1
        
        if let count = cards?.count,
            newPage == count {
            delegate?.userFinishedReview()
            dismiss(animated: global.useAnimations, completion: nil)
            return
        }
        
        if let engine = reviewEngine,
            let cardModels = cards {
            engine.fetchMissingCards(cardModels: cardModels) { [weak self] cardDataModel in
                print("fetched \(cardDataModel.cards.count) additional cards")
                self?.cards?.append(contentsOf: cardDataModel.cards)
                self?.pageControl.numberOfPages += cardDataModel.cards.count
            }
        }
        
        // Animated transition to next card 
        pageControl.currentPage = newPage
        
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
    
    func pageBack() {
        let newPage = pageControl.currentPage - 1
        
        guard newPage >= 0 else { return }
        
        // Animated transition to previous card
        pageControl.currentPage = newPage
        
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
    
    func showPage() {
        if let card = cards?[pageControl.currentPage] {
            
            currentFront?.removeFromSuperview()
            currentBack?.removeFromSuperview()
            
            let frontView = CardFrontView.loadFromNib()
            let backView = CardBackView.loadFromNib()
            
            frontView.keywordLabel.text = card.keyword
            backView.keywordLabel.text = card.keyword
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
            
            findReading(card: card)
        }
    }
    
    func findReading(card: CardModel) {
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
    
    func formatReadings(line: String) -> String {
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
                
                backView.drawingImageView.image = frontView.mainImageView.image
                backView.readingsTextView.alpha = 0.0
                
                let options: UIViewAnimationOptions = global.useAnimations ? [.transitionFlipFromRight, .showHideTransitionViews] : []
                
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
            frontView.mainImageView.image = nil
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
        }
    }
    
    func showFrontOptions() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alertController.addAction(optionButtonPreviousCard())
        alertController.addAction(optionButtonSkip())
        alertController.addAction(optionButtonDelete())
        alertController.addAction(optionButtonCancel())
        
        present(alertController, animated: true, completion: nil)
    }
    
    func showBackOptions() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alertController.addAction(optionButtonStroke())
        alertController.addAction(optionButtonStudyPage())
        alertController.addAction(optionButtonFlipBack())
        alertController.addAction(optionButtonSkip())
        alertController.addAction(optionButtonDelete())
        alertController.addAction(optionButtonCancel())
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func flipBack() {
        guard let backView = currentBack,
            let frontView = currentFront else {
                return
        }
        
        if !showingFront {
            UIView.transition(from: backView, to: frontView, duration: 0.5, options: [.transitionFlipFromLeft, .showHideTransitionViews], completion: { [weak self] _ in
                    self?.showingFront = true
            })

        }
    }
    
    private func optionButtonPreviousCard() -> UIAlertAction {
        return UIAlertAction(title: "Previous card", style: .default, handler: { [weak self] (action) -> Void in
            print("Previous card tapped")
            if let sself = self,
                sself.showingFront {
                sself.pageBack()
            }
        })
    }
    
    private func optionButtonFlipBack() -> UIAlertAction {
        return UIAlertAction(title: "Flip back", style: .default, handler: { [weak self] (action) -> Void in
            print("Flip back tapped")
            self?.flipBack()
        })
    }
    
    private func optionButtonSkip() -> UIAlertAction {
        return UIAlertAction(title: "Skip", style: .default, handler: { [weak self] (action) -> Void in
            print("Skip tapped")
            self?.userAnswered(answer: .skip)
            self?.pageForward()
        })
    }
    
    private func optionButtonDelete() -> UIAlertAction {
        return UIAlertAction(title: "Delete", style: .default, handler: { [weak self] (action) -> Void in
            print("Delete tapped")
            self?.userAnswered(answer: .delete)
            self?.pageForward()
       })
    }
    
    private func optionButtonStroke() -> UIAlertAction {
        return UIAlertAction(title: "Stroke order", style: .default, handler: { [weak self] (action) -> Void in
            print("Stroke order tapped")

            guard let sself = self,
                let card = sself.cards?[sself.pageControl.currentPage],
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
            detailsAction.consume(String(scalar))
        })
    }
    
    private func playVideo(url: NSURL){
        player = AVPlayer(url: url as URL)
        let playerController = AVPlayerViewController()
        
        playerController.player = player
        addChildViewController(playerController)
        videoContainer.addSubview(playerController.view)
        playerController.view.frame = videoContainer.bounds
        playerController.view.backgroundColor = .white
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
   

    private func optionButtonStudyPage() -> UIAlertAction {
        return UIAlertAction(title: "Study page", style: .default, handler: { [weak self] (action) -> Void in
            print("Study page tapped")
            
            guard let sself = self,
                let card = sself.cards?[sself.pageControl.currentPage],
                let scalar = UnicodeScalar(card.cardId),
                let encoded = String(scalar).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else { return }
            
            let studyPageVC = StudyPageViewController()
            studyPageVC.urlToOpen = "http://kanji.koohii.com/study/kanji/" + encoded
            studyPageVC.mode = .review
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
                                            print("Open \(scheme): \(success)")
                })
            } else {
                let success = UIApplication.shared.openURL(url)
                print("Open \(scheme): \(success)")
            }
        }
    }
    
    private func optionButtonCancel() -> UIAlertAction {
        return UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
            print("Cancel button tapped")
        })
    }

    func userAnswered(answer: CardAnswer) {
        guard let card = cards?[pageControl.currentPage] else {
            return
        }
        let reviewAnswer = ReviewAnswer(cardId: card.cardId, answer: answer)
        delegate?.userDidAnswer(reviewAnswer: reviewAnswer)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let frontView = currentFront else {
            return
        }
        
        frontView.drawHereLabel.isHidden = true
        
        swiped = false
        if let touch = touches.first {
            lastPoint = touch.location(in: frontView.tempImageView)
        }
    }
    
    func drawLineFrom(fromPoint: CGPoint, toPoint: CGPoint) {
        guard let frontView = currentFront else {
            return
        }
        
        let frame = frontView.tempImageView.frame
        UIGraphicsBeginImageContext(frame.size)
        let context = UIGraphicsGetCurrentContext()
        
        frontView.tempImageView.image?.draw(in:CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        
        context?.move(to: fromPoint)
        context?.addLine(to: toPoint)
        
        context?.setLineCap(.round)
        context?.setLineWidth(brushWidth)
        context?.setStrokeColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        context?.setBlendMode(.normal)
        
        context?.strokePath()
        
        frontView.tempImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        frontView.tempImageView.alpha = opacity
        UIGraphicsEndImageContext()
        
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let frontView = currentFront else {
            return
        }
        
        swiped = true
        if let touch = touches.first {
            let currentPoint = touch.location(in: frontView.tempImageView)
            drawLineFrom(fromPoint: lastPoint, toPoint: currentPoint)
            
            lastPoint = currentPoint
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let frontView = currentFront else {
            return
        }
        
        if !swiped {
            drawLineFrom(fromPoint: lastPoint, toPoint: lastPoint)
        }
        
        let frame = frontView.tempImageView.frame
        
        // Merge tempImageView into mainImageView
        UIGraphicsBeginImageContext(frame.size)
        frontView.mainImageView.image?.draw(in:CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height), blendMode: .normal, alpha: 1.0)
        frontView.tempImageView.image?.draw(in:CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height), blendMode: .normal, alpha: opacity)
        frontView.mainImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        frontView.tempImageView.image = nil
    }

}
