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
        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.view.frame = view.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewController.didMove(toParent: self)
    }
    
    func remove(childViewController viewController: UIViewController) {
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
}
