//
//  ReviewViewController.swift
//  KanjiRyokucha
//
//  Created by German Buela on 2/9/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import UIKit
import ReactiveSwift
import SwiftRater

fileprivate typealias ReviewStarter = ActionStarter<[ReviewEntry], Response, FetchError>
fileprivate typealias SubmitStarter = ActionStarter<[ReviewEntry], [SignalProducer<Response, FetchError>], FetchError>

struct Rating {
    let fromPercent: Int
    let emoji: String
}

extension PieChartItem {
    init(value: Int, color: UIColor, text: String? = nil) {
        self.init(value: Float(value), color: color, text: text ?? "\(value)")
    }
}

class PerformanceChartDataSource: ARPieChartItemDataSource {
    private var items: [PieChartItem] = []
    
    var pieChartItems: [PieChartItem] {
        return items
    }
    
    func set(yesCount: Int, noCount: Int, otherCount: Int, unansweredCount: Int) {
        let yesItem = PieChartItem(value: yesCount, color: UIColor.pieYes)
        let noItem = PieChartItem(value: noCount, color: UIColor.pieNo)
        let otherItem = PieChartItem(value: otherCount, color: UIColor.pieOther)
        let unansweredItem = PieChartItem(value: unansweredCount, color: UIColor.pieUnanswered)
        items = [yesItem, noItem, otherItem, unansweredItem]
    }
}

class SubmissionChartDataSource: ARPieChartItemDataSource {
    private var items: [PieChartItem] = []
    
    var pieChartItems: [PieChartItem] {
        return items
    }
    
    func set(submitted: Int, total: Int) {
        let unsubmitted = max(total - submitted, 0)
        let item0 = PieChartItem(value: submitted, color: UIColor.pieSubmitted, text: "")
        let item1 = PieChartItem(value: unsubmitted, color: UIColor.pieUnsubmitted, text: "")
        items = [item0, item1]
    }
}

class ReviewViewController: UIViewController {

    private class func scoreFromState(_ state: ReviewState?) -> Int? {
        guard let state = state,
            state.totalAnswered > 0
            else { return nil }
        
        let answered = Double(state.totalAnswered)
        let yesAnswers = Double(state.answeredYes)
        let percent = (100.0 / answered) * yesAnswers
        guard !percent.isNaN else { return nil }
        
        let score = Int(percent)
        
        if score < 0 {
            return 0
        } else if score > 100 {
            return 100
        }
        
        return score
    }
    
    private static let ratings: [Rating] = [
        Rating(fromPercent: 0, emoji: "😢"),
        Rating(fromPercent: 10, emoji: "🙄"),
        Rating(fromPercent: 60, emoji: "😐"),
        Rating(fromPercent: 75, emoji: "🙂"),
        Rating(fromPercent: 85, emoji: "😎"),
        Rating(fromPercent: 97, emoji: "😜"),
        ]
    
    private class func emojiRatingFromScore(_ percent: Int?) -> String {
        guard let percent = percent else { return "😶" }
        
        var emoji = ""
        for rating in ratings {
            if percent >= rating.fromPercent {
                emoji = rating.emoji
            } else {
                break
            }
        }
        return emoji
    }
    
    private class func cancelButtonFromPending(_ pending: Int) -> String {
        if pending > 0 {
            return "cancel"
        } else {
            return "done"
        }
    }

    @IBOutlet weak var reviewButton: UIButton!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var reviewContainer: UIView!
    @IBOutlet weak var reviewTitle: UILabel!
    @IBOutlet weak var reviewLabel: UILabel!
    @IBOutlet weak var submitLabel: UILabel!
    @IBOutlet weak var performanceChart: ARPieChart!
    @IBOutlet weak var submissionChart: ARPieChart!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var performanceEmoji: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    public weak var reviewDelegate: ReviewDelegate!
    public weak var reviewEngine: ReviewEngineProtocol!
    
    private var reviewStarter: ReviewStarter?
    private var submitStarter: SubmitStarter?
    
    private let score: MutableProperty<Int?> = MutableProperty(nil)
    
    private let performanceDataSource = PerformanceChartDataSource()
    private let submissionDataSource = SubmissionChartDataSource()
    
    var global: Global!

    init(engine: ReviewEngineProtocol, delegate: ReviewDelegate) {
        super.init(nibName: "ReviewViewController", bundle: nil)
        reviewEngine = engine
        reviewDelegate = delegate
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        reviewContainer.backgroundColor = .background
        global = Database.getGlobal()
        
        setUp()
        wireUp()
        refreshCharts(state: reviewEngine.reviewState.value)
    }

    func setUp() {
        performanceChart.showDescriptionText = true
        if UIScreen.main.bounds.maxY == 480 {
            submissionChart.innerRadius = 25
            performanceChart.innerRadius = 25
            performanceChart.outerRadius = 60
            submissionChart.outerRadius = 35
        } else {
            submissionChart.innerRadius = 35
            performanceChart.innerRadius = 35
            performanceChart.outerRadius = 80
            submissionChart.outerRadius = 45
        }
        submissionChart.showDescriptionText = false
        
        performanceChart.dataSource = performanceDataSource
        submissionChart.dataSource = submissionDataSource
        
        reviewLabel.textColor = .ryokuchaDark
        submitLabel.textColor = .ryokuchaDark
        
        view.layer.cornerRadius = 8.0
        view.layer.borderColor = reviewEngine.reviewColor.value.cgColor
        view.layer.borderWidth = 1.0
        reviewTitle.backgroundColor = reviewEngine.reviewColor.value
        reviewTitle.text = reviewEngine.reviewTitle.value
    }
    
    func wireUp() {
        reviewLabel.reactive.text <~ reviewEngine.toReviewCount.map { "\($0)" }
        submitLabel.reactive.text <~ reviewEngine.toSubmitCount.map { "\($0)" }
        
        reviewStarter = ReviewStarter(control: reviewButton,
                                      action: reviewEngine.reviewAction,
                                      inputProperty: reviewEngine.reviewEntries)
        
        cancelButton.reactive.isEnabled <~ reviewEngine.cancelAction.isEnabled
        
        cancelButton.tapReact { [weak self] _ in
            self?.cancelOrConfirm()
        }
        
        reviewStarter?.useHUD()
        
        reviewStarter?.action.uiReact { [weak self] (response: Response) in
            guard let model = response.model as? CardDataModel else { return }
            self?.presentPagedReview(model: model)
        }
        
        reviewEngine.reviewState.uiReact { [weak self] state in
            self?.refreshCharts(state: state)
        }
        
        score <~ reviewEngine.reviewState.map(ReviewViewController.scoreFromState)
        scoreLabel.reactive.text <~ score.map { (pct:Int?) -> String in
            guard let pct = pct else { return "-" }
            return "\(pct)%"
        }
        performanceEmoji.reactive.text <~ score.map(ReviewViewController.emojiRatingFromScore)
        
        let pendingCount = reviewEngine.toSubmitCount.zip(with: reviewEngine.toReviewCount).map({ (a,b) -> Int in
            a + b
        })
        cancelButton.reactive.title(for: .normal) <~ pendingCount.map { ReviewViewController.cancelButtonFromPending($0) }
        
        if let srsEngine = reviewEngine as? SRSEngineProtocol {
            submitStarter = SubmitStarter(control: submitButton,
                                          action: srsEngine.submitAction,
                                          inputProperty: reviewEngine.reviewEntries)
            
            
            performanceEmoji.reactive.isHidden <~ srsEngine.isSubmitting
            
            srsEngine.isSubmitting.uiReact { [weak self] submitting in
                if submitting {
                    self?.activityIndicator.startAnimating()
                } else {
                    self?.activityIndicator.stopAnimating()
                    SwiftRater.check()
                }
            }
        } else {
            submitButton.isEnabled = false
        }
    }
    
    private func presentPagedReview(model: CardDataModel) {
        let pagedReviewVC = PagedReviewViewController()
        pagedReviewVC.cards = model.cards
        pagedReviewVC.delegate = reviewDelegate
        pagedReviewVC.reviewEngine = reviewEngine
        pagedReviewVC.modalPresentationStyle = .custom
        pagedReviewVC.modalTransitionStyle = .crossDissolve
        self.present(pagedReviewVC, animated: global.useAnimations, completion: nil)
    }
    
    private func cancelOrConfirm() {
        let pending = reviewEngine.toSubmitCount.value
        
        if pending > 0 {
            confirm(title: "Cancel session",
                message: "You have \(pending) unsubmitted answers!",
                yesOption: "Cancel anyway",
                noOption: "OMG stay!") {
                    [unowned self] _ in
                    self.reviewContainer.isHidden = true
                    self.reviewEngine.cancelAction.apply(true).start()
            }
        } else {
            reviewContainer.isHidden = true
            reviewEngine.cancelAction.apply(true).start()
        }
    }
    
    // MARK: - charts
    
    private func refreshCharts(state: ReviewState?) {
        loadPerformanceData(state: state)
        performanceChart.reloadData()
        submissionChart.reloadData()
    }
    
    private func loadPerformanceData(state: ReviewState?) {
        performanceDataSource.set(yesCount: state?.answeredYes ?? 0,
                                  noCount: state?.answeredNo ?? 0,
                                  otherCount: state?.answeredOther ?? 0,
                                  unansweredCount: state?.totalUnanswered ?? 0)
        
        let submitted = state?.totalSubmitted ?? 0
        let total = state?.totalCards ?? 0
        submissionDataSource.set(submitted: submitted, total: total)
    }
}
