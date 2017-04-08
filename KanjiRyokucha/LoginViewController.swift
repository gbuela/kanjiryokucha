//
//  LoginViewController.swift
//  KanjiRyokucha
//
//  Created by German Buela on 3/15/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import UIKit
import ReactiveSwift

class LoginViewController: UIViewController {
    
    @IBOutlet weak var loggingInLabel: UILabel!
    @IBOutlet weak var errorMessageLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var retryButton: UIButton!
    @IBOutlet weak var manualLoginButton: UIButton!
    
    let viewModel = LoginViewModel()
    var started = false

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .ryokuchaFaint
        
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
        activityIndicator.reactive.isHidden <~ viewModel.state.map { !$0.isLoggingIn() }
        loggingInLabel.reactive.isHidden <~ viewModel.state.map { !$0.isLoggingIn() }
        
        activityIndicator.reactive.isAnimating <~ viewModel.state.map { $0.isLoggingIn() }
        
        errorMessageLabel.reactive.isHidden <~ viewModel.state.map { !$0.isFailure() }
        retryButton.reactive.isHidden <~ viewModel.state.map { !$0.isFailure() }
        manualLoginButton.reactive.isHidden <~ viewModel.state.map { !$0.isFailure() }
        
        errorMessageLabel.reactive.text <~ viewModel.state.map {
            switch $0 {
            case .failure(let message): return message
            default: return ""
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
