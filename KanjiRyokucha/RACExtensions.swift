//
//  RACExtensions.swift
//  github-users
//
//  Created by German Buela on 5/20/16.
//  Copyright © 2016 German Buela. All rights reserved.
//

import Foundation
import ReactiveSwift
import ReactiveCocoa
import UIKit
import PKHUD

public protocol StarterControl {
    var isEnabledTarget: BindingTarget<Bool> { get }
    func addTarget(_ target: Any?,
                   action: Selector,
                   for controlEvents: UIControl.Event)
    func tapReact(_ task:@escaping ((UIControl) -> Void))
}

extension UIControl: StarterControl {
    public var isEnabledTarget: BindingTarget<Bool> {
        return reactive.isEnabled
    }
    public func tapReact(_ task:@escaping ((UIControl) -> Void)) {
        reactive.controlEvents(.touchUpInside).observe(on: UIScheduler()).observeValues(task)
    }
}

extension UIBarButtonItem: StarterControl {
    public var isEnabledTarget: BindingTarget<Bool> {
        return reactive.isEnabled
    }
    public func addTarget(_ target: Any?,
                   action: Selector,
                   for controlEvents: UIControl.Event) {
        self.target = target as AnyObject?
        self.action = action
    }
    public func tapReact(_ task:@escaping ((UIControl) -> Void)) {
        // no implementation
    }
}

extension MutableProperty {
    func uiReact(_ task:@escaping ((Value) -> Void)) {
        signal.observe(on: UIScheduler()).observeValues(task)
    }
    func react(_ task:@escaping ((Value) -> Void)) {
        signal.observeValues(task)
    }
}

extension Signal {
    func uiReact(_ task:@escaping ((Value) -> Void)) {
        observe(on: UIScheduler()).observe { (event:Event) in
            if let value = event.value {
                task(value)
            }
        }
    }
    
    func react(_ task:@escaping ((Value) -> Void)) {
        observe { (event:Event) in
            if let value = event.value {
                task(value)
            }
        }
    }
}

extension Property {
    func uiReact(_ task:@escaping ((Value) -> Void)) {
        signal.observe(on: UIScheduler()).observeValues(task)
    }
    func react(_ task:@escaping ((Value) -> Void)) {
        signal.observeValues(task)
    }
}

extension Action {
    convenience init(handler: @escaping (() -> Void)) {
        self.init { _ in
            return SignalProducer { (sink,disposable) in
                handler()
                sink.sendCompleted()
            }
        }
    }
    
    convenience init<P: PropertyProtocol>(enabler property: P, handler: @escaping (() -> Void)) where P.Value == Bool {
        self.init(enabledIf: property) { _ in
            return SignalProducer { (sink,disposable) in
                handler()
                sink.sendCompleted()
            }
        }
    }
    
    func react(_ task:@escaping ((Output) -> Void)) {
        self.values.observeValues(task)
    }
    
    func uiReact(_ task:@escaping ((Output) -> Void)) {
        self.values.observe(on: UIScheduler()).observeValues(task)
    }
}

extension Signal {
    func noErrorSignal() -> Signal<Value,Never> {
        return self.flatMapError(errorSkipper)
    }
    private func errorSkipper(error: Error) -> SignalProducer<Value,Never> {
        return SignalProducer<Value, Never>.empty
    }

}

extension SignalProducer {
    
    /**
     Turns the signal producer into a non-failing one in order to facilitate
     binding with <~ to a PropertyType variable. Any errors are ignored.
     
     - returns: a non-failing version of the input SignalProducer
     */
    func noErrorSignalProducer() -> SignalProducer<Value,Never> {
        return self.flatMapError { error -> SignalProducer<Value,Never> in
            return SignalProducer<Value, Never>.empty
        }
    }

}

/** 
 ActionStarter wraps over CocoaAction and UIControl to prevent boilerplate for a common scenario:
 A control that triggers an Action. By default the UI event is .touchUpInside
 and the control will be enabled reflecting the Action's enabled state.
 */
public struct ActionStarter<Input, Output, Error: Swift.Error> {
    
    public let cocoaAction: CocoaAction<StarterControl>
    public let action: Action<Input, Output, Error>
    private let control: StarterControl
    
    private init(control:StarterControl, action:Action<Input, Output, Error>, cocoaAction: CocoaAction<StarterControl>, controlEvents: UIControl.Event, syncEnabled: Bool) {
        self.action = action
        self.control = control
        self.cocoaAction = cocoaAction
        
        self.control.addTarget(self.cocoaAction, action: CocoaAction<StarterControl>.selector, for: controlEvents)
        
        if syncEnabled {
            control.isEnabledTarget <~ self.action.isEnabled
        }
    }
    
    public init(control:StarterControl, action:Action<Input, Output, Error>, inputProperty: MutableProperty<Input>, controlEvents: UIControl.Event = .touchUpInside, syncEnabled: Bool = true) {
        
        self.init(control: control,
                  action: action,
                  cocoaAction: CocoaAction<StarterControl>(action, { _ in
                    return inputProperty.value
                  }),
                  controlEvents: controlEvents,
                  syncEnabled: syncEnabled
        )
    }
    
    public init(control:StarterControl, action:Action<Input, Output, Error>, input:Input, controlEvents: UIControl.Event = .touchUpInside, syncEnabled: Bool = true) {
        
        self.init(control: control,
                  action: action,
                  cocoaAction: CocoaAction<StarterControl>(action, input:input),
                  controlEvents: controlEvents,
                  syncEnabled: syncEnabled
        )
    }

    /**
     Provides observation for the action's Completed event on the UIScheduler.
     
     - parameter handler: closure to execute on the UIScheduler on completed action
     */
    public func observeActionComplete(handler:@escaping (() -> ())) -> Void {
        self.action.events
            .filter {
                if case .completed = $0 {
                    return true
                } else {
                    return false
                }
            }
            .observe(on: UIScheduler())
            .observeValues{ _ in handler() }
    }
    
    /**
     Provides observation for the action's errors on the UIScheduler
     
     - parameter handler: closure to execute on the UIScheduler on action error
     */
    public func observeActionErrors(handler:@escaping ((Error) -> ())) -> Void {
        self.action.errors
            .observe(on: UIScheduler())
            .observeValues { e in handler(e) }
    }
    
    static public func mergeErrors(controlActions:[ActionStarter]) -> Signal<Error,Never> {
        return Signal.merge(controlActions.map {$0.action.errors})
    }
}

extension ActionStarter {
    func useHUD() {
        self.cocoaAction.isExecuting.signal.observe(on: UIScheduler()).observeValues { executing in
            if executing {
                HUD.show(.progress)
            } else {
                HUD.hide()
            }
        }
    }
}
