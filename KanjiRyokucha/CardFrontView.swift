//
//  CardFrontView.swift
//  KanjiRyokucha
//
//  Created by German Buela on 12/9/16.
//  Copyright © 2016 German Buela. All rights reserved.
//

import UIKit

class CardFrontView: UIView {

    @IBOutlet weak var keywordLabel: UILabel!
    @IBOutlet weak var tempImageView: UIImageView!
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var flipButton: UIButton!
    @IBOutlet weak var quitButton: UIButton!
    @IBOutlet weak var optionsButton: UIButton!
    @IBOutlet weak var drawHereLabel: UILabel!
    
    weak var buttonHandler: ButtonHandler?

    @IBAction func buttonTapped(_ sender: UIControl) {
        buttonHandler?.handle(button: sender)
    }
}
