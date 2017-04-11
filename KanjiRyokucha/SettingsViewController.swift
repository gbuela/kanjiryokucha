//
//  SettingsViewController.swift
//  KanjiRyokucha
//
//  Created by German Buela on 2/27/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import UIKit
import RealmSwift

class SeparatorCell: UITableViewCell {}

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    var cells: [UITableViewCell]!
    var aboutCell: UITableViewCell!
    var selectableCells: [UITableViewCell]!
    var username: String?
    var global: Global!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        global = Database.getGlobal()
        
        edgesForExtendedLayout = []
        title = "Settings"
        
        usernameLabel.text = username
        
        let versionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String

        aboutCell = createDisclosureCell(title: "About")
        
        selectableCells = [aboutCell]
        
        cells = [
            createSeparatorCell(),
            createSwitchCell(title: "Animate cards", subtitle: "Use animations when reviewing cards.", state: global.useAnimations, handler: switchedAnimations),
            createSwitchCell(title: "Use Study phase", subtitle: "Only cards marked as learned are available for red pile review", state: global.useStudyPhase, handler: switchedStudy),
            createSeparatorCell(),
            createInfoCell(title: "Version", value: versionNumber),
            aboutCell
        ]
        
        tableView.tableFooterView = UIView()
    }
    
    private func switchedAnimations(isOn: Bool) {
        Database.write(object: global) {
            global.useAnimations = isOn
        }
    }
    
    private func switchedStudy(isOn: Bool) {
        Database.write(object: global) {
            global.useStudyPhase = isOn
            Global.studyPhaseFlag.value = isOn
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
        
        Realm.Configuration.defaultConfiguration = Realm.Configuration()

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
            let aboutPageVC = AboutViewController()
            navigationController?.pushViewController(aboutPageVC, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch cells[indexPath.row] {
        case is SettingsSwitchCell:
            return 84
        case is SeparatorCell:
            return 30
        case is SettingsInfoCell:
            return 53
        default:
            return 45
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cells[indexPath.row]
    }
}
