//
//  TipView.swift
//  KanjiRyokucha
//
//  Created by German Buela on 4/14/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import Foundation
import EasyTipView

enum TipType: Int {
    case srsButtons = 0
    case startReview
    case strokeOrder
    case submitAnswers
    case studyTab
    case studyPhase
}

extension TipType {
    
    func key() -> String {
        return "tip_\(self.rawValue)"
    }
    
    func text() -> String {
        switch self {
        case .srsButtons:
            return "These are your SRS piles. Tap on either non-zero pile to start a review session."
        case .startReview:
            return "Start reviewing!"
        case .strokeOrder:
            return "Hint: stroke order is available for many kanjis, find it in Options."
        case .submitAnswers:
            return "Submit your answers to the SRS at Kanji Koohii."
        case .studyTab:
            return "Your failed cards are sent here, where you can mark them as learned for a future red pile review. If you switch off \"study phase\" in Settings, your failed cards get to the red pile immediately"
        case .studyPhase:
            return "From here check out the study page for your failed cards. Mark the ones you relearn, and then Submit so they enter the red pile for a future review."
        }
    }
}

class TipView : EasyTipViewDelegate {
    
    static var alwaysShow = false
    
    private var tip: EasyTipView?
    private var type: TipType?
    private var control: UIControl?
    
    private var showable: Bool {
        guard let tipType = type else { return false }
        guard !TipView.alwaysShow else { return true }
        let shown = UserDefaults.standard.bool(forKey: tipType.key())
        return !shown
    }
    
    init(_ tipType: TipType) {
        type = tipType
    }
    
    private func show(showingClosure: (() -> ())) {
        guard let tipType = type else { return }
        
        var preferences = EasyTipView.Preferences()
        preferences.drawing.foregroundColor = .white
        preferences.drawing.backgroundColor = .darkGray

        tip = EasyTipView(text: tipType.text(), preferences: preferences, delegate: self)
        
        showingClosure()
        UserDefaults.standard.set(true, forKey: tipType.key())
    }
    
    func show(barItem: UITabBarItem) {
        guard showable else { return }
        show() {
            tip?.show(forItem: barItem)
        }
    }
    
    func show(view: UIView, parent: UIView) {
        guard showable else { return }
        show() {
            tip?.show(forView: view, withinSuperview: parent)
        }
    }
    
    func show(control: UIControl, parent: UIView) {
        guard showable else { return }
        self.control = control
        show() {
            tip?.show(forView: control, withinSuperview: parent)
        }
        control.addTarget(self, action: #selector(controlTapped), for: .touchUpInside)
    }
    
    func dismiss() {
        tip?.dismiss()
        tip = nil
        control = nil
    }
    
    func rearrange() {
        tip?.rearrange()
    }
    
    @objc private func controlTapped() {
        tip?.dismiss()
        tip = nil
        control?.removeTarget(self, action: #selector(controlTapped), for: .touchUpInside)
        control = nil
    }
    
    func easyTipViewDidDismiss(_ tipView: EasyTipView) {
        tip = nil
        control = nil
    }
}
