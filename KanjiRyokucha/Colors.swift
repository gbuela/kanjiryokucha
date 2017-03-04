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

let expiredColors = ButtonColors(enabledColor: UIColor("#FF9800"),
                                 disabledColor: UIColor("#FF980055"))

let newColors = ButtonColors(enabledColor: UIColor("#0277BD"),
                             disabledColor: UIColor("#0277BD55"))

let failedColors = ButtonColors(enabledColor: UIColor("#F44336"),
                             disabledColor: UIColor("#F4433655"))

extension UIColor {
    static var ryokuchaDark: UIColor {
        return UIColor("#88B319")
    }
    
    static var ryokuchaLight: UIColor {
        return UIColor("#D1EBB1")
    }
    
    static var ryokuchaTranslucent: UIColor {
        return UIColor("#88B31955")
    }
    
    static var ryokuchaLighter: UIColor {
        return UIColor("#DFFFBB")
    }
    
    static var ryokuchaFaint: UIColor {
        return UIColor("#EEFFEF")
    }
    
    static var pieYes: UIColor {
        return UIColor.ryokuchaDark
    }
    
    static var pieNo: UIColor {
        return UIColor("#E66351")
    }
    
    static var pieOther: UIColor {
        return UIColor("#97BCD0")
    }
    
    static var pieUnanswered: UIColor {
        return UIColor("#BCBDBB")
    }
    
    static var pieSubmitted: UIColor {
        return UIColor.darkGray
    }
    
    static var pieUnsubmitted: UIColor {
        return UIColor.pieUnanswered
    }
}
