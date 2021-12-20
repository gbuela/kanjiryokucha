//
//  SettingsViewController.swift
//  KanjiRyokucha
//
//  Created by German Buela on 2/27/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import UIKit
import RealmSwift
import UserNotifications

class SeparatorCell: UITableViewCell {}

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    var cells: [UITableViewCell]!
    var aboutCell: UITableViewCell!
    var whatsNewCell: UITableViewCell!
    var debugCell: UITableViewCell?
    var notifCell: SettingsSwitchCell!
    var selectableCells: [UITableViewCell]!
    var username: String?
    var global: Global!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        edgesForExtendedLayout = []
        title = "Settings"
        
        headerView.backgroundColor = .background
        
        usernameLabel.text = username
        
        let versionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String

        aboutCell = createDisclosureCell(title: "About")
        whatsNewCell = createDisclosureCell(title: "What's new")
        #if DEBUG
            debugCell = createDisclosureCell(title: "Debug 🐞")
        #endif
        
        selectableCells = [aboutCell, whatsNewCell, debugCell].compactMap{$0}
        
        notifCell = createSwitchCell(title: "Notifications", subtitle: "Sets the app's badge and notifies you when the due count has changed", state: global.useNotifications, handler: { [weak self] in self?.switchedNotifications(isOn: $0) })
        
        if #available(iOS 10.0, *) {
        } else {
            notifCell.uiswitch.isEnabled = false
        }
        
        cells = [
            createSeparatorCell(),
            createSwitchCell(title: "Animate cards", subtitle: "Use animations when reviewing cards.", state: global.useAnimations, handler: { [weak self] in self?.switchedAnimations(isOn: $0) }),
            createSwitchCell(title: "Use Study phase", subtitle: "Only cards marked as learned are available for red pile review", state: global.useStudyPhase, handler: { [weak self] in self?.switchedStudy(isOn: $0) }),
            notifCell,
            createSeparatorCell(),
            createInfoCell(title: "Version", value: versionNumber),
            aboutCell,
            whatsNewCell,
            debugCell
            ].compactMap{$0}
        
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // If notifications were un-granted, turn the feature off
        if global.useNotifications,
            #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.getNotificationSettings { (settings) in
                if settings.authorizationStatus == .denied {
                    self.revertEnablingNotifications()
                }
            }
        }
    }
    
    private func switchedAnimations(isOn: Bool) {
        Database.write(object: global) {
            global.useAnimations = isOn
        }
    }
    
    private func switchedStudy(isOn: Bool) {
        Database.write(object: global) {
            global.useStudyPhase = isOn
            global.studyPhaseProperty.value = isOn
        }
    }
    private func switchedNotifications2(isOn: Bool) {
        self.finishEnablingNotifications(isOn)
    }
    private func switchedNotifications(isOn: Bool) {
        guard #available(iOS 10.0, *) else { return }
        
        if isOn {
            let center = UNUserNotificationCenter.current()
            center.getNotificationSettings { (settings) in
                switch settings.authorizationStatus {
                case .notDetermined:
                    center.requestAuthorization(options: [.badge, .alert, .sound]) { (granted, error) in
                        if !granted || error != nil {
                            self.revertEnablingNotifications()
                        } else {
                            self.finishEnablingNotifications(isOn)
                        }
                    }
                case .authorized:
                    self.finishEnablingNotifications(isOn)
                case .denied:
                    self.confirm(title: "Need notifications permission",
                            message: "To enable this feature you need to grant notifications permision on your device's settings page for Kanji Ryokucha",
                        yesOption: "Get me there",
                        noOption: "Not now") { _ in
                            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    }
                    self.revertEnablingNotifications()
                case .provisional,  .ephemeral:
                    break
                    
                @unknown default:
                    // FIXME: ver que onda
                    break
                }
            }
        } else {
            finishEnablingNotifications(isOn)
        }
    }
    
    private func revertEnablingNotifications() {
        DispatchQueue.main.async {
            self.notifCell.uiswitch.isOn = false
        }
    }
    
    private func finishEnablingNotifications(_ isOn: Bool) {
        DispatchQueue.main.async {
            Database.write(object: self.global) {
                self.global.useNotifications = isOn
            }
        }
    }
    
    private func createSwitchCell(title: String, subtitle: String, state: Bool, handler:@escaping ((Bool) -> ())) -> SettingsSwitchCell {
        let cell = Bundle.main.loadNibNamed("SettingsSwitchCell", owner: self, options: nil)!.first as! SettingsSwitchCell
        cell.title.text = title
        cell.subtitle.text = subtitle
        cell.uiswitch.isOn = state
        cell.uiswitch.reactive.isOnValues.react(handler)
        return cell
    }
    
    private func createInfoCell(title: String, value: String) -> SettingsInfoCell {
        let cell = Bundle.main.loadNibNamed("SettingsInfoCell", owner: self, options: nil)!.first as! SettingsInfoCell
        cell.titleLabel.text = title
        cell.valueLabel.text = value
        return cell
    }
    
    private func createDisclosureCell(title: String) -> SettingsInfoCell {
        let cell = Bundle.main.loadNibNamed("SettingsInfoCell", owner: self, options: nil)!.first as! SettingsInfoCell
        cell.titleLabel.text = title
        cell.valueLabel.text = nil
        cell.accessoryType = .detailButton
        return cell
    }
    
    private func createSeparatorCell() -> SeparatorCell {
        let cell = SeparatorCell()
        cell.backgroundColor = .ryokuchaLight
        return cell
    }
    
    @IBAction func logoutTapped() {
        let defaults = UserDefaults()
        defaults.set(nil, forKey: usernameKey)
        defaults.set(nil, forKey: passwordKey)
        
        Realm.Configuration.defaultConfiguration = Realm.ConfigurationWithMigration()
        Global.username = ""

        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(sessionExpiredNotification), object: nil)
    }
    
    // MARK: - Table datasource
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let cell = cells[indexPath.row]
        return selectableCells.contains(cell) ? indexPath : nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = cells[indexPath.row]
        if cell == aboutCell {
            show(resourceName: "about", title: "About")
        } else if cell == whatsNewCell {
            show(resourceName: "whatsnew", title: "What's New")
        } else if cell == debugCell {
            let logsVC = LogsViewController()
            navigationController?.pushViewController(logsVC, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func show(resourceName: String, title: String) {
        let webPageVC = WebViewController()
        webPageVC.title = title
        webPageVC.resourceName = resourceName
        navigationController?.pushViewController(webPageVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if cells[indexPath.row] is SeparatorCell {
            return 30
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cells[indexPath.row]
    }
}

