// Taken from http://stackoverflow.com/questions/37411320/change-the-value-of-constraint-for-only-iphone-4-in-ib/37411321#37411321

import UIKit

/**
 * This class used to modify easly the constraint for each device iPhone 4, iPhone 5, iPhone 6 or iPhone 6 Plus
 * You can modify the constant, the multiplier and also active / deactive the constraint for each device
 * You should modify this properties only in the storyboard
 */
@IBDesignable
public class LayoutConstraint: NSLayoutConstraint {
    
    // MARK: 📱3¨5
    
    /**
     * The constant for device with 3.5 insh size
     * The default value is the value of the constant of the constraint.
     */
    @IBInspectable
    public var 📱3¨5_const: CGFloat = 0 {
        didSet {
            if UIScreen.main.bounds.maxY == 480 {
                constant = 📱3¨5_const
            }
        }
    }
    
    /**
     * The multiplier for device with 3.5 insh size
     * The default value is the value of the constant of the constraint.
     */
    @IBInspectable
    public var 📱3¨5_multip: CGFloat = 0 {
        didSet {
            if UIScreen.main.bounds.maxY == 480 {
                self.setValue(📱3¨5_multip, forKey: "multiplier")
            }
        }
    }
    
    /**
     * The boolean to active deative constraint for device with 3.5 insh size
     * The default value is true.
     */
    @IBInspectable
    public var 📱3¨5_active: Bool = true {
        didSet {
            if UIScreen.main.bounds.maxY == 480 {
                isActive = 📱3¨5_active
            }
        }
    }
    
    // MARK: 📱4¨0
    
    /**
     * The constant for device with 4.0 insh size
     * The default value is the value of the constant of the constraint.
     */
    @IBInspectable
    public var 📱4¨0_const: CGFloat = 0 {
        didSet {
            if UIScreen.main.bounds.maxY == 568 {
                constant = 📱4¨0_const
            }
        }
    }
    
    /**
     * The multiplier for device with 4.0 insh size
     * The default value is the value of the constant of the constraint.
     */
    @IBInspectable
    public var 📱4¨0_multip: CGFloat = 0 {
        didSet {
            if UIScreen.main.bounds.maxY == 568 {
                self.setValue(📱4¨0_multip, forKey: "multiplier")
            }
        }
    }
    
    /**
     * The boolean to active deative constraint for device with 4.0 insh size
     * The default value is true.
     */
    @IBInspectable
    public var 📱4¨0_active: Bool = true {
        didSet {
            if UIScreen.main.bounds.maxY == 568 {
                isActive = 📱4¨0_active
            }
        }
    }
    
    // MARK: 📱4¨7
    
    /**
     * The constant for device with 4.7 insh size
     * The default value is the value of the constant of the constraint.
     */
    @IBInspectable
    public var 📱4¨7_const: CGFloat = 0 {
        didSet {
            if UIScreen.main.bounds.maxY == 667 {
                constant = 📱4¨7_const
            }
        }
    }
    
    /**
     * The multiplier for device with 4.7 insh size
     * The default value is the value of the constant of the constraint.
     */
    @IBInspectable
    public var 📱4¨7_multip: CGFloat = 0 {
        didSet {
            if UIScreen.main.bounds.maxY == 667 {
                self.setValue(📱4¨7_multip, forKey: "multiplier")
            }
        }
    }
    
    /**
     * The boolean to active deative constraint for device with 4.7 insh size
     * The default value is true.
     */
    @IBInspectable
    public var 📱4¨7_active: Bool = true {
        didSet {
            if UIScreen.main.bounds.maxY == 667 {
                isActive = 📱4¨7_active
            }
        }
    }
    // MARK: 📱5¨5
    
    /**
     * The constant for device with 5.5 insh size
     * The default value is the value of the constant of the constraint.
     */
    @IBInspectable
    public var 📱5¨5_const: CGFloat = 0 {
        didSet {
            if UIScreen.main.bounds.maxY == 736 {
                constant = 📱5¨5_const
            }
        }
    }
    
    /**
     * The multiplier for device with 5.5 insh size
     * The default value is the value of the constant of the constraint.
     */
    @IBInspectable
    public var 📱5¨5_multip: CGFloat = 0 {
        didSet {
            if UIScreen.main.bounds.maxY == 736 {
                self.setValue(📱5¨5_multip, forKey: "multiplier")
            }
        }
    }
    
    /**
     * The boolean to active / deactive constraint for device with 5.5 insh size
     * The default value is true.
     */
    @IBInspectable
    public var 📱5¨5_active: Bool = true {
        didSet {
            if UIScreen.main.bounds.maxY == 736 {
                isActive = 📱5¨5_active
            }
        }
    }
}
