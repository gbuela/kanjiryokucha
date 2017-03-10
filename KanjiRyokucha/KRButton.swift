//
//  KRButton.swift
//  KanjiRyokucha
//
//  Created by German Buela on 2/5/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import UIKit

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
    }
    
    override var isEnabled: Bool {
        didSet {
            backgroundColor = isEnabled ? .ryokuchaFaint : .white
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? .ryokuchaDark : .ryokuchaFaint
        }
    }
}
