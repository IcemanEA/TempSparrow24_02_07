//
//  ViewController.swift
//  TempSparrow24_02_07
//
//  Created by Egor Ledkov on 07.02.2024.
//

import UIKit

class ViewController: UIViewController {
	
	private lazy var squareView: UIView = makeSquareView()
	private lazy var slider: UISlider = makeSlider()
	
	private lazy var animator: MonitorableUIViewPropertyAnimator = {
		return MonitorableUIViewPropertyAnimator(duration: 1, curve: .linear)
	}()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setup()
	}
	
	private func setup() {
		view.backgroundColor = .white
		
		slider.addTarget(self, action: #selector(didChangeSlider), for: .valueChanged)
		slider.addTarget(self, action: #selector(touchCancelSlider), for: .touchUpInside)
		
		view.addSubview(squareView)
		view.addSubview(slider)
		
		setupAnimator()
	}
	
	@objc private func touchCancelSlider() {
		animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
	}
	
	@objc private func didChangeSlider(_ sender: UISlider) {
		animator.fractionComplete = CGFloat(slider.value)
	}
	
	private func setupAnimator() {
		animator.pausesOnCompletion = true
		
		animator.addAnimations {
			// Можно сразу присвоить, оставил тут для запоминания навешивания одной на другую
			var transform = CGAffineTransform.identity
			transform = transform.rotated(by: .pi / 2)
			
			self.squareView.transform = transform
			
			let x = UIScreen.main.bounds.width - 160
			self.squareView.frame = CGRect(x: x, y: 95, width: 150, height: 150)
		}
		
		// Тут не нужно, оставил для себя на будущее - полезно!
		animator.addCompletion { position in
			switch position {
			case .end:
				print("end", self.animator.fractionComplete)
			case .start:
				print("start", self.animator.fractionComplete)
			case .current:
				print("current", self.animator.fractionComplete)
			default:
				break
			}
		}
		
		animator.resetAnimation()
		animator.onFractionCompleteUpdated = { fractionComplete in
			self.slider.value = Float(fractionComplete)
		}
	}
}

// MARK: - Constructors

private extension ViewController {
	
	func makeSquareView() -> UIView {
		let uiView = UIView(frame: CGRect(x: 10, y: 120, width: 100, height: 100))
		
		uiView.layer.cornerRadius = 10
		uiView.layer.backgroundColor = UIColor.tintColor.cgColor
		
		return uiView
	}
	
	func makeSlider() -> UISlider {
		let uiSlider = UISlider(frame: CGRect(x: 10, y: 230, width: view.frame.width-20, height: 100))
		
		return uiSlider
	}
}

// MARK: - MonitorableUIViewPropertyAnimator

final class MonitorableUIViewPropertyAnimator : UIViewPropertyAnimator {
	
	private var displayLink: CADisplayLink?
	private var lastFractionComplete: CGFloat?
	
	var onFractionCompleteUpdated: ((CGFloat) -> ())? = nil {
		didSet {
			if onFractionCompleteUpdated != nil {
				if displayLink == nil {
					displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink(_:)))
					displayLink?.add(to: .main, forMode: .common)
					
					// Clean up when the animation completes
					addCompletion { [weak self] _ in
						self?.displayLink?.invalidate()
					}
				}
			} else {
				displayLink?.invalidate()
			}
		}
	}
	
	func resetAnimation() {
		displayLink = nil
		lastFractionComplete = nil
	}
	
	@objc private func handleDisplayLink(_ displayLink: CADisplayLink) {
		if lastFractionComplete != fractionComplete {
			onFractionCompleteUpdated?(fractionComplete)
			lastFractionComplete = fractionComplete
		}
		
		if state == .stopped {
			displayLink.invalidate()
		}
	}
}
