//
//  DrawingViewController.swift
//  KanjiRyokucha
//
//  Created by German Buela on 5/7/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import UIKit

class DrawingViewController: UIViewController {

    @IBOutlet weak var mainImage: UIImageView!
    @IBOutlet weak var tempImage: UIImageView!
    @IBOutlet weak var emptyImageLabel: UILabel!
    
    var lastPoint = CGPoint.zero
    var brushWidth: CGFloat = 5.0
    var opacity: CGFloat = 1.0
    var swiped = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        emptyImageLabel.isHidden = true
        swiped = false
        if let touch = touches.first {
            lastPoint = touch.location(in: tempImage)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        swiped = true
        if let touch = touches.first {
            let currentPoint = touch.location(in: tempImage)
            drawLineFrom(fromPoint: lastPoint, toPoint: currentPoint)
            lastPoint = currentPoint
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !swiped {
            drawLineFrom(fromPoint: lastPoint, toPoint: lastPoint)
        }
        
        let frame = tempImage.frame
        
        // Merge tempImageView into mainImageView
        UIGraphicsBeginImageContext(frame.size)
        mainImage.image?.draw(in:CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height), blendMode: .normal, alpha: 1.0)
        tempImage.image?.draw(in:CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height), blendMode: .normal, alpha: opacity)
        mainImage.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        tempImage.image = nil
    }
    
    private func drawLineFrom(fromPoint: CGPoint, toPoint: CGPoint) {
        let frame = tempImage.frame
        UIGraphicsBeginImageContext(frame.size)
        let context = UIGraphicsGetCurrentContext()
        
        tempImage.image?.draw(in:CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        
        context?.move(to: fromPoint)
        context?.addLine(to: toPoint)
        
        context?.setLineCap(.round)
        context?.setLineWidth(brushWidth)
        context?.setStrokeColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        context?.setBlendMode(.normal)
        
        context?.strokePath()
        
        tempImage.image = UIGraphicsGetImageFromCurrentImageContext()
        tempImage.alpha = opacity
        UIGraphicsEndImageContext()
    }

}
