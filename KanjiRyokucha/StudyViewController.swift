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

fileprivate typealias SubmitAction = Action<[StudyEntry], Response, FetchError>
fileprivate typealias SubmitStarter = ActionStarter<[StudyEntry], Response, FetchError>
fileprivate typealias RefreshAction = Action<Void, Response, FetchError>
fileprivate typealias RefreshStarter = ActionStarter<Void, Response, FetchError>

extension Array {
    func take(atMost maximum: Int) -> Array {
        let limit:Int = Swift.min(count, maximum)
        let result = self[0..<limit]
        return Array(result)
    }
}

class StudyViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,
    UIViewControllerPreviewingDelegate, StudyPageDelegate, StudyCellDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var submitLabel: UILabel!

    let studyCellId = "studyCellId"
    
    var viewModel: SRSViewModel!
    let studyEntries: MutableProperty<[StudyEntry]> = MutableProperty([])
    let learnedEntries: MutableProperty<[StudyEntry]> = MutableProperty([])
    var emptyStudyCell: EmptyStudyCell!
    var emptyLearnedCell: EmptyStudyCell!
    private var submitAction: SubmitAction!
    private var submitStarter: SubmitStarter!
    let shouldEnableSubmit: MutableProperty<Bool> = MutableProperty(false)
    let unsyncedEntries: MutableProperty<[StudyEntry]> = MutableProperty([])
    private var refreshAction: RefreshAction!
    private var refreshStarter: RefreshStarter!
    let dataRefreshed: MutableProperty<Bool> = MutableProperty(false)

    private class func submitActionProducer(entries: [StudyEntry]) -> SignalProducer<Response,FetchError> {
        let submitBatchSize = 10
        
        let learned = entries.filter({ !$0.synced && $0.learned }).map({ $0.cardId }).take(atMost: submitBatchSize)
        let notLearned = entries.filter({ !$0.synced && !$0.learned }).map({ $0.cardId }).take(atMost: submitBatchSize)
        
        print("submitting \(learned.count) learned, \(notLearned.count) not learned")
        
        guard learned.count > 0 || notLearned.count > 0 else { return SignalProducer.empty }
        
        let syncRq = SyncStudyRequest(learned: learned, notLearned: notLearned)
        return syncRq.requestProducer()!
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.barTintColor = .ryokuchaDark
        
        title = "Study"
        edgesForExtendedLayout = []
        view.backgroundColor = .ryokuchaFaint

        tableView.tableFooterView = UIView()

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "REFRESH", style: .plain, target: nil, action: nil)

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "ALL LEARNED", style: .plain, target: self, action: #selector(learnedTapped))
        
        let nib = UINib(nibName: "StudyCell", bundle: Bundle.main)
        tableView.register(nib, forCellReuseIdentifier: studyCellId)
        
        emptyStudyCell = createEmptyCell(text: "no kanji to learn")
        emptyLearnedCell = createEmptyCell(text: "no learned kanji")
        
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        }
        
        wireUp()
        viewModel.studyEntries.value = viewModel.studyEntries.value
    }

    private func createEmptyCell(text: String) -> EmptyStudyCell {
        let cell = Bundle.main.loadNibNamed("EmptyStudyCell", owner: self, options: nil)!.first as! EmptyStudyCell
        cell.label.text = text
        cell.clipsToBounds = true
        return cell
    }
    
    private func wireUp() {
        studyEntries <~ viewModel.studyEntries.signal.map { entries in
            return entries.filter { entry in !entry.learned }
        }
        learnedEntries <~ viewModel.studyEntries.signal.map { entries in
            return entries.filter { entry in entry.learned }
        }
        if let rightButton = navigationItem.rightBarButtonItem {
            rightButton.reactive.isEnabled <~ studyEntries.signal.map { entries in
                return entries.count > 0
            }
        }
        
        unsyncedEntries <~ viewModel.studyEntries.map { entries in
            return entries.filter { !$0.synced }
        }
        
        submitLabel.reactive.text <~ unsyncedEntries.map { "\($0.count)" }
        
        shouldEnableSubmit <~ unsyncedEntries.map { $0.count > 0 }
        
        submitAction = SubmitAction(enabledIf: shouldEnableSubmit, StudyViewController.submitActionProducer)
        
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
        let leftButton = navigationItem.leftBarButtonItem!

        refreshStarter = RefreshStarter(control: leftButton,
                                        action: refreshAction,
                                        input: ())
        
        refreshStarter.useHUD()
        
        dataRefreshed.uiReact { [weak self] _ in
            self?.tableView.reloadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    func learnedTapped() {
        confirm(title: "Mark all as learned",
                message: "Are you sure?",
                yesOption: "Yes",
                noOption: "Cancel") { [unowned self] _ in
                    for _ in 1...self.studyEntries.value.count {
                        self.markLearned(indexPath: IndexPath(row: 1, section: 0))
                    }
        }
    }
    
    private func detailViewController(for entry: StudyEntry, indexPath: IndexPath) -> StudyPageViewController? {
        guard let scalar = UnicodeScalar(entry.cardId),
            let encoded = String(scalar).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
            else { return nil }
        
        let url = "http://kanji.koohii.com/study/kanji/" + encoded
        let vc = StudyPageViewController()
        vc.urlToOpen = url
        vc.mode = entry.learned ? .studyLearned : .study
        vc.indexPath = indexPath
        vc.delegate = self
        return vc
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
        previewingContext.sourceRect = cell.frame
        return vc
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        navigationController?.pushViewController(viewControllerToCommit, animated: true)
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "kanji to learn"
        } else {
            return "learned kanji"
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 25))
        let label = UILabel(frame: CGRect(x: 10, y: 0, width: tableView.frame.size.width, height: 25))
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = .black
        label.text = self.tableView(tableView, titleForHeaderInSection: section)
        view.addSubview(label)
        view.backgroundColor = .ryokuchaLight
        view.autoresizingMask = []
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 25
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            if indexPath.section == 0 && studyEntries.value.count > 0 {
                return 0
            } else if indexPath.section == 1 && learnedEntries.value.count > 0 {
                return 0
            }
        }
        return 70
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return studyEntries.value.count + 1
        } else {
            return learnedEntries.value.count + 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 0 {
            return indexPath.section == 0 ? emptyStudyCell : emptyLearnedCell
        }
        
        let idx = indexPath.row - 1
        
        let cell = tableView.dequeueReusableCell(withIdentifier: studyCellId, for: indexPath) as! StudyCell
        
        cell.delegate = self
        if indexPath.section == 0 {
            cell.learnedButton.setTitle("❓", for: .normal)
            cell.keywordLabel?.text = studyEntries.value[idx].keyword
            cell.entry = studyEntries.value[idx]
        } else {
            cell.learnedButton.setTitle("✅", for: .normal)
            cell.keywordLabel?.text = learnedEntries.value[idx].keyword
            cell.entry = learnedEntries.value[idx]
        }
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
            guard (indexPath.section == 0 && studyEntries.value.count > 0) ||
                (indexPath.section == 1 && learnedEntries.value.count > 0) else { return nil }
        }
        
        let idx = indexPath.row - 1
        
        return indexPath.section == 0 ?
            studyEntries.value[idx] :
            learnedEntries.value[idx]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let entry = self.entry(forIndexPath: indexPath),
            let vc = detailViewController(for: entry, indexPath: indexPath) else { return }
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - Events
    
    func studyPageMarkLearnedTapped(indexPath: IndexPath) {
        markLearned(indexPath: indexPath)
        _ = navigationController?.popViewController(animated: true)
    }
    
    func studyCellMarkLearnedTapped(entry: StudyEntry) {
        if let index = studyEntries.value.index(of: entry) {
            markLearned(indexPath: IndexPath(row: index + 1, section: 0))
        } else if let index = learnedEntries.value.index(of: entry) {
            markLearned(indexPath: IndexPath(row: index + 1, section: 1))
        }
    }
    
    private func markLearned(indexPath: IndexPath) {
        guard indexPath.row > 0,
            let entry = self.entry(forIndexPath: indexPath) else { return }
        
        let toLearned = indexPath.section == 0
        let buttonTitle = toLearned ? "✅" : "❓"
        
        let cell = tableView.cellForRow(at: indexPath) as! StudyCell
        cell.learnedButton.setTitle(buttonTitle, for: .normal)
        
        Database.write(object: entry) {
            entry.learned = toLearned
            entry.synced = false
        }
        
        viewModel.studyEntries.value = viewModel.studyEntries.value
        
        let toSection = toLearned ? 1 : 0
        let prop = toLearned ? learnedEntries : studyEntries
        if let toIndex = prop.value.index(of: entry) {
            let toRow = toIndex + 1
            let toIndexPath = IndexPath(row: toRow, section: toSection)
            tableView.moveRow(at: indexPath, to: toIndexPath)
        } else {
            tableView.reloadData()
        }
    }
    
    // MARK: - 
    
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
        let entriesToRemove = viewModel.studyEntries.value.filter {
            result.putLearned.contains($0.cardId)
        }
        
        viewModel.studyEntries.value = viewModel.studyEntries.value.filter {
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
        viewModel.global.refreshNeeded = true
    }
    
    private func updateStudyData(studyIds: StudyIdsModel) {
        let oldStudyEntries = viewModel.studyEntries.value.map { ($0.cardId, $0.keyword) }
        
        let newStudyIds = studyIds.ids.filter { !studyIds.learnedIds.contains($0) }
        
        Database.delete(objects: viewModel.studyEntries.value)
        viewModel.studyEntries.value = []
        
        Database.write { realm in
            newStudyIds.forEach { studyId in
                var keyword = "#\(studyId)" // TODO: need to get the keyword

                if let oldEntry = oldStudyEntries.first(where:{ $0.0 == studyId }) {
                    keyword = oldEntry.1
                }

                let studyEntry = StudyEntry()
                studyEntry.cardId = studyId
                studyEntry.keyword = keyword
                studyEntry.learned = false
                studyEntry.synced = true
                realm.add(studyEntry, update: false)
                viewModel.studyEntries.value.append(studyEntry)
            }
        }
        viewModel.studyEntries.value = viewModel.studyEntries.value
        
        dataRefreshed.value = true
        viewModel.global.refreshNeeded = true
    }
}
