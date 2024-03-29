//
//  CardBackView.swift
//  KanjiRyokucha
//
//  Created by German Buela on 12/25/16.
//  Copyright © 2016 German Buela. All rights reserved.
//

import UIKit

class CardBackView : UIView {
    @IBOutlet weak var keywordLabel: LookupLabel!
    @IBOutlet weak var kanjiLabel: UILabel!
    @IBOutlet weak var strokeCountLabel: UILabel!
    @IBOutlet weak var readingsTextView: UITextView!
    @IBOutlet weak var frameNumLabel: UILabel!
    @IBOutlet weak var drawingImageView: UIImageView!
    @IBOutlet weak var yesButton: UIButton!
    @IBOutlet weak var noButton: UIButton!
    @IBOutlet weak var easyButton: UIButton!
    @IBOutlet weak var hardButton: UIButton!
    @IBOutlet weak var optionsButton: UIButton!
    @IBOutlet weak var quitButton: UIButton!
    @IBOutlet weak var flipBackButton: UIButton!
    @IBOutlet weak var rootView: UIView!
    
    weak var buttonHandler: ButtonHandler?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        easyButton.titleLabel?.adjustsFontSizeToFitWidth = true
        hardButton.titleLabel?.adjustsFontSizeToFitWidth = true
        rootView.backgroundColor = .background
        drawingImageView.backgroundColor = .canvas
    }
    
    @IBAction func buttonTapped(_ sender: UIControl) {
        buttonHandler?.handle(button: sender)
    }
}
