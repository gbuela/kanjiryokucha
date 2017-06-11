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
    @IBOutlet weak var frameNumLabel: UILabel!
    @IBOutlet weak var learnedButton: UIButton!
    
    weak var delegate: StudyCellDelegate?
    var entry: StudyEntry? {
        didSet {
            updateUI()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        learnedButton.setImage(UIImage(named: "circle"), for: .normal)
        learnedButton.setImage(UIImage(named: "circlecheck"), for: .selected)
        
        updateUI()
    }
    
    private func updateUI() {
        guard let entry = entry,
            let button = learnedButton else { return }
        
        button.isSelected = entry.learned
        
        keywordLabel?.text = entry.keyword == "" ? "#\(entry.cardId)" : entry.keyword

        if let frameNum = entry.frameNum.value,
            frameNum > 0 {
            frameNumLabel?.text = "\(frameNum)"
        } else {
            frameNumLabel.text = ""
        }
    }
    
    @IBAction func learnedTapped() {
        guard let entry = entry else { return }
        delegate?.studyCellMarkLearnedTapped(entry: entry)
    }
    
}
