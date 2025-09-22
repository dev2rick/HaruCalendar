//
//  HaruCalendarDelegationProxy.swift
//  HaruCalendar
//
//  Created by Claude on 2025-09-20.
//  Copyright © 2025 HaruCalendar. All rights reserved.
//

import Foundation
import UIKit

// MARK: - HaruCalendarDelegationProxy

/// A simplified proxy that handles delegation forwarding using Swift-native approaches
/// Removes NSMethodSignature/NSInvocation dependency for pure Swift compatibility
public class HaruCalendarDelegationProxy: NSObject {
    
    // MARK: - Properties
    
    weak var delegation: AnyObject?
    var deprecations: [String: String] = [:]
    
    // MARK: - Initialization
    
    public override init() {
        super.init()
    }
    
    // MARK: - Protocol Compliance
    
    public override func responds(to aSelector: Selector!) -> Bool {
        guard let delegation = delegation else { return false }
        
        // First check if delegation responds to current selector
        if delegation.responds(to: aSelector) {
            return true
        }
        
        // Check if delegation responds to deprecated selector
        if let deprecatedSelector = deprecatedSelector(for: aSelector),
           delegation.responds(to: deprecatedSelector) {
            return true
        }
        
        return super.responds(to: aSelector)
    }
    
    public override func conforms(to aProtocol: Protocol) -> Bool {
        return delegation?.conforms(to: aProtocol) ?? false
    }
    
    // MARK: - Method Forwarding
    
    public override func forwardingTarget(for aSelector: Selector!) -> Any? {
        guard let delegation = delegation else { return nil }
        
        // Try current selector first
        if delegation.responds(to: aSelector) {
            return delegation
        }
        
        // Try deprecated selector with wrapper
        if let deprecatedSelector = deprecatedSelector(for: aSelector),
           delegation.responds(to: deprecatedSelector) {
            return DeprecatedMethodWrapper(
                target: delegation,
                originalSelector: aSelector,
                deprecatedSelector: deprecatedSelector
            )
        }
        
        return super.forwardingTarget(for: aSelector)
    }
    
    // MARK: - Direct Method Calls (Type-Safe)
    
    /// Safely calls optional delegate/dataSource methods with default values
    @objc dynamic func callOptionalMethod(_ selector: Selector, defaultReturn: Any? = nil, arguments: [Any] = []) -> Any? {
        guard let delegation = delegation else { return defaultReturn }
        
        if delegation.responds(to: selector) {
            return performMethodCall(on: delegation, selector: selector, arguments: arguments)
        }
        
        // Try deprecated version
        if let deprecatedSelector = deprecatedSelector(for: selector),
           delegation.responds(to: deprecatedSelector) {
            return performMethodCall(on: delegation, selector: deprecatedSelector, arguments: arguments)
        }
        
        return defaultReturn
    }
    
    private func performMethodCall(on target: AnyObject, selector: Selector, arguments: [Any]) -> Any? {
        switch arguments.count {
        case 0:
            return target.perform(selector)?.takeUnretainedValue()
        case 1:
            return target.perform(selector, with: arguments[0])?.takeUnretainedValue()
        case 2:
            return target.perform(selector, with: arguments[0], with: arguments[1])?.takeUnretainedValue()
        case 3:
            // For 3+ arguments, use runtime method calling
            return performComplexMethodCall(on: target, selector: selector, arguments: arguments)
        default:
            return nil
        }
    }
    
    private func performComplexMethodCall(on target: AnyObject, selector: Selector, arguments: [Any]) -> Any? {
        // Use method_getImplementation for complex calls
        guard let nsTarget = target as? NSObject else { return nil }
        
        guard let method = class_getInstanceMethod(type(of: nsTarget), selector) else { return nil }
        let implementation = method_getImplementation(method)
        
        // For methods with 3+ arguments, we need to handle them case by case
        // This is a simplified approach for the most common calendar delegate patterns
        
        if arguments.count == 3 {
            typealias ThreeArgFunction = @convention(c) (AnyObject, Selector, Any, Any, Any) -> Any?
            let function = unsafeBitCast(implementation, to: ThreeArgFunction.self)
            return function(target, selector, arguments[0], arguments[1], arguments[2])
        }
        
        return nil
    }
    
    // MARK: - Deprecation Handling
    
    private func deprecatedSelector(for selector: Selector) -> Selector? {
        let selectorString = NSStringFromSelector(selector)
        guard let deprecatedString = deprecations[selectorString] else {
            return nil
        }
        return NSSelectorFromString(deprecatedString)
    }
}

// MARK: - Deprecated Method Wrapper

/// A simplified wrapper for handling deprecated method calls
private class DeprecatedMethodWrapper: NSObject {
    weak var target: AnyObject?
    let originalSelector: Selector
    let deprecatedSelector: Selector
    
    init(target: AnyObject, originalSelector: Selector, deprecatedSelector: Selector) {
        self.target = target
        self.originalSelector = originalSelector
        self.deprecatedSelector = deprecatedSelector
        super.init()
    }
    
    override func responds(to aSelector: Selector!) -> Bool {
        if aSelector == originalSelector {
            return target?.responds(to: deprecatedSelector) ?? false
        }
        return super.responds(to: aSelector)
    }
    
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if aSelector == originalSelector {
            return target
        }
        return super.forwardingTarget(for: aSelector)
    }
    
    // Handle method forwarding using @objc dynamic methods
    @objc dynamic func handleMethodCall() -> Any? {
        return target?.perform(deprecatedSelector)?.takeUnretainedValue()
    }
    
    @objc dynamic func handleMethodCallWithOneArg(_ arg1: Any) -> Any? {
        return target?.perform(deprecatedSelector, with: arg1)?.takeUnretainedValue()
    }
    
    @objc dynamic func handleMethodCallWithTwoArgs(_ arg1: Any, _ arg2: Any) -> Any? {
        return target?.perform(deprecatedSelector, with: arg1, with: arg2)?.takeUnretainedValue()
    }
}

// MARK: - Factory Methods

public extension HaruCalendarDelegationProxy {
    
    /// Creates a delegation proxy for HaruCalendarDataSource
    static func dataSourceProxy() -> HaruCalendarDelegationProxy {
        let proxy = HaruCalendarDelegationProxy()
        proxy.setupDataSourceDeprecations()
        return proxy
    }
    
    /// Creates a delegation proxy for HaruCalendarDelegate
    static func delegateProxy() -> HaruCalendarDelegationProxy {
        let proxy = HaruCalendarDelegationProxy()
        proxy.setupDelegateDeprecations()
        return proxy
    }
    
    /// Creates a delegation proxy for HaruCalendarDelegateAppearance
    static func appearanceDelegateProxy() -> HaruCalendarDelegationProxy {
        let proxy = HaruCalendarDelegationProxy()
        proxy.setupAppearanceDelegateDeprecations()
        return proxy
    }
    
    // MARK: - Deprecation Setup
    
    private func setupDataSourceDeprecations() {
        // Add deprecated data source method mappings
        // Example: deprecations["calendar:titleFor:"] = "calendar:titleForDate:"
    }
    
    private func setupDelegateDeprecations() {
        // Add deprecated delegate method mappings
        // Example: deprecations["calendar:didSelect:at:"] = "calendar:didSelectDate:at:"
    }
    
    private func setupAppearanceDelegateDeprecations() {
        // Add deprecated appearance delegate method mappings
        // Example: deprecations["calendar:appearance:fillDefaultColorFor:"] = "calendar:appearance:fillColorForDate:"
    }
}

// MARK: - Convenience Methods

public extension HaruCalendarDelegationProxy {
    
    /// Convenience method for calling Bool-returning delegate methods
    func callBoolMethod(_ selector: Selector, defaultValue: Bool = true, arguments: [Any] = []) -> Bool {
        let result = callOptionalMethod(selector, defaultReturn: NSNumber(value: defaultValue), arguments: arguments)
        return (result as? NSNumber)?.boolValue ?? defaultValue
    }
    
    /// Convenience method for calling String-returning delegate methods
    func callStringMethod(_ selector: Selector, defaultValue: String? = nil, arguments: [Any] = []) -> String? {
        let result = callOptionalMethod(selector, defaultReturn: defaultValue, arguments: arguments)
        return result as? String
    }
    
    /// Convenience method for calling Int-returning delegate methods
    func callIntMethod(_ selector: Selector, defaultValue: Int = 0, arguments: [Any] = []) -> Int {
        let result = callOptionalMethod(selector, defaultReturn: NSNumber(value: defaultValue), arguments: arguments)
        return (result as? NSNumber)?.intValue ?? defaultValue
    }
    
    /// Convenience method for calling void delegate methods
    func callVoidMethod(_ selector: Selector, arguments: [Any] = []) {
        _ = callOptionalMethod(selector, defaultReturn: nil, arguments: arguments)
    }
    
    /// Convenience method for calling UIImage-returning delegate methods
    func callImageMethod(_ selector: Selector, arguments: [Any] = []) -> UIImage? {
        let result = callOptionalMethod(selector, defaultReturn: nil, arguments: arguments)
        return result as? UIImage
    }
    
    /// Convenience method for calling custom cell-returning delegate methods
    func callCellMethod(_ selector: Selector, arguments: [Any] = []) -> HaruCalendarCell? {
        let result = callOptionalMethod(selector, defaultReturn: nil, arguments: arguments)
        return result as? HaruCalendarCell
    }
}
