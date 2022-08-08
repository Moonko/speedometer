//
//  ViewController.swift
//  Speedometer
//
//  Created by Andrei Rychkov on 08.08.2022.
//

import UIKit

class ViewController: UIViewController {
    private let speedometerView = SpeedometerView(frame: .zero, maxSpeed: 300)

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(speedometerView)

        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            self.speedometerView.startAccelerating()
            self.speedometerView.setSpeed(CGFloat(arc4random_uniform(100)) / 100 * 140)
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(800)) {
                self.speedometerView.endAccelerating()
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        speedometerView.frame.size = CGSize(width: 300, height: 300)
        speedometerView.center = view.center
    }
}

