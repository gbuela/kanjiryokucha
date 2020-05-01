//
//  UIViewExtensions.swift
//  KanjiRyokucha
//
//  Created by German Buela on 12/9/16.
//  Copyright © 2016 German Buela. All rights reserved.
//

import UIKit

protocol UIViewLoading {}

extension UIView : UIViewLoading {}

extension UIViewLoading where Self : UIView {
    static func loadFromNib() -> Self {
        let nibName = "\(self)".split{$0 == "."}.map(String.init).last!
        let nib = UINib(nibName: nibName, bundle: nil)
        let view = nib.instantiate(withOwner: self, options: nil).first as! Self
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }
}

extension UIView {
    
    func layoutAttachAll(subview: UIView) {
        subview.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        subview.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        subview.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        subview.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
    }
    
    func roundedCorners() {
        roundedCorners(withRadius: 8)
    }
    
    func roundedCorners(withRadius radius: Int) {
        layer.cornerRadius = CGFloat(radius)
        clipsToBounds = true
    }
}

