//
//  GermansUtils.swift
//  github-users
//
//  Created by German Buela on 5/20/16.
//  Copyright © 2016 German Buela. All rights reserved.
//

import Foundation
import ReactiveSwift
import ReactiveCocoa
import Result

import PKHUD

extension UIControl {
    func tapReact(_ task:@escaping ((UIControl) -> Void)) {
        reactive.controlEvents(.touchUpInside).observe(on: UIScheduler()).observeValues(task)
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
        observe(on: UIScheduler()).observe { (event:Event<Signal.Value, Signal.Error>) in
            if let value = event.value {
                task(value)
            }
        }
    }
    
    func react(_ task:@escaping ((Value) -> Void)) {
        observe { (event:Event<Signal.Value, Signal.Error>) in
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
    convenience init(handler: @escaping ((Void) -> Void)) {
        self.init { _ in
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
    func noErrorSignal() -> Signal<Value,NoError> {
        return self.flatMapError(errorSkipper)
    }
    private func errorSkipper(error: Error) -> SignalProducer<Value,NoError> {
        return SignalProducer<Value, NoError>.empty
    }

}

extension SignalProducer {
    
    /**
     Turns the signal producer into a non-failing one in order to facilitate
     binding with <~ to a PropertyType variable. Any errors are ignored.
     
     - returns: a non-failing version of the input SignalProducer
     */
    func noErrorSignalProducer() -> SignalProducer<Value,NoError> {
        return self.flatMapError { error -> SignalProducer<Value,NoError> in
            return SignalProducer<Value, NoError>.empty
        }
    }

}

extension UITextField {
    
    /**
     Facilitates getting the UITextField text signal as required for binding to a PropertyType
     
     - returns: a non-failing text SignalProducer
     */
    func propertyBindingTextSignal() -> SignalProducer<String,NoError> {
        return self.propertyBindingTextSignal()
            .noErrorSignalProducer()
            .map { $0 }
    }
}

/** 
 ActionStarter wraps over CocoaAction and UIControl to prevent boilerplate for a common scenario:
 A control that triggers an Action. By default the UI event is .touchUpInside
 and the control will be enabled reflecting the Action's enabled state.
 */
public struct ActionStarter<Input, Output, Error: Swift.Error> {
    
    public let cocoaAction: CocoaAction<UIControl>
    public let action: Action<Input, Output, Error>
    private let control: UIControl
    
    private init(control:UIControl, action:Action<Input, Output, Error>, cocoaAction: CocoaAction<UIControl>, controlEvents: UIControlEvents, syncEnabled: Bool) {
        self.action = action
        self.control = control
        self.cocoaAction = cocoaAction
        
        self.control.addTarget(self.cocoaAction, action: CocoaAction<UIControl>.selector, for: controlEvents)
        
        if syncEnabled {
            control.reactive.isEnabled <~ self.action.isEnabled
        }
    }
    
    public init(control:UIControl, action:Action<Input, Output, Error>, inputProperty: MutableProperty<Input>, controlEvents: UIControlEvents = .touchUpInside, syncEnabled: Bool = true) {
        
        self.init(control: control,
                  action: action,
                  cocoaAction: CocoaAction<UIControl>(action, { _ in
                    return inputProperty.value
                  }),
                  controlEvents: controlEvents,
                  syncEnabled: syncEnabled
        )
    }
    
    public init(control:UIControl, action:Action<Input, Output, Error>, input:Input, controlEvents: UIControlEvents = .touchUpInside, syncEnabled: Bool = true) {
        
        self.init(control: control,
                  action: action,
                  cocoaAction: CocoaAction<UIControl>(action, input:input),
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
    
    static public func mergeErrors(controlActions:[ActionStarter]) -> Signal<Error,NoError> {
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
