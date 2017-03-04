//
//  ColorStateButton.swift
//  KanjiRyokucha
//
//  Created by German Buela on 12/15/16.
//  Copyright © 2016 German Buela. All rights reserved.
//

import UIKit

class ColorStateButton: UIButton {
    
    var buttonColors: ButtonColors?
    
    override var isEnabled: Bool {
        didSet {
            if let colors = buttonColors {
                backgroundColor = isEnabled ? colors.enabledColor : colors.disabledColor
            }
        }
    }
}
