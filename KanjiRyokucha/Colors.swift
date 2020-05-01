//
//  Colors.swift
//  KanjiRyokucha
//
//  Created by German Buela on 12/3/16.
//  Copyright © 2016 German Buela. All rights reserved.
//

import UIKit
import UIColor_Hex_Swift

struct ButtonColors {
    let enabledColor: UIColor
    let disabledColor: UIColor
    
    static var defaultColors: ButtonColors {
        return ButtonColors(enabledColor: .darkGray, disabledColor: .gray)
    }
    
    func color(forState enabled:Bool) -> UIColor {
        return enabled ? enabledColor : disabledColor
    }
}

let expiredColors = ButtonColors(enabledColor: UIColor(named: "expired") ?? UIColor("#FF9800"),
                                 disabledColor: UIColor("#FF980055"))

let newColors = ButtonColors(enabledColor: UIColor(named: "new") ?? UIColor("#0277BD"),
                             disabledColor: UIColor("#0277BD55"))

let failedColors = ButtonColors(enabledColor:  UIColor(named: "failed") ?? UIColor("#F44336"),
                             disabledColor: UIColor("#F4433655"))

extension UIColor {
    static var ryokuchaDark: UIColor {
        return UIColor(named: "dark") ?? UIColor("#88B319")
    }
    
    static var ryokuchaLight: UIColor {
        return UIColor(named: "light") ?? UIColor.white
    }
    
    static var ryokuchaTranslucent: UIColor {
        return UIColor("#88B31955")
    }
    
    static var ryokuchaLighter: UIColor {
        return UIColor("#DFFFBB")
    }
    
    static var grayIsh: UIColor {
        return UIColor.systemGray
    }
    
    static var background: UIColor {
        return UIColor(named: "background") ?? UIColor.white
    }
    
    static var ryokuchaFaint: UIColor {
        return UIColor(named: "faint") ?? UIColor.black
    }
    
    static var pieYes: UIColor {
        return UIColor.ryokuchaDark
    }
    
    static var pieNo: UIColor {
        return UIColor(named: "pieNo") ?? UIColor("#E66351")
    }
    
    static var pieOther: UIColor {
        return UIColor(named: "pieOther") ?? UIColor("#97BCD0")
    }
    
    static var pieUnanswered: UIColor {
        return UIColor(named: "pieUnanswered") ?? UIColor("#BCBDBB")
    }
    
    static var pieSubmitted: UIColor {
        return UIColor(named: "pieSubmitted") ?? UIColor.darkGray
    }
    
    static var canvas: UIColor {
        return UIColor(named: "canvas") ?? UIColor.darkGray
    }
    
    static var pieUnsubmitted: UIColor {
        return UIColor.pieUnanswered
    }
}
