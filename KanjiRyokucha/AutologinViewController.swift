//
//  AutologinViewController.swift
//  KanjiRyokucha
//
//  Created by German Buela on 3/15/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import UIKit
import ReactiveSwift

class AutologinViewController: UIViewController {
    
    @IBOutlet weak var loggingInLabel: UILabel!
    @IBOutlet weak var errorMessageLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var retryButton: UIButton!
    @IBOutlet weak var manualLoginButton: UIButton!
    
    var loginController: LoginController!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .ryokuchaLight
        
        wireUp()
    }
    
    private func wireUp() {
        errorMessageLabel.reactive.isHidden <~ loginController.state.map { (state:LoginState) in
            switch state {
            case .failure(_): // TODO: shorter way to check this??
                return false
            default:
                return true
            }
        }
        loggingInLabel.reactive.isHidden <~ loginController.state.map { (state:LoginState) in
            switch state {
            case .loggingIn:
                return false
            default:
                return true
            }
        }
        errorMessageLabel.reactive.text <~ loginController.state.signal.map { state in
            switch state {
            case .failure(let message):
                return message
            default:
                return nil
            }
        }
        retryButton.reactive.isHidden <~ loginController.state.map { (state:LoginState) in
            switch state {
            case .failure(_):
                return false
            default:
                return true
            }
        }
        manualLoginButton.reactive.isHidden <~ loginController.state.map { (state:LoginState) in
            switch state {
            case .failure(_):
                return false
            default:
                return true
            }
        }
    }
}
