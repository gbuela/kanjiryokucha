//
//  FreeReviewViewController.swift
//  KanjiRyokucha
//
//  Created by German Buela on 2/7/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import UIKit
import ReactiveSwift
import PKHUD

class FreeViewModel: ReviewEngineProtocol {    
    private static func validateRange(range:(Int?,Int?)) -> ((Int,Int)?, String?) {
        guard let fromInt = range.0,
            let toInt = range.1 else { return (nil, nil) }
        
        guard fromInt <= toInt else { return (nil, nil) }
        
        guard (1 + (toInt - fromInt)) <= maxRangeSize else {
            return (nil, "Range too big! Maximum is \(maxRangeSize) cards")
        }
        
        return ((fromInt, toInt), nil)
    }
    let reviewTitle: MutableProperty<String?> = MutableProperty("free review")
    let reviewColor: MutableProperty<UIColor> = MutableProperty(.ryokuchaDark)

    let emptySessionAttempt = MutableProperty(false)

    let reviewInProgress: MutableProperty<Bool> = MutableProperty(false)
    let reviewEntries: MutableProperty<[ReviewEntry]> = MutableProperty([])
    var toReviewCount: MutableProperty<Int> = MutableProperty(0)
    let toSubmitCount: MutableProperty<Int> = MutableProperty(0)
    let reviewState: MutableProperty<ReviewState?> = MutableProperty(nil)
    var cancelAction: ButtonAction!
    var reviewAction: ReviewAction!

    let shouldEnableReview: MutableProperty<Bool> = MutableProperty(false)
    let shouldEnableSubmit: MutableProperty<Bool> = MutableProperty(false)

    var startAction: FreeStartActionType!
    var startedSession: MutableProperty<[Int]?> = MutableProperty(nil)
    let fromIndex: MutableProperty<Int?> = MutableProperty(nil)
    let toIndex: MutableProperty<Int?> = MutableProperty(nil)
    let shuffleOn: MutableProperty<Bool> = MutableProperty(false)
    let indexRange: MutableProperty<(Int,Int)?> = MutableProperty(nil)
    let shouldEnableStart: MutableProperty<Bool> = MutableProperty(false)
    let rangeError: MutableProperty<String?> = MutableProperty(nil)

    func wireUp() {
        let validation = fromIndex.combineLatest(with: toIndex).map(FreeViewModel.validateRange)
        indexRange <~ validation.map{$0.0}
        rangeError <~ validation.map{$0.1}
        shouldEnableStart <~ indexRange.map { $0 != nil }
        
        startAction = FreeStartActionType(enabledIf: shouldEnableStart) { [weak self] _ in
            guard let sself = self else { return SignalProducer.empty }
            return FreeReviewStartRequest(fromIndex: sself.fromIndex.value!,
                                          toIndex: sself.toIndex.value!,
                                          shuffle: sself.shuffleOn.value).requestProducer()!
        }
        
        startedSession <~ startAction.values.map { (response:Response) -> [Int]? in
            guard let model = response.model as? CardIdsModel else { return nil }
            return model.ids
        }

        reviewInProgress <~ startedSession.map { $0 != nil }
        
        reviewEntries <~ startedSession.map { cardIds in
            guard let ids = cardIds else { return [] }
            return ids.map { cardId in
                let reviewEntry = ReviewEntry()
                reviewEntry.cardId = cardId
                return reviewEntry
            }
        }
        
        toReviewCount <~ reviewEntries.map { $0.count(answer: .unanswered) }
        shouldEnableReview <~ toReviewCount.map { $0 > 0 }

        reviewAction = ReviewAction(enabledIf: shouldEnableReview, execute: SRSReviewEngine.fetchActionProducer)
        
        reviewState <~ reviewEntries.map { [unowned self] reviewEntries in
            self.reviewStateMapper(entries: reviewEntries)
        }

        cancelAction = Action { [weak self] _ in
            self?.cancelSession()
            return SignalProducer<Bool, Never>.empty
        }
    }
    
    func cancelSession() {
        reviewEntries.value = []
        reviewInProgress.value = false
    }
    
    func saveFetchedCards(response: Response) {}
}

typealias FreeStartActionType = Action<Bool, Response, FetchError>
typealias FreeStartStarter = ActionStarter<Bool, Response, FetchError>

let maxRangeSize = 100

class FreeReviewViewController: UIViewController, ReviewDelegate {
    
    private static func textToInt(text: String?) -> Int? {
        guard let text = text else { return nil }
        return Int(text)
    }
    
    private let viewModel = FreeViewModel()
    private var reviewViewController: ReviewViewController?

    @IBOutlet weak var formView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var fromField: UITextField!
    @IBOutlet weak var toField: UITextField!
    @IBOutlet weak var shuffleSwitch: UISwitch!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var errorMessage: UILabel!
    
    @IBOutlet weak var reviewContainer: UIView!

    private var startStarter: FreeStartStarter!

    override func viewDidLoad() {
        super.viewDidLoad()

        setUp()
        wireUp()
    }
    
    func setUp() {
        reviewContainer.roundedCorners()
        self.view.backgroundColor = .ryokuchaFaint
    }
    
    func wireUp() {
        viewModel.wireUp()
        
        startButton.titleLabel?.adjustsFontForContentSizeCategory = true
        
        viewModel.fromIndex <~ fromField.reactive.continuousTextValues.map(FreeReviewViewController.textToInt)
        viewModel.toIndex <~ toField.reactive.continuousTextValues.map(FreeReviewViewController.textToInt)
        viewModel.shuffleOn <~ shuffleSwitch.reactive.isOnValues
        
        errorMessage.reactive.isHidden <~ viewModel.rangeError.map{ $0 == nil }
        errorMessage.reactive.text <~ viewModel.rangeError
        
        startStarter = FreeStartStarter(control: startButton,
                                        action: viewModel.startAction!,
                                        input: false)
        
        startButton.reactive.controlEvents(.touchDown).uiReact { [weak self] response in
            self?.view.endEditing(true)
        }
        
        viewModel.startAction.errors.uiReact { [weak self] error in
            self?.showAlert(error.uiMessage)
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(userTappedBackground))
        view.addGestureRecognizer(tap)
        
        viewModel.reviewInProgress.uiReact { [weak self] inProgress in
            guard inProgress else {
                if let vc = self?.reviewViewController {
                    vc.willMove(toParent: nil)
                    vc.view.removeFromSuperview()
                    vc.removeFromParent()
                    self?.reviewViewController = nil
                    self?.reviewContainer.isHidden = true
                    self?.formView.isHidden = false
                }
                return
            }
            
            if let sself = self {
                let rvc = ReviewViewController(engine: sself.viewModel, delegate: sself)
                sself.reviewViewController = rvc
                sself.addChild(rvc)
                rvc.view.frame = sself.reviewContainer.bounds
                sself.reviewContainer.addSubview(rvc.view)
                rvc.didMove(toParent: sself)
                self?.reviewContainer.isHidden = false
                self?.formView.isHidden = true
            }
        }
        
        activityIndicator.reactive.isAnimating <~ viewModel.startAction.isExecuting
    }
    
    @IBAction func userTappedBackground() {
        view.endEditing(true)
    }
    
    private func notifyStartError() {
        showAlert("Could not start review! Are these indexes valid?")
    }
    
    func userDidAnswer(reviewAnswer: ReviewAnswer) {
        guard let reviewEntry = viewModel.reviewEntries.value.first(where: { $0.cardId == reviewAnswer.cardId }) else {
            log("card not in review!!")
            return
        }
        reviewEntry.cardAnswer = reviewAnswer.answer
        
        viewModel.reviewEntries.value = viewModel.reviewEntries.value
    }
    
    func userFinishedReview() {
        log("finished review")
        viewModel.reviewEntries.value = viewModel.reviewEntries.value
    }

}
