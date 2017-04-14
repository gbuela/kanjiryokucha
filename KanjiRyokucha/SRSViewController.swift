//
//  SRSViewController.swift
//  KanjiRyokucha
//
//  Created by German Buela on 12/3/16.
//  Copyright © 2016 German Buela. All rights reserved.
//

import UIKit
import ReactiveSwift
import ReactiveCocoa
import Result
import RealmSwift
import Gloss
import SwiftRater
import EasyTipView

let lastSatusRefreshKey = "lastSatusRefresh"

struct ReviewState {
    let totalCards: Int
    let answeredYes: Int
    let answeredNo: Int
    let answeredOther: Int
    let totalSubmitted: Int
    
    var totalAnswered: Int {
        return answeredYes + answeredNo + answeredOther
    }
    var totalUnanswered: Int {
        return totalCards - totalAnswered
    }
}

struct StartedSession {
    let reviewType: ReviewType
    let ids: [Int]
}

extension Dictionary {
    init(elements:[(Key, Value)]) {
        self.init()
        for (key, value) in elements {
            updateValue(value, forKey: key)
        }
    }
}

typealias StartAction = Action<ReviewType, Response, FetchError>
typealias StartStarter = ActionStarter<ReviewType, Response, FetchError>
typealias ButtonAction = Action<Bool, Bool, NoError>
typealias ReviewAction = Action<[ReviewEntry], Response, FetchError>
typealias SubmitAction = Action<[ReviewEntry], [SignalProducer<Response,FetchError>], FetchError>
fileprivate typealias RefreshStarter = ActionStarter<Void, Response, FetchError>

struct ReviewTypeSetup {
    let shouldEnable: MutableProperty<Bool>
    let cardCount: MutableProperty<Int>
    let learnedCount: MutableProperty<Int>
    let actualCount: MutableProperty<Int>
    let action: StartAction
}

protocol ReviewEngineProtocol: class {
    var reviewTitle: MutableProperty<String?> { get }
    var reviewColor: MutableProperty<UIColor> { get }
    var reviewInProgress: MutableProperty<Bool> { get }
    var toReviewCount: MutableProperty<Int> { get }
    var toSubmitCount: MutableProperty<Int> { get }
    var reviewState: MutableProperty<ReviewState?> { get }
    var reviewEntries: MutableProperty<[ReviewEntry]> { get }
    var shouldEnableReview: MutableProperty<Bool> { get }
    var shouldEnableSubmit: MutableProperty<Bool> { get }
    var reviewAction: ReviewAction! { get }
    var submitAction: SubmitAction! { get }
    var cancelAction: ButtonAction! { get }
    var emptySessionAttempt: MutableProperty<Bool> { get }
    var chunkSubmitProducers: MutableProperty<[SignalProducer<Response, FetchError>]> { get }
    var isSubmitting: MutableProperty<Bool> { get }
   
    func fetchMissingCards(cardModels: [CardModel], completion:((CardDataModel) -> ())?)
    func saveFetchedCards(response: Response)
}

extension ReviewEngineProtocol {
    static func fetchActionProducer(entries:[ReviewEntry]) -> SignalProducer<Response,FetchError> {
        let unansweredEntries = entries.filter {$0.rawAnswer == CardAnswer.unanswered.rawValue}
        guard unansweredEntries.count > 0 else { return SignalProducer.empty }
        
        let ids = unansweredEntries.map {$0.cardId}
        
        log("fetching ids: \(ids)")
        let fetchRq = CardFetchRequest(cardIds: ids)
        return fetchRq.requestProducer()!
    }
    
    func fetchMissingCards(cardModels: [CardModel], completion:((CardDataModel) -> ())?) {
        
        guard cardModels.count < reviewEntries.value.count else { return }
        
        let entriesToFetch = reviewEntries.value.filter { entry in
            return cardModels.first(where: { $0.cardId == entry.cardId} ) == nil
        }
        let fetchProducer = type(of: self).fetchActionProducer(entries: entriesToFetch)
        _ = fetchProducer
            .noErrorSignalProducer()
            .start(on: QueueScheduler(qos: .default, name: "fetchQueue"))
            .startWithValues { [weak self] response in
                self?.saveFetchedCards(response: response)
                if let completion = completion,
                    let model = response.model as? CardDataModel {
                    completion(model)
                }
            }
    }
    
    func reviewStateMapper(entries: [ReviewEntry]) -> ReviewState? {
        if reviewInProgress.value {
            let ids = entries.map { $0.cardId }
            
            let yesCount = entries.count(answer: .yes) +
                entries.count(answer: .easy) +
                entries.count(answer: .hard)
            let noCount = entries.count(answer: .no)
            let otherCount = entries.count(answer: .delete) +
                entries.count(answer: .skip)
            
            return ReviewState(totalCards: ids.count,
                               answeredYes: yesCount,
                               answeredNo: noCount,
                               answeredOther: otherCount,
                               totalSubmitted: entries.countSubmitted)
        }
        else {
            return nil
        }
    }
}

class SRSReviewEngine: ReviewEngineProtocol {
    var statusAction: Action<Void, Response, FetchError>!
    var refreshedSinceStartup = false
    
    private var startSignals: [Signal<StartedSession,NoError>] = []
    private var startedSession: MutableProperty<StartedSession?> = MutableProperty(nil)

    let reviewTitle: MutableProperty<String?> = MutableProperty(nil)
    let reviewColor: MutableProperty<UIColor> = MutableProperty(.ryokuchaDark)
    var reviewTypeSetups: [ReviewType: ReviewTypeSetup] = [:]
    let reviewInProgress: MutableProperty<Bool> = MutableProperty(false)
    var currentReviewType: MutableProperty<ReviewType?> = MutableProperty(nil)
    let reviewEntries: MutableProperty<[ReviewEntry]> = MutableProperty([])
    let studyEntries: MutableProperty<[StudyEntry]> = MutableProperty([])
    var toReviewCount: MutableProperty<Int> = MutableProperty(0)
    let toSubmitCount: MutableProperty<Int> = MutableProperty(0)
    let reviewState: MutableProperty<ReviewState?> = MutableProperty(nil)
    var cancelAction: ButtonAction!
    var reviewAction: ReviewAction!
    var submitAction: SubmitAction!
    let shouldEnableReview: MutableProperty<Bool> = MutableProperty(false)
    let shouldEnableSubmit: MutableProperty<Bool> = MutableProperty(false)
    let shouldEnableCancel: MutableProperty<Bool> = MutableProperty(false)
    let emptySessionAttempt: MutableProperty<Bool> = MutableProperty(false)
    let toStudyCount: MutableProperty<Int> = MutableProperty(0)
    let chunkSubmitProducers: MutableProperty<[SignalProducer<Response, FetchError>]> = MutableProperty([])
    let isSubmitting: MutableProperty<Bool> = MutableProperty(false)
    let shouldEnableStatus: MutableProperty<Bool> = MutableProperty(false)

    private var chunkIndex = 0

    var global: Global!
    
    init() {
        global = Database.getGlobal()
        SRSReviewEngine.syncLimit = global.syncLimit
    }
    
    static var syncLimit = defaultSyncLimit
    
    private class func submitActionProducer(entries:[ReviewEntry]) -> SignalProducer<[SignalProducer<Response,FetchError>],FetchError> {
        let submitBatchSize = syncLimit
 
        let unsubmittedEntries = entries.filter {$0.rawAnswer != CardAnswer.unanswered.rawValue
            && !$0.submitted
        }
        guard unsubmittedEntries.count > 0 else { return SignalProducer.empty }
        
        let entriesChunks = unsubmittedEntries.chunks(ofSize: submitBatchSize)
        let syncRqs = entriesChunks.map { (entries:[ReviewEntry]) -> SignalProducer<Response,FetchError> in
            let answers = entries.map { CardSyncModel(cardId:$0.cardId, answer:$0.cardAnswer) }
            let syncRq = SyncAnswersRequest(answers: answers)
            return syncRq.requestProducer()!
        }
        log("total chunks \(syncRqs.count)")
        return SignalProducer(value: syncRqs)
    }
    
    private class func titleFromReviewType(_ reviewType: ReviewType?) -> String {
        if let reviewType = reviewType {
            return reviewType.displayText
        } else {
            return ""
        }
    }
   
    public func wireUp() {
        reviewTypeSetups = Dictionary(elements: ReviewType.allTypes.map(reviewTypeSetupCreator))
        
        let failedSetup = reviewTypeSetups[.failed]!
        
        toStudyCount <~ Property.combineLatest(failedSetup.cardCount,
                                               failedSetup.learnedCount).map { cc, lc in
                                                let ts = cc - lc
                                                return max(ts, 0)
        }
        
        statusAction = Action<Void, Response, FetchError>(enabledIf: shouldEnableStatus, { _ in
            return GetStatusRequest().requestProducer()!
        })
        statusAction.react { [weak self] response in
            self?.updateCardCount(response: response)
            UserDefaults().set(Int(Date().timeIntervalSince1970), forKey: lastSatusRefreshKey)
            self?.refreshedSinceStartup = true
        }
        
        startSignals = reviewTypeSetups.keys.map { [unowned self] reviewType in
            self.startSignalCreator(from: reviewType)
        }
        
        startedSession <~ Signal.merge(startSignals).filter { [weak self] startedSession in
            guard let sself = self else { return false }
            return sself.sessionHasCards(session: startedSession)
        }
        
        toSubmitCount <~ reviewEntries.map { $0.countUnsubmitted }
        toReviewCount <~ reviewEntries.map { $0.count(answer: .unanswered) }
        
        shouldEnableStatus <~ isSubmitting.map { !$0 }
        shouldEnableCancel <~ isSubmitting.map { !$0 }
        
        shouldEnableReview <~ Property.combineLatest(toReviewCount, isSubmitting).map { count, submitting in count > 0 && !submitting }
        
        shouldEnableSubmit <~ Property.combineLatest(toSubmitCount, isSubmitting).map { count, submitting in count > 0 && !submitting }
        
        startedSession.react { [weak self] startedSession in
            self?.saveSession(startSession: startedSession)
        }

        reviewState <~ reviewEntries.map { [unowned self] reviewEntries in
            self.reviewStateMapper(entries: reviewEntries)
        }
        
        cancelAction = Action(enabler: shouldEnableCancel) { [weak self] _ in
            self?.cancelSession()
        }
        
        reviewAction = ReviewAction(enabledIf: shouldEnableReview, SRSReviewEngine.fetchActionProducer)
        
        reviewAction.react { [weak self] response in
            self?.saveFetchedCards(response: response)
        }
        
        submitAction = SubmitAction(enabledIf: shouldEnableSubmit, SRSReviewEngine.submitActionProducer)
        
        chunkSubmitProducers <~ submitAction.values
        chunkSubmitProducers.react { [weak self] in
            guard $0.count > 0 else { return }
            // start submitting chunks
            log("-> got chunk producers")
            self?.chunkIndex = 0
            self?.submitChunk()
        }

        isSubmitting <~ chunkSubmitProducers.map { $0.count > 1 }

        reviewInProgress <~ currentReviewType.map { $0 != nil }
        
        reviewTitle <~ currentReviewType.map(SRSReviewEngine.titleFromReviewType)
        reviewColor <~ currentReviewType.map { $0?.colors.enabledColor ?? .ryokuchaDark}
    }
    
    private func submitChunk() {
        guard chunkIndex < chunkSubmitProducers.value.count else {
            // finished submitting chunks
            chunkSubmitProducers.value = []
            return
        }
        log("chunk #\(chunkIndex)")
        let producer = chunkSubmitProducers.value[chunkIndex]
       
        producer.start(Observer(value: { [weak self] response in
                self?.completedSubmission(response: response)
            }, failed: { [weak self] _ in
                // finished submitting chunks
                self?.chunkSubmitProducers.value = []
            }, completed: { [weak self] in
                guard let sself = self else { return }
                sself.chunkIndex = sself.chunkIndex + 1
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Global.requestDelaySeconds) {
                    sself.submitChunk()
                }
        }))
    }

    public func start() {
        restoreState()
        refreshStatus()
        global.studyPhaseProperty.value = global.useStudyPhase
    }
    
    func refreshStatus() {
        global.refreshNeeded = false
        statusAction.apply(()).start()
    }

    func restoreState() {
        if let reviewTypeId = global.reviewType.value {
            currentReviewType.value = ReviewType(rawValue: reviewTypeId)
        } else {
            currentReviewType.value = nil
        }
        
        reviewEntries.value = Database.readAllForType()
        studyEntries.value = Database.readAllForType()
    }
    
    func saveFetchedCards(response: Response) {
        guard let model = response.model as? CardDataModel else { return }
        
        let entriesToSave = reviewEntries.value.filter { entry in
            model.cards.contains(where: { $0.cardId == entry.cardId })
        }

        Database.write(objects: entriesToSave) { _ in
            for entry in entriesToSave {
                if let card = model.cards.first(where: { entry.cardId == $0.cardId }) {
                    entry.keyword = card.keyword
                }
            }
        }
    }
    
    private func completedSubmission(response: Response) {
        guard let model = response.model as? SyncResultModel else {
            log("service temporarily unavailable!")
            return
        }
        let syncedIds = model.putIds
        let entries = reviewEntries.value
        log("reviewEntries.value \(entries.count) ids")
        
        guard entries.count > 0 else { return }
        
        log("put \(syncedIds.count) ids")

        
        let syncedEntries = entries.filter { syncedIds.contains($0.cardId) }
        Database.write(objects: syncedEntries) { realm in
            syncedEntries.forEach { entry in
                entry.submitted = true
                
                if let studyEntry = studyEntries.value.first(where: { entry.cardId == $0.cardId }) {
                    if entry.cardAnswer == .no || entry.cardAnswer == .skip {
                        studyEntry.learned = false
                        studyEntry.synced = false
                        realm.add(studyEntry, update: true)
                    } else {
                        if let index = studyEntries.value.index(of: studyEntry) {
                            studyEntries.value.remove(at: index)
                        }
                        realm.delete(studyEntry)
                    }
                } else {
                    if entry.cardAnswer == .no {
                        let studyEntry = StudyEntry()
                        studyEntry.cardId = entry.cardId
                        studyEntry.keyword = entry.keyword
                        studyEntry.learned = false
                        studyEntry.synced = true
                        realm.add(studyEntry, update: false)
                        studyEntries.value.append(studyEntry)
                    }
                }
            }
        }
        
        reviewEntries.value = reviewEntries.value
        log("-> completed")
    }
    
    private func startSignalCreator(from reviewType:ReviewType) -> Signal<StartedSession,NoError> {
        let setup = reviewTypeSetups[reviewType]!
        let validValues = setup.action.values.filter { response in
            return response.model is CardIdsModel
        }
        return validValues.map { [weak self] response in
            let model = response.model as! CardIdsModel
            log("Binding \(reviewType) cards with ids: \(model.ids)")
            
            if let sself = self,
                sself.global.syncLimit != model.syncLimit {
                Database.write(object: sself.global) {
                    sself.global.syncLimit = model.syncLimit
                }
            }
            
            return StartedSession(reviewType: reviewType,
                                  ids: model.ids)
        }
    }
    
    private func reviewTypeSetupCreator(from reviewType:ReviewType) -> (ReviewType,ReviewTypeSetup) {
        let shouldEnable: MutableProperty<Bool> = MutableProperty(false)
        let countProperty: MutableProperty<Int> = MutableProperty(0)
        let learnedCountProperty: MutableProperty<Int> = MutableProperty(0)
        var actualCountProperty: MutableProperty<Int> = MutableProperty(0)
        
        if case .failed = reviewType {
            actualCountProperty <~ Property.combineLatest(countProperty, learnedCountProperty, global.studyPhaseProperty).map { c, lc, s in
                return s ? min(c,lc) : c
            }
        } else {
            actualCountProperty = countProperty
        }
        shouldEnable <~ shouldEnableStartSignal(countProperty: actualCountProperty,
                                                reviewType: reviewType)
        
        let action = StartAction(enabledIf: shouldEnable) { [weak self] _ in
            var learnedOnly = false
            if case .failed = reviewType,
                let sself = self,
                sself.global.useStudyPhase {
                learnedOnly = true
            }
            return SRSStartRequest(reviewType: reviewType, learnedOnly: learnedOnly).requestProducer()!
        }
        
        let setup = ReviewTypeSetup(shouldEnable: shouldEnable,
                                    cardCount: countProperty,
                                    learnedCount: learnedCountProperty,
                                    actualCount: actualCountProperty,
                                    action: action)
        return (reviewType, setup)
    }
    
    private func sessionHasCards(session: StartedSession) -> Bool {
        return session.ids.count > 0
    }
    
    private func updateCardCount(response: Response) {
        if let model = response.model as? GetStatusModel {
            reviewTypeSetups[.expired]?.cardCount.value = model.expiredCards
            reviewTypeSetups[.expired]?.learnedCount.value = model.expiredCards
            
            reviewTypeSetups[.new]?.cardCount.value = model.newCards
            reviewTypeSetups[.new]?.learnedCount.value = model.newCards

            reviewTypeSetups[.failed]?.cardCount.value = model.failedCards
            reviewTypeSetups[.failed]?.learnedCount.value = model.learnedCards
        }
    }

    private func shouldEnableStartSignal(countProperty: MutableProperty<Int>,
                                         reviewType: ReviewType) -> Signal<Bool, NoError> {
        
        let result = Property.combineLatest(countProperty, currentReviewType)
            .map { (count:Int, inProgressReview:ReviewType?) -> Bool in
                return inProgressReview == nil && count > 0
        }
        return result.signal
    }

    func saveSession(startSession: StartedSession?) {
        guard let startSession = startSession else { return }
        
        let ids = startSession.ids.filter { [unowned self] cardId in
            guard case .failed = startSession.reviewType,
                self.global.useStudyPhase else { return true }
            
            if let entry = self.studyEntries.value.first(where: { entry in entry.cardId == cardId }) {
                return entry.learned
            } else {
                return true
            }
        }
        
        if ids.count == 0 && startSession.reviewType == .failed {
            emptySessionAttempt.value = true
            return
        }

        currentReviewType.value = startSession.reviewType
        
        reviewEntries.value = ids.map { cardId -> ReviewEntry in
            let reviewEntry = ReviewEntry()
            reviewEntry.cardId = cardId
            return reviewEntry
        }
        
        Database.write(object: global) {
            global.reviewType.value = startSession.reviewType.rawValue
        }
        let entries = reviewEntries.value
        if entries.count > 0 {
            Database.write(objects: entries) { _ in }
        }
    }
    
    func cancelSession() {
        log("Wiping session")
        Database.write(object: global) {
            global.reviewType.value = nil
        }
        Database.delete(objects: reviewEntries.value)
        reviewEntries.value = []
        currentReviewType.value = nil
        
        refreshStatus()
    }
}

class SRSViewController: UIViewController, ReviewDelegate {
    
    var engine: SRSReviewEngine!
    private var reviewViewController: ReviewViewController?
    
    @IBOutlet weak var reviewContainer: UIView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var dueView: UIView!
    @IBOutlet weak var newView: UIView!
    @IBOutlet weak var failedView: UIView!
    @IBOutlet weak var dueButton: UIButton!
    @IBOutlet weak var newButton: UIButton!
    @IBOutlet weak var failedButton: UIButton!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var duePadding: NSLayoutConstraint!
    @IBOutlet weak var newPadding: NSLayoutConstraint!
    @IBOutlet weak var failedPadding: NSLayoutConstraint!
   
    private var reviewTypeStarters: [ReviewType: StartStarter]!
    private var refreshStarter: RefreshStarter!
    
    private let srsTip = TipView(.srsButtons)
    private let submitTip = TipView(.submitAnswers)

    private class func buttonColorsFromReviewType(_ reviewType: ReviewType?) -> ButtonColors {
        if let reviewType = reviewType {
            return reviewType.colors
        } else {
            return ButtonColors(enabledColor: .darkGray, disabledColor: .gray)
        }
    }
    
    private class func colorFromState(_ tuple:(ButtonColors, Bool)) -> UIColor {
        let colors = tuple.0
        let enabled = tuple.1
        return colors.color(forState: enabled)
    }
    
    private class func buttonColorFromEnabledState(_ enabled: Bool) -> UIColor {
        return enabled ? .ryokuchaDark : .ryokuchaLight
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUp()
        wireUp()
        
        engine.start()
        
        srsTip.show(control: dueButton, parent: view)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        SwiftRater.check()

        if engine.global.refreshNeeded {
            engine.refreshStatus()
        } else if engine.refreshedSinceStartup,
            let lastRefresh = UserDefaults().value(forKey: lastSatusRefreshKey) as? Int {
            let then = Date(timeIntervalSince1970: TimeInterval(lastRefresh))
            let calendar = Calendar.current
            if let hours = calendar.dateComponents([.hour], from: then, to: Date()).hour,
                hours >= 12 {
                engine.refreshStatus()
            }
        }
        
        engine.studyEntries.value = engine.studyEntries.value
    }
    
    func setUp() {
        for reviewType in ReviewType.allTypes {
            let view = self.topButtonView(for: reviewType)
            view.roundedCorners()
        }
        
        reviewContainer.roundedCorners()
        self.view.backgroundColor = .ryokuchaFaint
    }
    
    func wireUp() {        
        reviewContainer.reactive.isHidden <~ engine.currentReviewType.map { $0 == nil }
        
        reviewTypeStarters = Dictionary(elements: ReviewType.allTypes.map { [unowned self] reviewType in
            
            let button = self.topButton(for: reviewType)
            let view = self.topButtonView(for: reviewType)
            let padding = self.paddingConstraint(for: reviewType)
            
            let setup = self.engine.reviewTypeSetups[reviewType]!
            let starter = ActionStarter(control: button,
                                        action: setup.action,
                                        input: reviewType)
            
            button.reactive.controlEvents(.touchDown).uiReact { _ in
                UIView.animate(withDuration: 0.3,
                               animations: {
                                view.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
                })
            }
            button.reactive.controlEvents([.touchUpInside, .touchDragExit]).uiReact { _ in
                UIView.animate(withDuration: 0.3,
                               animations: {
                                view.transform = CGAffineTransform.identity
                })
            }

            self.activityIndicator.reactive.isAnimating <~ setup.action.isExecuting

            button.reactive.title(for: .normal) <~ setup.actualCount.map { "\($0)" }
            
            view.reactive.backgroundColor <~ setup.shouldEnable.combineLatest(with: self.engine.currentReviewType).map { (shouldEnable, currentRevType) in
                let colors = SRSViewController.buttonColorsFromReviewType(reviewType)
                if let current = currentRevType,
                    current != reviewType {
                    return colors.disabledColor
                }
                return shouldEnable ? colors.enabledColor : colors.disabledColor
            }
            
            self.engine.currentReviewType.uiReact { rtyp in
                UIView.animate(withDuration: 0.3) {
                    padding.constant = rtyp == reviewType ? 0 : 30
                    view.layoutIfNeeded()
                }
            }

            return (reviewType, starter)
        })
        
        engine.currentReviewType.uiReact { [weak self] reviewType in
            guard let _ = reviewType else {
                if let vc = self?.reviewViewController {
                    vc.willMove(toParentViewController: nil)
                    vc.view.removeFromSuperview()
                    vc.removeFromParentViewController()
                    self?.reviewViewController = nil
                    self?.reviewContainer.isHidden = true
                }
                return
            }
            
            if let sself = self {
                let rvc = ReviewViewController(engine: sself.engine, delegate: sself)
                sself.reviewViewController = rvc
                sself.addChildViewController(rvc)
                rvc.view.frame = sself.reviewContainer.bounds
                sself.reviewContainer.addSubview(rvc.view)
                rvc.didMove(toParentViewController: sself)
                self?.reviewContainer.isHidden = false
            }
        }
        
        engine.emptySessionAttempt.uiReact { [weak self] _ in
            self?.showAlert("Nothing to review!\nUse the Study tab to mark kanji as learned")
        }
        
        refreshStarter = RefreshStarter(control: refreshButton,
                                        action: engine.statusAction,
                                        input: ())

        activityIndicator.reactive.isAnimating <~ engine.statusAction.isExecuting
        
        engine.statusAction.uiReact { [weak self] response in
            if let model = response.model as? GetStatusModel,
                let tabBarItem = self?.tabBarItem {
                tabBarItem.badgeValue = model.expiredCards > 0 ? "\(model.expiredCards)" : nil
            }
        }
        
        engine.toStudyCount.combineLatest(with: engine.global.studyPhaseProperty).uiReact { [weak self] (count, studyPhase) in
            let badge = studyPhase && count > 0 ? "\(count)" : nil
            self?.tabBarController?.tabBar.items![1].badgeValue = badge
        }
        
        engine.studyEntries.combineLatest(with: engine.global.studyPhaseProperty).uiReact { [weak self] (studyEntries, studyPhase) in
            let count = studyEntries.filter({ !$0.learned && $0.synced }).count
            let badge = studyPhase && count > 0 ? "\(count)" : nil
            self?.tabBarController?.tabBar.items![1].badgeValue = badge
        }
    }

    func userDidAnswer(reviewAnswer: ReviewAnswer) {
        guard let reviewEntry = engine.reviewEntries.value.first(where: { $0.cardId == reviewAnswer.cardId }) else {
            log("card not in review!!")
            return
        }
        
        engine.reviewEntries.value = engine.reviewEntries.value
        
        Database.write(object: reviewEntry) {
            reviewEntry.cardAnswer = reviewAnswer.answer
        }
    }

    func userFinishedReview() {
        log("finished review")
        engine.reviewEntries.value = engine.reviewEntries.value
        if let submitButton = reviewViewController?.submitButton {
            submitTip.show(control: submitButton, parent: view)            
        }
    }
    
    func topButtonView(for reviewType: ReviewType) -> UIView {
        switch reviewType {
        case .expired:
            return dueView
        case .new:
            return newView
        case .failed:
            return failedView
        }
    }
    
    func topButton(for reviewType: ReviewType) -> UIButton {
        switch reviewType {
        case .expired:
            return dueButton
        case .new:
            return newButton
        case .failed:
            return failedButton
        }
    }
    
    func paddingConstraint(for reviewType: ReviewType) -> NSLayoutConstraint {
        switch reviewType {
        case .expired:
            return duePadding
        case .new:
            return newPadding
        case .failed:
            return failedPadding
        }
    }
}
