//
//  KRButton.swift
//  KanjiRyokucha
//
//  Created by German Buela on 2/5/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import UIKit
import ReactiveSwift

class KRButton : UIButton {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        layer.cornerRadius = 8.0
        layer.borderColor = UIColor.ryokuchaDark.cgColor
        layer.borderWidth = 1.0
        
        setTitleColor(.ryokuchaDark, for: .normal)
        setTitleColor(.white, for: .highlighted)
        setTitleColor(.ryokuchaLight, for: .disabled)
        
        backgroundColor = .ryokuchaFaint
        
        reactive.backgroundColor <~ reactive.controlEvents(.touchDown).map {_ in UIColor.ryokuchaDark}
        reactive.backgroundColor <~ reactive.controlEvents(.touchUpInside).map {_ in UIColor.ryokuchaFaint}
    }
    
    override var isEnabled: Bool {
        get {
            return super.isEnabled
        }
        set {
            super.isEnabled = newValue
            backgroundColor = newValue ? .ryokuchaFaint : .white
        }
    }
}
