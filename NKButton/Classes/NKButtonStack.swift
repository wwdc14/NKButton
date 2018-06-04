//
//  NKButtonStack.swift
//  NKButton
//
//  Created by Nam Kennic on 8/23/17.
//  Copyright © 2017 Nam Kennic. All rights reserved.
//

import UIKit
import NKFrameLayoutKit

public struct NKButtonItem {
	var title: String?
	var image: UIImage?
	var selectedImage: UIImage?
	var userInfo : Any?
}

public class NKButtonStack: UIControl {
	
	public var items : [NKButtonItem]? = nil {
		didSet {
			updateLayout()
			self.setNeedsLayout()
		}
	}
	
	public var buttons : [UIButton] {
		get {
			var results : [UIButton] = []
			frameLayout.enumerate { (layout, idx, stop) in
				results.append(layout!.targetView as! UIButton)
			}
			
			return results
		}
	}
	
	public var firstButton: UIButton? {
		get {
			return frameLayout.numberOfFrameLayouts > 0 ? frameLayout.frameLayout(at: 0).targetView as? UIButton : nil
		}
	}
	
	public var lastButton: UIButton? {
		get {
			return frameLayout.numberOfFrameLayouts > 0 ? frameLayout.last().targetView as? UIButton : nil
		}
	}
	
	public var spacing : CGFloat {
		get {
			return frameLayout.spacing
		}
		set {
			frameLayout.spacing = newValue
			self.setNeedsLayout()
		}
	}
	
	public var contentEdgeInsets : UIEdgeInsets {
		get {
			return frameLayout.edgeInsets
		}
		set {
			frameLayout.edgeInsets = newValue
			self.setNeedsLayout()
		}
	}
	
	override open var frame: CGRect {
		get {
			return super.frame
		}
		set (value) {
			let sizeChanged = true//self.frame.size != value.size
			super.frame = value
			if sizeChanged {
				self.setNeedsLayout()
			}
		}
	}
	
	override open var bounds: CGRect {
		get {
			return super.bounds
		}
		set (value) {
			let sizeChanged = true//self.bounds.size != value.size
			super.bounds = value
			if sizeChanged {
				self.setNeedsLayout()
			}
		}
	}
	
	public var selectedIndex: Int = -1 {
		didSet {
			for button in buttons {
				button.isSelected = selectedIndex == button.tag
			}
		}
	}
	
	public var direction: NKFrameLayoutDirection {
		get {
			return frameLayout.layoutDirection
		}
		set {
			frameLayout.layoutDirection = newValue
		}
	}
	
	public var buttonCreationBlock 		: ((_ item: NKButtonItem, _ index: Int) -> UIButton)? = nil
	public var buttonConfigurationBlock : ((_ button: UIButton, _ item: NKButtonItem, _ index: Int) -> Void)? = nil
	public var buttonSelectionBlock 	: ((_ button: UIButton, _ item: NKButtonItem, _ index: Int) -> Void)? = nil
	
	internal let scrollView = UIScrollView()
	internal var frameLayout : NKGridFrameLayout!
	
	// MARK: -
	
	convenience public init(items : [NKButtonItem], direction: NKFrameLayoutDirection = .horizontal) {
		self.init()
		
		self.direction = direction
		self.items = items
	}
	
	public init() {
		super.init(frame: .zero)
		
		frameLayout = NKGridFrameLayout(direction: .horizontal)
		frameLayout.layoutAlignment = .split
		frameLayout.spacing = 1.0
		frameLayout.intrinsicSizeEnabled = true
		frameLayout.autoRemoveTargetView = true
		frameLayout.shouldCacheSize = false
		
		scrollView.bounces = true
		scrollView.alwaysBounceHorizontal = false
		scrollView.alwaysBounceVertical = false
		scrollView.isDirectionalLockEnabled = true
		scrollView.showsVerticalScrollIndicator = false
		scrollView.showsHorizontalScrollIndicator = false
		scrollView.clipsToBounds = false
		scrollView.addSubview(frameLayout)
		self.addSubview(scrollView)
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	override open func sizeThatFits(_ size: CGSize) -> CGSize {
		return frameLayout.sizeThatFits(size)
	}
	
	override open func layoutSubviews() {
		super.layoutSubviews()
		
		let contentSize = frameLayout.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
		scrollView.contentSize = contentSize
		scrollView.frame = self.bounds
		
		var contentFrame = self.bounds
		if contentSize.width > self.bounds.size.width {
			contentFrame.size.width = contentSize.width
		}
		frameLayout.frame = contentFrame
	}
	
	// MARK: -
	
	public func button(at index:Int) -> UIButton {
		return frameLayout.frameLayout(at: index).targetView as! UIButton
	}
	
	// MARK: -
	
	fileprivate func updateLayout() {
		if let buttonItems = items {
			let total = buttonItems.count
			
			if frameLayout.numberOfFrameLayouts > total {
				frameLayout.enumerate({ (layout, index, stop) in
					if Int(index) >= Int(total) {
						if let button: UIButton = layout?.targetView as? UIButton {
							button.removeTarget(self, action: #selector(onButtonSelected(_:)), for: .touchUpInside)
						}
					}
				})
			}
			
			frameLayout.numberOfFrameLayouts = total
			
			frameLayout.enumerate({ (layout, idx, stop) in
				let index = Int(idx)
				let buttonItem = items![index]
				let button : UIButton = layout?.targetView as? UIButton ?? buttonCreationBlock?(buttonItem, index) ?? UIButton(type: .custom)
				button.tag = index
				button.addTarget(self, action: #selector(onButtonSelected(_:)), for: .touchUpInside)
				scrollView.addSubview(button)
				layout!.targetView = button
				
				if buttonConfigurationBlock != nil {
					buttonConfigurationBlock!(button, buttonItem, index)
				}
				else {
					button.setTitle(buttonItem.title, for: .normal)
					button.setImage(buttonItem.image, for: .normal)
					
					if buttonItem.selectedImage != nil {
						button.setImage(buttonItem.selectedImage, for: .highlighted)
						button.setImage(buttonItem.selectedImage, for: .selected)
					}
				}
			})
		}
		else {
			frameLayout.enumerate({ (layout, index, stop) in
				if let button: UIButton = layout?.targetView as? UIButton {
					button.removeTarget(self, action: #selector(onButtonSelected(_:)), for: .touchUpInside)
				}
			})
			
			frameLayout.removeAllFrameLayout()
		}
	}
	
	@objc fileprivate func onButtonSelected(_ sender: UIButton) {
		if buttonSelectionBlock != nil {
			let index = sender.tag
			let item = items![index]
			buttonSelectionBlock!(sender, item, index)
		}
	}
	
}