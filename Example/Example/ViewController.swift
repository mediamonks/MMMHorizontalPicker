//
//  ViewController.swift
//  Example
//
//  Copyright (C) 2016-2020 MediaMonks. All rights reserved.
//

import UIKit
import MMMHorizontalPicker

class ViewController: UIViewController, MMMHorizontalPickerDelegate {
	
	private let pickerView = MMMHorizontalPicker()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		pickerView.prototypeView = Item(index: 0)
		pickerView.delegate = self
		pickerView.spacing = 30
		pickerView.contentInsets = .init(top: 0, left: 30, bottom: 0, right: 30)
		view.addSubview(pickerView)
        
		do {
			pickerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
			pickerView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
			pickerView.heightAnchor.constraint(equalToConstant: 80).isActive = true
			pickerView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
		}
		
		for i in 0...8 {
			let item = Item(index: i)
			item.addTarget(self, action: #selector(itemDidTap), for: .touchUpInside)
			items.append(item)
		}
		
		pickerView.reload()
	}
	
	private var items = [Item]()
	
	// MARK: - Actions
	
	@objc private func itemDidTap(_ sender: Item) {
		pickerView.setCurrentItemIndex(sender.index, animated: true)
	}
	
	// MARK: - MMMHorizontalPickerDelegate
	
	func horizontalPickerDidChangeCurrentItemIndex(_ picker: MMMHorizontalPicker) {
		print("Current item index changed:", picker.currentItemIndex)
	}
	
	func numberOfItemsForHorizontalPicker(_ picker: MMMHorizontalPicker) -> Int {
		return items.count
	}
	
	func horizontalPicker(_ picker: MMMHorizontalPicker, viewForItemWith index: Int) -> UIView {
		return items[index]
	}
    
    func horizontalPicker(_ picker: MMMHorizontalPicker, recycle view: UIView) {
        // Called after an item view becomes invisible and is removed from the picker. The delegate can choose to store it somewhere and reuse it later or can just forget it and simply use a new view next time.
    }
    
    func horizontalPicker(_ picker: MMMHorizontalPicker, prepare view: UIView) {
        // Called after the given item view is added into the view hierarchy.
    }
    
    func horizontalPicker(_ picker: MMMHorizontalPicker, didScroll offset: CGFloat) {
        // Called when the picker scrolls to a new offset.
    }
    
    func horizontalPicker(_ picker: MMMHorizontalPicker, update view: UIView, centerProximity: CGFloat) {
        
        // Called every time the viewport position changes (every frame in case of animation or dragging) with an updated "center proximity" value for each visible item view.
        //
        // "Center proximity" is a difference between the center of the item and the current viewport  position in "index space" coordinates.
        //
        // For example, if the current item is in the center of the view port already, then its "center proximiy" value will be 0, and the same value for the view right (left) to the central item will be 1 (-1). When dragging the contents so the right view gets closer to the center, then its center proximity will be continously approaching 0.
        //
        // This is handy when you need to dim or transforms items when they get farther from the center, but be careful with doing heavy things here.
        
        let scale = 1 - (abs(centerProximity) / 4)
        
        view.transform = CGAffineTransform(scaleX: scale, y: scale)
    }
}

private class Item: UIControl {

	public let index: Int

	public init(index: Int) {
		self.index = index
		
		super.init(frame: .zero)
		
		translatesAutoresizingMaskIntoConstraints = false
		
		backgroundColor = index % 2 == 1 ? .red : .blue
	}
	
	override var isHighlighted: Bool {
		didSet {
			alpha = isHighlighted ? 0.7 : 1.0
		}
	}
	
	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override var intrinsicContentSize: CGSize { .init(width: index % 2 == 0 ? 140 : 220, height: 40) }
}

