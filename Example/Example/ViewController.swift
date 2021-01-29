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
		print(picker.currentItemIndex)
	}
	
	/*
	func horizontalPicker(_ picker: MMMHorizontalPicker, update view: UIView, centerProximity: CGFloat) {
		// TODO: Do some fancy things
	}
	*/
	
	func numberOfItemsForHorizontalPicker(_ picker: MMMHorizontalPicker) -> Int {
		return items.count
	}
	
	func horizontalPicker(_ picker: MMMHorizontalPicker, viewForItemWith index: Int) -> UIView {
		return items[index]
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

