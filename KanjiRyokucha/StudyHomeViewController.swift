//
//  StudyHomeViewController.swift
//  KanjiRyokucha
//
//  Created by German Buela on 3/25/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import UIKit
import PKHUD
import ReactiveSwift
import RealmSwift

fileprivate typealias RefreshAction = Action<Void, Response, FetchError>
fileprivate typealias RefreshStarter = ActionStarter<Void, Response, FetchError>
fileprivate typealias SubmitAction = Action<[StudyEntry], Response, FetchError>
fileprivate typealias SubmitStarter = ActionStarter<[StudyEntry], Response, FetchError>

extension Array {
    func take(atMost maximum: Int) -> Array {
        let limit:Int = Swift.min(count, maximum)
        let result = self[0..<limit]
        return Array(result)
    }
}

class StudyHomeViewController: UIViewController {
    
    private class func submitActionProducer(entries: [StudyEntry]) -> SignalProducer<Response,FetchError> {
        let submitBatchSize = 10
        
        let learned = entries.filter({ !$0.synced && $0.learned }).map({ $0.cardId }).take(atMost: submitBatchSize)
        let notLearned = entries.filter({ !$0.synced && !$0.learned }).map({ $0.cardId }).take(atMost: submitBatchSize)
        
        print("submitting \(learned.count) learned, \(notLearned.count) not learned")
        
        guard learned.count > 0 || notLearned.count > 0 else { return SignalProducer.empty }
        
        let syncRq = SyncStudyRequest(learned: learned, notLearned: notLearned)
        return syncRq.requestProducer()!
    }
    
    var viewModel: SRSViewModel!
    let unsyncedEntries: MutableProperty<[StudyEntry]> = MutableProperty([])
    private var submitAction: SubmitAction!
    private var submitStarter: SubmitStarter!
    private var refreshAction: RefreshAction!
    private var refreshStarter: RefreshStarter!
    let shouldEnableSubmit: MutableProperty<Bool> = MutableProperty(false)

    @IBOutlet weak var toStudyLabel: UILabel!
    @IBOutlet weak var learnedLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var toSubmitLabel: UILabel!
    @IBOutlet weak var refreshButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Study"
        view.backgroundColor = .ryokuchaFaint
        
        let backItem = UIBarButtonItem(title: "Done", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backItem
        
        wireUp()
    }
    
    func wireUp() {
        toStudyLabel.reactive.text <~ viewModel.toStudyCount.map { (count:Int) in "\(count) to study" }
        
        let failedSetup = viewModel.reviewTypeSetups[.failed]!
        learnedLabel.reactive.text <~ failedSetup.learnedCount.map { "\($0) learned" }
        
        unsyncedEntries <~ viewModel.studyEntries.map { entries in
            return entries.filter { !$0.synced }
        }
        
        toSubmitLabel.reactive.text <~ unsyncedEntries.map { "\($0.count)" }
        
        shouldEnableSubmit <~ unsyncedEntries.map { $0.count > 0 }
        
        submitAction = SubmitAction(enabledIf: shouldEnableSubmit, StudyHomeViewController.submitActionProducer)

        submitStarter = SubmitStarter(control: submitButton,
                                      action: submitAction,
                                      inputProperty: unsyncedEntries)
        submitStarter.useHUD()
        
        submitAction.react { [weak self] response in
            if let result = response.model as? SyncStudyResultModel {
                self?.updateSyncedData(result: result)
            }
        }
        
        refreshAction = RefreshAction { _ in
            return StudyRefreshRequest().requestProducer()!
        }
        refreshAction.react { [weak self] response in
            if let ids = response.model as? StudyIdsModel {
                self?.updateStudyData(studyIds: ids)
            }
        }
        
        refreshStarter = RefreshStarter(control: refreshButton,
                                        action: refreshAction,
                                        input: ())
        
        refreshStarter.useHUD()
        
        startButton.reactive.controlEvents(.touchUpInside).uiReact { [weak self] _ in
            let studyVC = StudyViewController()
            studyVC.viewModel = self?.viewModel
            self?.navigationController?.pushViewController(studyVC, animated: true)
        }
    }
    
    private func confirmSync(cardId: Int, learned: Bool, realm: Realm) {
        if let studyEntry = viewModel.studyEntries.value.first(where: { cardId == $0.cardId }) {
            confirmSync(entry: studyEntry, learned: learned, realm: realm)
        }
    }
    
    private func confirmSync(entry: StudyEntry, learned: Bool, realm: Realm) {
        entry.learned = learned
        entry.synced = true
        realm.add(entry, update: true)
        print("confirmed sync \(entry.cardId)")
    }
    
    private func updateSyncedData(result: SyncStudyResultModel) {
        print("finished sync \(result)")
        Database.write { realm in
            result.putLearned.forEach { studyId in
                confirmSync(cardId: studyId, learned: true, realm: realm)
            }
            result.putNotLearned.forEach { studyId in
                confirmSync(cardId: studyId, learned: false, realm: realm)
            }
        }
        viewModel.studyEntries.value = viewModel.studyEntries.value
    }
    
    private func updateStudyData(studyIds: StudyIdsModel) {
        var unsyncedIds = viewModel.studyEntries.value.map { $0.cardId }

        Database.write { realm in
            studyIds.ids.forEach { studyId in
                let isLearned = studyIds.learnedIds.contains(studyId)
                if let studyEntry = viewModel.studyEntries.value.first(where: { studyId == $0.cardId }) {
                    confirmSync(entry: studyEntry, learned: isLearned, realm: realm)
                } else {
                    let studyEntry = StudyEntry()
                    studyEntry.cardId = studyId
                    studyEntry.keyword = "#\(studyId)" // TODO: need to get the keyword
                    studyEntry.learned = isLearned
                    studyEntry.synced = true
                    realm.add(studyEntry, update: false)
                    viewModel.studyEntries.value.append(studyEntry)
                }
                
                if let index = unsyncedIds.index(of: studyId) {
                    unsyncedIds.remove(at: index)
                }
            }
            unsyncedIds.forEach { unsyncedId in
                if let studyEntry = viewModel.studyEntries.value.first(where: { unsyncedId == $0.cardId }) {
                    if let index = viewModel.studyEntries.value.index(of: studyEntry) {
                        viewModel.studyEntries.value.remove(at: index)
                    }
                    realm.delete(studyEntry)
                }
            }
        }
    }
}
