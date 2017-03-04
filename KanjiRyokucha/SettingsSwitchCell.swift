//
//  SettingsSwitchCell.swift
//  KanjiRyokucha
//
//  Created by German Buela on 2/27/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import UIKit

class SettingsSwitchCell: UITableViewCell {
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var subtitle: UILabel!
    @IBOutlet weak var uiswitch: UISwitch!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        uiswitch.tintColor = .ryokuchaDark
        uiswitch.onTintColor = .ryokuchaDark
    }
}
