//
//  KRButton.swift
//  KanjiRyokucha
//
//  Created by German Buela on 2/5/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import UIKit

struct ButtonColorScheme {
    let nonHighlightedEnabled: UIColor
    let nonHighlightedDisabled: UIColor
    let highlighted: UIColor
    let normalTitle: UIColor
    let highlightedTitle: UIColor
    let disabledTitle: UIColor
}

protocol ButtonColoring: AnyObject {
    var scheme: ButtonColorScheme { get }
    var isEnabled: Bool { get }
    var isHighlighted: Bool { get }
    var backgroundColor: UIColor? { get set }
    
    func setTitleColor(_ color: UIColor?,
                       for state: UIControl.State)
    
    func resolveBackground()
}

extension ButtonColoring {
    func initializeColors() {
        setTitleColor(scheme.normalTitle, for: .normal)
        setTitleColor(scheme.highlightedTitle, for: .highlighted)
        setTitleColor(scheme.disabledTitle, for: .disabled)
        
        backgroundColor = scheme.nonHighlightedEnabled
    }
    
    func resolveBackground() {
        backgroundColor = isHighlighted ? scheme.highlighted : nonHighlighted
    }
    var nonHighlighted: UIColor {
        return isEnabled ? scheme.nonHighlightedEnabled : scheme.nonHighlightedDisabled
    }
}

struct Schemes {
    static let krButton =
        ButtonColorScheme(nonHighlightedEnabled: .ryokuchaFaint,
                          nonHighlightedDisabled: .grayIsh,
                          highlighted: .ryokuchaDark,
                          normalTitle: .ryokuchaDark,
                          highlightedTitle: .white,
                          disabledTitle: .ryokuchaLight)
    
    static let submitStudyButton =
        ButtonColorScheme(nonHighlightedEnabled: .ryokuchaFaint,
                          nonHighlightedDisabled: .background,
                          highlighted: .ryokuchaLight,
                          normalTitle: .ryokuchaDark,
                          highlightedTitle: .white,
                          disabledTitle: .ryokuchaLight)

}

class BaseButton: UIButton, ButtonColoring {
    
    var scheme: ButtonColorScheme {
        return Schemes.krButton
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        initializeColors()
    }
    
    override var isEnabled: Bool {
        didSet {
            resolveBackground()
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            resolveBackground()
        }
    }
}

class KRButton : BaseButton {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        layer.cornerRadius = 8.0
        layer.borderColor = UIColor.ryokuchaDark.cgColor
        layer.borderWidth = 1.0
    }
}

class SubmitStudyButton : BaseButton {
    override var scheme: ButtonColorScheme {
        return Schemes.submitStudyButton
    }
}
