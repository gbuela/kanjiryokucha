//
//  UIViewController+Utils.swift
//  KanjiRyokucha
//
//  Created by German Buela on 2/25/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func confirm(title: String, message: String, yesOption: String, noOption: String, yesHandler: @escaping ((UIAlertAction) -> ())) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: yesOption, style: .default, handler: yesHandler))
        
        alert.addAction(UIAlertAction(title: noOption, style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
}
