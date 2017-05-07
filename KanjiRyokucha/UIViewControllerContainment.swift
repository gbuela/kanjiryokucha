//
//  UIViewControllerContainment.swift
//  KanjiRyokucha
//
//  Created by German Buela on 5/7/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import UIKit

extension UIViewController {
    func add(childViewController viewController: UIViewController, insideView view: UIView) {
        addChildViewController(viewController)
        view.addSubview(viewController.view)
        viewController.view.frame = view.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewController.didMove(toParentViewController: self)
    }
    
    func remove(childViewController viewController: UIViewController) {
        viewController.willMove(toParentViewController: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParentViewController()
    }
}
