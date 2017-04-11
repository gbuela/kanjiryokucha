//
//  WelcomeGuestViewController.swift
//  KanjiRyokucha
//
//  Created by German Buela on 4/9/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import UIKit

protocol WelcomeGuestDelegate : class {
    func enteringAsGuest()
}

class WelcomeGuestViewController: UIViewController {
    
    weak var delegate: WelcomeGuestDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ryokuchaFaint
    }
    
    @IBAction func start() {
        dismiss(animated: true) { [weak self] in
            self?.delegate?.enteringAsGuest()
        }
    }
    
    @IBAction func backToLogin() {
        dismiss(animated: true, completion: nil)
    }
}
