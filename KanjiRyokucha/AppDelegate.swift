//
//  AppDelegate.swift
//  KanjiRyokucha
//
//  Created by German Buela on 11/25/16.
//  Copyright © 2016 German Buela. All rights reserved.
//

import UIKit
import UserNotifications
import SwiftRater
import ReactiveSwift
import PKHUD
import AVKit

struct TabModel {
    let title: String
    let imageName: String
    let viewController: UIViewController
}

let sessionExpiredNotification = "sessionExpiredNotification"
let sessionStartedNotification = "sessionStartedNotification"
let sessionCheckMinElapsedSeconds = 540

struct AppController {
    
    let window = UIWindow(frame: UIScreen.main.bounds)
    
    let studyStoryboard = UIStoryboard(name: "Study", bundle: nil)
    let reviewEngine = SRSReviewEngine()
    let studyEngine = StudyEngine()
    let srsViewController = SRSViewController()
    let settingsViewController = SettingsViewController()
    let splitDelegate = SplitDelegate()
    
    let sessionCheckAction: Action<Void, Response, FetchError>!

    let tabBarController = UITabBarController()
    
    init() {
        sessionCheckAction = Action<Void, Response, FetchError> { _ in
            return AccountInfoRequest().requestProducer()!
        }
    }
    
    func start(username: String) {
        let studyMaster = studyStoryboard.instantiateViewController(withIdentifier: "studyMaster") as! StudyViewController
        let studyDetailNav = studyStoryboard.instantiateViewController(withIdentifier: "studyDetailNav") as! UINavigationController
        let studyNav = UINavigationController(rootViewController: studyMaster)
        //        let detailNav = studyDetail.navigationController!
        
        let studySplitVC = UISplitViewController()
        studySplitVC.viewControllers = [studyNav, studyDetailNav]

        srsViewController.engine = reviewEngine
        studyEngine.reviewEngine = reviewEngine
        studyMaster.engine = studyEngine
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            studySplitVC.preferredDisplayMode = .allVisible
        } else {
            studySplitVC.delegate = splitDelegate
        }
        
        settingsViewController.username = username
        settingsViewController.global = reviewEngine.global
        let settingsNav = UINavigationController(rootViewController: settingsViewController)
        
        reviewEngine.wireUp()

        let tabs: [TabModel] = [
            TabModel(title: "Review", imageName: "tabreview", viewController: srsViewController),
            TabModel(title: "Study", imageName: "tabstudy", viewController: studySplitVC),
            TabModel(title: "Free review", imageName: "tabfree", viewController: FreeReviewViewController()),
            TabModel(title: "Settings", imageName: "tabsettings", viewController: settingsNav)
        ]

        tabBarController.viewControllers = tabs.map { $0.viewController }
        window.rootViewController = tabBarController
        
        for tab in tabs {
            tab.viewController.tabBarItem = UITabBarItem(title: tab.title,
                                                         image: UIImage(named:tab.imageName)?.withRenderingMode(.alwaysOriginal),
                                                         selectedImage: UIImage(named:"sel-" + tab.imageName))
        }
        
        window.makeKeyAndVisible()
        
        sessionCheckAction.isExecuting.uiReact { executing in
            if executing {
                HUD.show(.systemActivity)
            } else {
                HUD.hide()
            }
        }
    }
}

class SplitDelegate: UISplitViewControllerDelegate {
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        true
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var appController: AppController?
    var fromBackground: Bool = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }
        
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)

        SwiftRater.showLaterButton = true
    #if DEBUG
        SwiftRater.daysUntilPrompt = 1
        SwiftRater.usesUntilPrompt = 12
        SwiftRater.daysBeforeReminding = 1
        SwiftRater.showLog = true
        SwiftRater.debugMode = false
    #else
        SwiftRater.daysUntilPrompt = 7
        SwiftRater.usesUntilPrompt = 12
        SwiftRater.daysBeforeReminding = 2
        SwiftRater.showLog = false
        SwiftRater.debugMode = false
    #endif
        SwiftRater.appLaunched()

        UINavigationBar.appearance().barStyle = .default
        UINavigationBar.appearance().backgroundColor = .ryokuchaDark
        UINavigationBar.appearance().barTintColor = .ryokuchaDark
        UINavigationBar.appearance().tintColor = .black
        UINavigationBar.appearance().isTranslucent = true
        
        UIBarButtonItem.appearance()
            .setTitleTextAttributes([NSAttributedString.Key.font : UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)], for: UIControl.State.normal)
        
        UIToolbar.appearance().barTintColor = .ryokuchaDark
        UIToolbar.appearance().backgroundColor = .ryokuchaDark
        
        UITabBar.appearance().tintColor = .white
        UITabBar.appearance().barTintColor = .ryokuchaDark
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black], for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .selected)

        if #available(iOS 10, *) {
            UITabBarItem.appearance().badgeColor = .ryokuchaLighter
            let badgeTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
            UITabBarItem.appearance().setBadgeTextAttributes(badgeTextAttributes, for: .normal)
        }
        
        subscribeNotifications()
        
        startAutologin()
        
        return true
    }
    
    func startAutologin() {
        window = UIWindow(frame: UIScreen.main.bounds)
        let loginController = LoginViewController()
        window?.rootViewController = loginController
        window?.makeKeyAndVisible()
    }
    
    func subscribeNotifications() {
        NotificationCenter.default.addObserver(forName: Notification.Name(sessionExpiredNotification), object: nil, queue: OperationQueue.main, using: handleSessionExpired)
        NotificationCenter.default.addObserver(forName: Notification.Name(sessionStartedNotification), object: nil, queue: OperationQueue.main, using: handleSessionStarted)
    }
    
    func unsubscribeNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    func handleSessionExpired(_: Notification) {
        appController = nil
        startAutologin()
    }
    
    func handleSessionStarted(notification: Notification) {
        let controller = AppController()
        appController = controller
        let username = notification.object as! String
        window = controller.window
        controller.start(username: username)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        fromBackground = true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        if fromBackground {
            fromBackground = false
            log("Coming from bkg")
            
            if let latest = Global.latestRequestDate,
                let controller = appController {
                let elapsed = Int(Date().timeIntervalSince(latest))
                log("Elapsed since last rq: \(elapsed)")
                if elapsed > sessionCheckMinElapsedSeconds {
                    log("Checking session")
                    controller.sessionCheckAction.apply(()).start()
                }
            }
            
        } else {
            log("Not coming from bkg")
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // MARK: - Background fetch
    
    var bkgTask: BackgroundTask?
    var bkgFetcher: BackgroundFetcher?

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        bkgTask = BackgroundTask(application: UIApplication.shared)
        bkgTask?.begin()
        
        bkgFetcher = BackgroundFetcher { [weak self] fetcherResult in
            log("Completed BackgroundFetcher with \(fetcherResult)")
            switch fetcherResult {
            case .failure, .notChecked:
                log("NODATA")
                completionHandler(.noData)
            case .success(let oldCount, let newCount):
                self?.resolveStatus(oldCount: oldCount,
                                    newCount: newCount,
                                    completionHandler: completionHandler)
            }
            
            self?.bkgTask?.end()
            self?.bkgTask = nil
            self?.bkgFetcher = nil
        }
        
        bkgFetcher?.start()
    }
    
    func resolveStatus(oldCount: Int, newCount: Int, completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if newCount != oldCount && newCount > 0 {
            
            let global = Database.getGlobal()
            Database.write(object: global) {
                global.latestDueCount = newCount
            }
            global.refreshNeeded = true

            notifyNewDueCount(count: newCount)
            log("due count has changed: \(oldCount) -> \(newCount) / NEWDATA")
            completionHandler(.newData)
        } else {
            log("due count hasn't changed: \(newCount) / NODATA")
            completionHandler(.noData)
        }
    }

    private func notifyNewDueCount(count: Int) {
        guard #available(iOS 10.0, *) else { return }

        let message: String
        if Global.username != "" {
            message = "\(Global.username.capitalized), you have \(count) due cards to review"
        } else {
            message = "You have \(count) due cards to review"
        }
        notify(message: message, badgeCount: count as NSNumber)
    }
    
    private func notify(message: String, badgeCount: NSNumber?) {
        guard #available(iOS 10.0, *) else { return }

        let content = UNMutableNotificationContent()
        content.body = message
        content.sound = UNNotificationSound.default
        content.badge = badgeCount

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
        
        log("Notifying --> \(message)")
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.badge])
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
