//
//  StudyViewController.swift
//  KanjiRyokucha
//
//  Created by German Buela on 3/30/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import UIKit
import ReactiveSwift
import RealmSwift
import PKHUD

fileprivate typealias StudySubmitAction = Action<[StudyEntry], [SignalProducer<Response,FetchError>], FetchError>
fileprivate typealias SubmitStarter = ActionStarter<[StudyEntry], [SignalProducer<Response, FetchError>], FetchError>
fileprivate typealias RefreshAction = Action<Void, Response, FetchError>
fileprivate typealias RefreshStarter = ActionStarter<Void, Response, FetchError>
fileprivate typealias FetchAction = Action<Void, Response, FetchError>

class StudyEngine {

    private class func submitActionProducer(entries: [StudyEntry]) -> SignalProducer<[SignalProducer<Response,FetchError>],FetchError> {
        let submitBatchSize = SRSReviewEngine.syncLimit
        
        let unsyncedEntries = entries.filter { !$0.synced }
        
        log("submitting \(unsyncedEntries.count) study changes")
        
        guard unsyncedEntries.count > 0 else { return SignalProducer.empty }
        
        let entriesChunks = unsyncedEntries.chunks(ofSize: submitBatchSize)
        let syncRqs = entriesChunks.map { (entries:[StudyEntry]) -> SignalProducer<Response,FetchError> in
            let learnedIds = entries.filter({$0.learned}).map { $0.cardId }
            let notLearnedIds = entries.filter({!$0.learned}).map { $0.cardId }
            let syncRq = SyncStudyRequest(learned: learnedIds, notLearned: notLearnedIds)
            return syncRq.requestProducer()!
        }
        log("total chunks \(syncRqs.count)")
        return SignalProducer(value: syncRqs)
    }
    
    var reviewEngine: SRSReviewEngine!
    let notLearnedEntries: MutableProperty<[StudyEntry]> = MutableProperty([])
    fileprivate var submitAction: StudySubmitAction!
    let shouldEnableSubmit: MutableProperty<Bool> = MutableProperty(false)
    let unsyncedEntries: MutableProperty<[StudyEntry]> = MutableProperty([])
    fileprivate var refreshAction: RefreshAction!
    fileprivate var fetchAction: FetchAction?
    let dataRefreshed: MutableProperty<Bool> = MutableProperty(false)
    let keywordsFetched: MutableProperty<Bool> = MutableProperty(false)
    let isFetchingKeywords: MutableProperty<Bool> = MutableProperty(false)
    let chunkSubmitProducers: MutableProperty<[SignalProducer<Response, FetchError>]> = MutableProperty([])
    let isSubmitting: MutableProperty<Bool> = MutableProperty(false)

    private var chunkIndex = 0

    func wireUp() {
        notLearnedEntries <~ reviewEngine.studyEntries.signal.map { entries in
            return entries.filter { entry in !entry.learned }
        }
        
        unsyncedEntries <~ reviewEngine.studyEntries.map { entries in
            return entries.filter { !$0.synced }
        }
        
        shouldEnableSubmit <~ Property.combineLatest(unsyncedEntries, isSubmitting).map { (unsynced, submitting) in
            return unsynced.count > 0 && !submitting
        }
        
        submitAction = StudySubmitAction(enabledIf: shouldEnableSubmit, execute: StudyEngine.submitActionProducer)
        
        chunkSubmitProducers <~ submitAction.values
        chunkSubmitProducers.react { [weak self] in
            guard $0.count > 0 else { return }
            // start submitting chunks
            log("-> got chunk producers")
            self?.chunkIndex = 0
            self?.submitChunk()
        }
        
        isSubmitting <~ chunkSubmitProducers.map { $0.count > 0 }

        refreshAction = RefreshAction(enabledIf: isSubmitting.map({!$0})) { _ in
            return StudyRefreshRequest().requestProducer()!
        }
        
        refreshAction.react { [weak self] response in
            if let ids = response.model as? StudyIdsModel {
                self?.updateStudyData(studyIds: ids)
            }
        }
        
        dataRefreshed.react { [weak self] _ in
            if let sself = self,
                let producer = sself.fetchActionProducer() {
                sself.isFetchingKeywords.value = true
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Global.requestDelaySeconds) {
                    sself.fetchKeywords(producer: producer)
                }
            }
        }
    }
    
    private func fetchKeywords(producer: SignalProducer<Response, FetchError>?) {
        guard let producer = producer else {
            isFetchingKeywords.value = false
            keywordsFetched.value = true
            return
        }
        log("fetching keywords!")
        fetchAction = FetchAction {
            return producer
        }
        if let action = fetchAction {
            action.react { [weak self] response in
                self?.updateKeywords(response: response)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Global.requestDelaySeconds) {
                    self?.fetchKeywords(producer: self?.fetchActionProducer())
                }
            }
            action.errors.react { [weak self] error in
                self?.isFetchingKeywords.value = false
                self?.keywordsFetched.value = true
            }
            action.apply(()).start()
        }
    }
    
    private func updateKeywords(response: Response) {
        guard let model = response.model as? CardDataModel else { return }
        let studyCards = studyEntries().value
        Database.write { realm in
            model.cards.forEach { fetchedCard in
                if let card = studyCards.first(where: {$0.cardId == fetchedCard.cardId}) {
                    card.keyword = fetchedCard.keyword
                    realm.add(card, update: .all)
                }
            }
        }
    }
    
    private func submitChunk() {
        guard chunkIndex < chunkSubmitProducers.value.count else {
            // finished submitting chunks
            chunkSubmitProducers.value = []
            return
        }
        log("chunk #\(chunkIndex)")
        let producer = chunkSubmitProducers.value[chunkIndex]
        
        producer.start(Signal.Observer(value: { [weak self] response in
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
    
    private func completedSubmission(response: Response) {
        if let result = response.model as? SyncStudyResultModel {
            self.updateSyncedData(result: result)
        }
    }
    
    func studyEntries() -> MutableProperty<[StudyEntry]> {
        return reviewEngine.studyEntries
    }
    
    func triggerStudyEntries() {
        reviewEngine.studyEntries.value = reviewEngine.studyEntries.value
    }
    
    private func updateSyncedData(result: SyncStudyResultModel) {
        log("finished sync \(result)")
        let entriesToRemove = reviewEngine.studyEntries.value.filter {
            result.putLearned.contains($0.cardId)
        }
        
        reviewEngine.studyEntries.value = reviewEngine.studyEntries.value.filter {
            !result.putLearned.contains($0.cardId)
        }
        
        Database.write { realm in
            entriesToRemove.forEach { entry in
                realm.delete(entry)
            }
            result.putNotLearned.forEach { studyId in
                confirmSync(cardId: studyId, learned: false, realm: realm)
            }
        }
        dataRefreshed.value = true
        reviewEngine.global.refreshNeeded = true
    }
    
    private func updateStudyData(studyIds: StudyIdsModel) {
        let oldStudyEntries = reviewEngine.studyEntries.value.map { ($0.cardId, $0.keyword, $0.frameNum.value) }
        
        let newStudyIds = studyIds.ids.filter { !studyIds.learnedIds.contains($0) }
        
        Database.delete(objects: reviewEngine.studyEntries.value)
        reviewEngine.studyEntries.value = []
        
        Database.write { realm in
            newStudyIds.forEach { studyId in
                var keyword = ""
                var frameNum: Int? = nil
                
                if let oldEntry = oldStudyEntries.first(where:{ $0.0 == studyId }) {
                    keyword = oldEntry.1
                    frameNum = oldEntry.2
                }
                
                let studyEntry = StudyEntry()
                studyEntry.cardId = studyId
                studyEntry.keyword = keyword
                studyEntry.learned = false
                studyEntry.synced = true
                studyEntry.frameNum.value = frameNum
                realm.add(studyEntry, update: .error)
                reviewEngine.studyEntries.value.append(studyEntry)
            }
        }
        reviewEngine.studyEntries.value = reviewEngine.studyEntries.value
        
        dataRefreshed.value = true
        reviewEngine.global.refreshNeeded = true
    }
    
    private func confirmSync(cardId: Int, learned: Bool, realm: Realm) {
        if let studyEntry = reviewEngine.studyEntries.value.first(where: { cardId == $0.cardId }) {
            confirmSync(entry: studyEntry, learned: learned, realm: realm)
        }
    }
    
    private func confirmSync(entry: StudyEntry, learned: Bool, realm: Realm) {
        entry.learned = learned
        entry.synced = true
        realm.add(entry, update: .all)
        log("confirmed sync \(entry.cardId)")
    }
    
    private func fetchActionProducer() -> SignalProducer<Response,FetchError>? {
        let incompleteEntries = studyEntries().value.filter {$0.keyword == ""}
        guard incompleteEntries.count > 0 else { return nil }
        
        let ids = incompleteEntries.map {$0.cardId}
        
        log("fetching ids: \(ids)")
        let fetchRq = CardFetchRequest(cardIds: ids)
        return fetchRq.requestProducer()!
    }
}

class StudyViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,
    UIViewControllerPreviewingDelegate, StudyPageDelegate, StudyCellDelegate, UISplitViewControllerDelegate, BackendAccess {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var submitLabel: UILabel!

    let studyCellId = "studyCellId"

    var engine: StudyEngine!
    var emptyStudyCell: EmptyStudyCell!
    private var submitStarter: SubmitStarter!
    private var refreshStarter: RefreshStarter!
    private let isProcessing: MutableProperty<Bool> = MutableProperty(false)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.barTintColor = .ryokuchaDark
        
        title = "Study"
        edgesForExtendedLayout = []
        view.backgroundColor = .ryokuchaFaint
        
        submitLabel.textColor = .grayIsh

        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 70

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "REFRESH", style: .plain, target: nil, action: nil)

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "ALL LEARNED", style: .plain, target: self, action: #selector(learnedTapped))

        emptyStudyCell = createEmptyCell(text: "no kanji to learn")
        
        wireUp()
        engine.triggerStudyEntries()
        
        splitViewController?.preferredDisplayMode = .oneBesideSecondary
        splitViewController?.delegate = self
    }

    private func createEmptyCell(text: String) -> EmptyStudyCell {
        let cell = Bundle.main.loadNibNamed("EmptyStudyCell", owner: self, options: nil)!.first as! EmptyStudyCell
        cell.label.text = text
        cell.clipsToBounds = true
        return cell
    }
    
    private func wireUp() {
        engine.wireUp()
        
        if let rightButton = navigationItem.rightBarButtonItem {
            rightButton.reactive.isEnabled <~ engine.notLearnedEntries.signal.map { entries in
                return entries.count > 0
            }
        }
        
        if #available(iOS 10.0, *) {
            submitButton.titleLabel?.adjustsFontForContentSizeCategory = true
        }
        
        submitLabel.reactive.text <~ engine.unsyncedEntries.map { "\($0.count)" }
        
        submitStarter = SubmitStarter(control: submitButton,
                                      action: engine!.submitAction,
                                      inputProperty: engine.unsyncedEntries)
        
        let leftButton = navigationItem.leftBarButtonItem!

        refreshStarter = RefreshStarter(control: leftButton,
                                        action: engine!.refreshAction,
                                        input: ())
        
        Property.combineLatest(engine.dataRefreshed,
                               engine.keywordsFetched).uiReact { [weak self] _ in
            self?.tableView.reloadData()
        }
        
        isProcessing <~ Property.combineLatest(engine.refreshAction.isExecuting,
                                               engine.isSubmitting,
                                               engine.isFetchingKeywords).map { $0 || $1 || $2 }
        
        tableView.reactive.isUserInteractionEnabled <~ isProcessing.map {!$0}
        
        isProcessing.uiReact { processing in
            if processing {
                HUD.show(.progress)
            } else {
                HUD.hide()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    @objc func learnedTapped() {
        confirm(title: "Mark all as learned",
                message: "Are you sure?",
                yesOption: "Yes",
                noOption: "Cancel") { [unowned self] _ in
                    self.engine.notLearnedEntries.value.forEach { entry in
                        self.mark(entry: entry, learned: true)
                    }
                    self.engine.dataRefreshed.value = true
                    self.engine.triggerStudyEntries()
        }
    }
    
    private func detailViewController(for entry: StudyEntry, indexPath: IndexPath) -> StudyPageViewController? {
        guard let scalar = UnicodeScalar(entry.cardId),
            let encoded = String(scalar).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
            else { return nil }
        
        let url = backendHost + "/study/kanji/" + encoded
        return StudyPageViewController.instanceForStudy(urlString: url,
                                                        keyword: entry.keyword,
                                                        isLearned: entry.learned,
                                                        indexPath: indexPath,
                                                        delegate: self)
    }
    
    // MARK: - Previewing
    
    func absoluteRect(_ subView: UIView) -> CGRect {
        return subView.convert(subView.bounds, to: view)
    }
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRow(at: location),
            let cell = tableView.cellForRow(at: indexPath) as? StudyCell,
            !absoluteRect(cell.learnedButton).contains(location),
            let entry = self.entry(forIndexPath: indexPath),
            let vc = detailViewController(for: entry, indexPath: indexPath) else { return nil }
        
        vc.preferredContentSize = CGSize(width: 0.0, height: 400.0)
        vc.isPreviewing.value = true
        return vc
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        if let vc = viewControllerToCommit as? StudyPageViewController {
            vc.isPreviewing.value
                = false
        }
        navigationController?.pushViewController(viewControllerToCommit, animated: true)
    }
    
    // MARK: - Table view data source

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            if engine.studyEntries().value.count > 0 {
                return 0
            }
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return engine.studyEntries().value.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 0 {
            return emptyStudyCell
        }
        
        let idx = indexPath.row - 1
        
        let cell = tableView.dequeueReusableCell(withIdentifier: studyCellId, for: indexPath) as! StudyCell
        
        cell.delegate = self
        cell.entry = engine.studyEntries().value[idx]
        
        return cell
    }
    
    private func isSelectable(indexPath: IndexPath) -> Bool {
        return tableView.cellForRow(at: indexPath) is StudyCell
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        guard isSelectable(indexPath: indexPath) else {
            return nil
        }
        
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return isSelectable(indexPath: indexPath)
    }
    
    private func entry(forIndexPath indexPath: IndexPath) -> StudyEntry? {
        guard indexPath.row > 0 else { return nil }
        
        if indexPath.row == 1 {
            guard engine.studyEntries().value.count > 0 else { return nil }
        }
        
        let idx = indexPath.row - 1
        return engine.studyEntries().value[idx]
    }

    // MARK: - Events
    
    func studyPageMarkLearnedTapped(indexPath: IndexPath) {
        markLearned(indexPath: indexPath)
        _ = navigationController?.popViewController(animated: true)
    }
    
    func studyCellMarkLearnedTapped(entry: StudyEntry) {
        if let index = engine.studyEntries().value.firstIndex(of: entry) {
            markLearned(indexPath: IndexPath(row: index + 1, section: 0))
        }
    }
    
    private func markLearned(indexPath: IndexPath, onlyToLearned: Bool = false) {
        guard indexPath.row > 0,
            let entry = self.entry(forIndexPath: indexPath) else { return }
        
        let toLearned = !entry.learned
        
        guard !onlyToLearned || toLearned else { return }

        mark(entry: entry, learned: toLearned)
        
        let cell = tableView.cellForRow(at: indexPath) as! StudyCell
        cell.entry = entry
        
        engine.triggerStudyEntries()
    }
    
    private func mark(entry: StudyEntry, learned: Bool) {
        Database.write(object: entry) {
            entry.learned = learned
            entry.synced = !learned
        }
    }
    
    // MARK: - Storyboard
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let cell = sender as? StudyCell,
            let indexPath = tableView.indexPath(for: cell),
            let entry = self.entry(forIndexPath: indexPath),
            let scalar = UnicodeScalar(entry.cardId),
            let encoded = String(scalar).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
            let navigationVC = segue.destination as? UINavigationController,
            let studyPageVC = navigationVC.viewControllers[0] as? StudyPageViewController else { return }
        
        let url = backendHost + "/study/kanji/" + encoded
        studyPageVC.setupInStudy(urlString: url,
                                 keyword: entry.keyword,
                                 isLearned: entry.learned,
                                 indexPath: indexPath,
                                 delegate: self)
    }
    
    // MARK: - Split controller delegate
    
    func splitViewController(_ splitViewController: UISplitViewController,
                             collapseSecondary secondaryViewController: UIViewController,
                             onto primaryViewController: UIViewController) -> Bool {
        return true
    }
}
