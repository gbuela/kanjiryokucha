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
import Fabric
import Crashlytics
import ReactiveSwift
import PKHUD

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
    
    let sessionCheckAction: Action<Void, Response, FetchError>!

    let tabBarController = UITabBarController()
    
    init() {
        sessionCheckAction = Action<Void, Response, FetchError> { _ in
            return AccountInfoRequest().requestProducer()!
        }
    }
    
    func start(username: String) {
        let studySplitVC = studyStoryboard.instantiateViewController(withIdentifier: "studySplit") as! UISplitViewController
        let studyNav = studySplitVC.viewControllers[0] as! UINavigationController
        let studyMaster = studyNav.viewControllers[0] as! StudyViewController
        
        srsViewController.engine = reviewEngine
        studyEngine.reviewEngine = reviewEngine
        studyMaster.engine = studyEngine
        
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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var appController: AppController?
    var fromBackground: Bool = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.badge]) { (granted, error) in
                // Enable or disable features based on authorization.
            }
            center.delegate = self
        }
        
        initFabric()
        
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
            .setTitleTextAttributes([NSFontAttributeName : UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)], for: UIControlState.normal)
        
        UIToolbar.appearance().barTintColor = .ryokuchaDark
        UIToolbar.appearance().backgroundColor = .ryokuchaDark
        
        UITabBar.appearance().tintColor = .white
        UITabBar.appearance().barTintColor = .ryokuchaDark
        UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.black], for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.white], for: .selected)

        if #available(iOS 10, *) {
            UITabBarItem.appearance().badgeColor = .ryokuchaLighter
            let badgeTextAttributes = [NSForegroundColorAttributeName: UIColor.black]
            UITabBarItem.appearance().setBadgeTextAttributes(badgeTextAttributes, for: .normal)
        }
        
        subscribeNotifications()
        
        startAutologin()
        
        return true
    }
    
    private func initFabric() {
        guard let resourceUrl = Bundle.main.url(forResource: "fabric", withExtension: "apikey") else { return }
        let fabricApiKey = try! String(contentsOf: resourceUrl)
        let whiteSpace = CharacterSet.whitespacesAndNewlines
        let trimmedApiKey = fabricApiKey.trimmingCharacters(in: whiteSpace)
        Crashlytics.start(withAPIKey: trimmedApiKey)
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
            
            if !Global.isGuest(),
                let latest = Global.latestRequestDate,
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

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        guard !Global.isGuest(),
            let engine = appController?.srsViewController.engine else {
            log("BkgFetch: not a fetch scenario")
            completionHandler(.noData)
            return
        }
        
        log("BkgFetch: fetching")
        
        let oldCount = engine.reviewTypeSetups[.expired]?.cardCount.value ?? 0
        
        engine.statusAction.events.take(first: 1).react { event in
            if let response = event.value {
                self.processFetch(response: response, oldCount: oldCount, completionHandler: completionHandler)
            } else {
                log("didn't get a response: session may have expired")
                
                // give it time to see if the fetch attempt has triggered auto reauthentication + statusAction
                let delayInSeconds = 10.0
                DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + delayInSeconds) {
                    guard let engine = self.appController?.srsViewController.engine else {
                        log("BkgFetch: engine not found, desisting")
                        completionHandler(.noData)
                        return
                    }
                    log("waited a while, deciding now on current status")
                    
                    let newCount = engine.reviewTypeSetups[.expired]?.cardCount.value ?? 0
                    self.resolveStatus(oldCount: oldCount, newCount: newCount, completionHandler: completionHandler)
                }
            }
        }
        engine.refreshStatus()
    }
    
    func resolveStatus(oldCount: Int, newCount: Int, completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if newCount != oldCount {
            log("due count has changed: \(oldCount) -> \(newCount)")
            completionHandler(.newData)
        } else {
            log("due count hasn't changed: \(newCount)")
            completionHandler(.noData)
        }
    }
    
    func processFetch(response: Response, oldCount: Int, completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let model = response.model as? GetStatusModel {
            let newCount = model.expiredCards
            resolveStatus(oldCount: oldCount, newCount: newCount, completionHandler: completionHandler)
        } else {
            log("response model is not GetStatusModel")
            completionHandler(.failed)
        }
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
