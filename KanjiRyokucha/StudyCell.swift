//
//  StudyCell.swift
//  KanjiRyokucha
//
//  Created by German Buela on 2/17/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import UIKit

protocol StudyCellDelegate: class {
    func studyCellMarkLearnedTapped(entry: StudyEntry)
}

class StudyCell: UITableViewCell {
    
    @IBOutlet weak var keywordLabel: UILabel!
    @IBOutlet weak var learnedButton: UIButton!
    
    weak var delegate: StudyCellDelegate?
    var entry: StudyEntry?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        keywordLabel.font = UIFont.preferredFont(forTextStyle: .body)
        if #available(iOS 10.0, *) {
            keywordLabel.adjustsFontForContentSizeCategory = true
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func learnedTapped() {
        guard let entry = entry else { return }
        delegate?.studyCellMarkLearnedTapped(entry: entry)
    }
    
}
