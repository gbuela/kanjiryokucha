//
//  Extensions.swift
//  KanjiRyokucha
//
//  Created by German Buela on 11/26/16.
//  Copyright © 2016 German Buela. All rights reserved.
//

import UIKit

extension UIAlertController {
    class func alert(_ message: String) -> UIAlertController {
        let ac = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        ac.addAction(OKAction)
        return ac
    }
}

extension UIViewController {
    func showAlert(_ message: String) {
        showAlert(message, completion: nil)
    }
    func showAlert(_ message: String, completion: (() -> ())?) {
        self.present(UIAlertController.alert(message), animated: true, completion: completion)
    }
    
}
