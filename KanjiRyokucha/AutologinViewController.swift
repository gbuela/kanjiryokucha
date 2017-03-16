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
    
    let viewModel = LoginViewModel()
    var started = false

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .ryokuchaLight
        
        wireUp()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !started {
            started = true
            viewModel.start()
        }
    }
    
    private func wireUp() {
        activityIndicator.reactive.isHidden <~ viewModel.state.map { (state:LoginState) in
            switch state {
            case .loggingIn:
                return false
            default:
                return true
            }
        }
        
        activityIndicator.reactive.isAnimating <~ viewModel.state.map { (state:LoginState) in
            switch state {
            case .loggingIn:
                return true
            default:
                return false
            }
        }
        
        errorMessageLabel.reactive.isHidden <~ viewModel.state.map { (state:LoginState) in
            switch state {
            case .failure(_): // TODO: shorter way to check this??
                return false
            default:
                return true
            }
        }
        loggingInLabel.reactive.isHidden <~ viewModel.state.map { (state:LoginState) in
            switch state {
            case .loggingIn:
                return false
            default:
                return true
            }
        }
        errorMessageLabel.reactive.text <~ viewModel.state.signal.map { state in
            switch state {
            case .failure(let message):
                return message
            default:
                return nil
            }
        }
        retryButton.reactive.isHidden <~ viewModel.state.map { (state:LoginState) in
            switch state {
            case .failure(_):
                return false
            default:
                return true
            }
        }
        manualLoginButton.reactive.isHidden <~ viewModel.state.map { (state:LoginState) in
            switch state {
            case .failure(_):
                return false
            default:
                return true
            }
        }
        
        retryButton.reactive.controlEvents(.touchUpInside).react { [weak self] _ in
            self?.viewModel.autologinOrPrompt()
        }
        
        manualLoginButton.reactive.controlEvents(.touchUpInside).react { [weak self] _ in
            self?.viewModel.credentialsRequired.value = true
        }
        
        viewModel.credentialsRequired.uiReact { [weak self] required in
            if required {
                self?.promptForCredentials()
            }
        }
    }
    
    private func promptForCredentials() {
        let credentialsVC = CredentialsViewController()
        credentialsVC.enteredCredentialsCallback = { [weak self] (username: String, password: String) in
            self?.viewModel.attemptLogin(withUsername: username, password: password)
        }
        present(credentialsVC, animated: true, completion: nil)
    }
}
