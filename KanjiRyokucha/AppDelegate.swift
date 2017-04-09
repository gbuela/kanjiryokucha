//
//  AppDelegate.swift
//  KanjiRyokucha
//
//  Created by German Buela on 11/25/16.
//  Copyright © 2016 German Buela. All rights reserved.
//

import UIKit
import SwiftRater

struct TabModel {
    let title: String
    let imageName: String
    let viewController: UIViewController
}

let sessionExpiredNotification = "sessionExpiredNotification"
let sessionStartedNotification = "sessionStartedNotification"

struct AppController {
    
    let window = UIWindow(frame: UIScreen.main.bounds)
    
    let reviewEngine = SRSReviewEngine()
    let studyEngine = StudyEngine()
    let srsViewController = SRSViewController()
    let studyViewController = StudyViewController()
    let settingsViewController = SettingsViewController()

    let tabBarController = UITabBarController()
    
    func start(username: String) {
        srsViewController.engine = reviewEngine
        studyEngine.reviewEngine = reviewEngine
        studyViewController.engine = studyEngine
        
        let studyNav = UINavigationController(rootViewController: studyViewController)
        
        settingsViewController.username = username
        let settingsNav = UINavigationController(rootViewController: settingsViewController)
        
        reviewEngine.wireUp()

        let tabs: [TabModel] = [
            TabModel(title: "Review", imageName: "tabreview", viewController: srsViewController),
            TabModel(title: "Study", imageName: "tabstudy", viewController: studyNav),
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
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var appController: AppController?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
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
        UINavigationBar.appearance().tintColor = .black
        UINavigationBar.appearance().isTranslucent = true
        
        UIBarButtonItem.appearance()
            .setTitleTextAttributes([NSFontAttributeName : UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)], for: UIControlState.normal)
        
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
        startAutologin()
    }
    
    func handleSessionStarted(notification: Notification) {
        let appController = AppController()
        let username = notification.object as! String
        window = appController.window
        appController.start(username: username)
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
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

