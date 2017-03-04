//
//  AppDelegate.swift
//  KanjiRyokucha
//
//  Created by German Buela on 11/25/16.
//  Copyright © 2016 German Buela. All rights reserved.
//

import UIKit

struct TabModel {
    let title: String
    let imageName: String
    let viewController: UIViewController
}

let sessionExpiredNotification = "sessionExpiredNotification"
let sessionStartedNotification = "sessionStartedNotification"

struct AppController {
    
    let window = UIWindow(frame: UIScreen.main.bounds)
    
    let viewModel = SRSViewModel()
    let srsViewController = SRSViewController()
    let studyViewController = StudyViewController()
    let settingsViewController = SettingsViewController()

    let tabBarController = UITabBarController()
    
    func start(username: String) {
        srsViewController.viewModel = viewModel
        studyViewController.viewModel = viewModel
        
        let studyNav = UINavigationController(rootViewController: studyViewController)
        
        settingsViewController.username = username
        let settingsNav = UINavigationController(rootViewController: settingsViewController)
        
        viewModel.wireUp()

        let tabs: [TabModel] = [
            TabModel(title: "Review", imageName: "tabcards", viewController: srsViewController),
            TabModel(title: "Study", imageName: "tabstudy", viewController: studyNav),
            TabModel(title: "Free review", imageName: "tabfree", viewController: FreeReviewViewController()),
            TabModel(title: "Settings", imageName: "tabsettings", viewController: settingsNav)
        ]

        tabBarController.viewControllers = tabs.map { $0.viewController }
        window.rootViewController = tabBarController
        
        for tab in tabs {
            tab.viewController.tabBarItem = UITabBarItem(title: tab.title,
                                                         image: UIImage(named:tab.imageName)?.withRenderingMode(.alwaysOriginal),
                                                         selectedImage: UIImage(named:tab.imageName))
        }
        
        window.makeKeyAndVisible()
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var appController: AppController?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        UINavigationBar.appearance().barStyle = .default
        UINavigationBar.appearance().backgroundColor = .ryokuchaDark
        UINavigationBar.appearance().tintColor = .black
        UINavigationBar.appearance().isTranslucent = true

        UITabBar.appearance().tintColor = .white
        UITabBar.appearance().barTintColor = .ryokuchaDark
        UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.black], for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.white], for: .selected)

        subscribeNotifications()
        
        let loginController = LoginController()
        window = loginController.window
        loginController.start()
        
        return true
    }
    
    func subscribeNotifications() {
        NotificationCenter.default.addObserver(forName: Notification.Name(sessionExpiredNotification), object: nil, queue: OperationQueue.main, using: handleSessionExpired)
        NotificationCenter.default.addObserver(forName: Notification.Name(sessionStartedNotification), object: nil, queue: OperationQueue.main, using: handleSessionStarted)
    }
    
    func unsubscribeNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    func handleSessionExpired(_: Notification) {
        let loginController = LoginController()
        window = loginController.window
        loginController.start()
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

