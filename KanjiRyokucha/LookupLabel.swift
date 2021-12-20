//
//  LookupLabel.swift
//  KanjiRyokucha
//
//  Created by German Buela on 6/11/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import UIKit

// Based on: https://stackoverflow.com/a/42587549/17138

protocol LookupLabelDelegate: AnyObject {
    func lookupRequested(forTerm term: String)
}

class LookupLabel: UILabel {
    
    weak var delegate: LookupLabelDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.sharedInit()
    }
    
    func sharedInit() {
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(self.showMenu)))
    }
    
    @objc func showMenu(sender: AnyObject?) {
        self.becomeFirstResponder()
        
        let menu = UIMenuController.shared
        
        let menuItem = UIMenuItem(title: "Look Up", action: #selector(self.dictionaryLookup(_:)))
        menu.menuItems = [menuItem]
        
        if !menu.isMenuVisible {
            menu.showMenu(from: self, rect: bounds)
        }
    }
    
    @objc func dictionaryLookup(_ sender: Any?) {
        log("looking up")
        if let term = text {
            delegate?.lookupRequested(forTerm: term)
        }
    }
    
    override func copy(_ sender: Any?) {
        let board = UIPasteboard.general
        
        board.string = text
        
        let menu = UIMenuController.shared
        
        menu.hideMenu()
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        
        if action == #selector(UIResponderStandardEditActions.copy) ||
            (delegate != nil && text != nil && action == #selector(self.dictionaryLookup(_:))) {
            return true
        }
        
        return false
    }
}
