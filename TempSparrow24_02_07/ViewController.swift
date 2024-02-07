//
//  ViewController.swift
//  TempSparrow24_02_07
//
//  Created by Egor Ledkov on 07.02.2024.
//

#if DEBUG
import SwiftUI
#endif

import UIKit

class ViewController: UIViewController {
	
	private lazy var squareView: UIView = makeSquareView()
	private lazy var slider: UISlider = makeSlider()
	private lazy var button: UIButton = {
		let button = UIButton(frame: CGRect(x: 200, y: 300, width: 100, height: 50))
		
		button.backgroundColor = .green
		
		return button
	}()
	
	private lazy var animator: MonitorableUIViewPropertyAnimator = {
		return MonitorableUIViewPropertyAnimator(duration: 1, curve: .linear)
	}()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setup()
	}
	
	private func setup() {
		view.backgroundColor = .white
		
		button.setTitle("Reset", for: .normal)
		button.addTarget(self, action: #selector(restart), for: .touchUpInside)
		
		slider.addTarget(self, action: #selector(didChangeSlider), for: .valueChanged)
		
		slider.addTarget(self, action: #selector(touchDownSlider), for: .touchDown)
		
		slider.addTarget(self, action: #selector(touchCancelSlider), for: .touchUpInside)
		
		view.addSubview(squareView)
		view.addSubview(slider)
		view.addSubview(button)
		
		setupAnimator()
	}
	
	@objc private func restart() {
		print("restart \(animator.state)")
		
		squareView.transform = CGAffineTransform.identity
		squareView.frame = CGRect(x: 10, y: 120, width: 100, height: 100)
		slider.value = 0
		
		animator.stopAnimation(true)
		
		setupAnimator()
	}
	
	@objc private func touchCancelSlider() {
		print("Cancel", animator.fractionComplete)
		animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
	}
	
	@objc private func touchDownSlider() {
		if animator.isRunning {
			animator.pauseAnimation()
			print("Down pause", animator.fractionComplete)
		} else {
			if slider.value == slider.maximumValue {
//				restart()
			} else {
				animator.startAnimation()
			}
			print("Down start", animator.fractionComplete)
		}
	}
	
	@objc private func didChangeSlider() {
		animator.pauseAnimation()
		animator.fractionComplete = CGFloat(slider.value)
	}
	
	private func setupAnimator() {
		animator.addAnimations {
			var transform = CGAffineTransform.identity
			transform = transform.rotated(by: .pi / 2)
			
			self.squareView.transform = transform
			
			let x = UIScreen.main.bounds.width - 160
			self.squareView.frame = CGRect(x: x, y: 95, width: 150, height: 150)
		}
		
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


// MARK: - PreviewProvider

#if DEBUG
struct MainViewControllerProvider: PreviewProvider {
	static var previews: some View {
		ViewController()
			.preview()
	}
}

extension UIViewController {
	struct Preview: UIViewControllerRepresentable {
		let viewController: UIViewController
		
		func makeUIViewController(context: Context) -> some UIViewController {
			viewController
		}
		
		func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) { }
	}
	
	func preview( ) -> some View {
		Preview(viewController: self)
	}
}
#endif
