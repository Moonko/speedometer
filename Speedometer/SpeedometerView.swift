import UIKit

typealias Speed = CGFloat

final class SpeedometerView: UIView {
    private let centerPointLayer: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = UIColor.gray.cgColor
        return layer
    }()

    private let arrowLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.orange.cgColor
        layer.anchorPoint = CGPoint(x: 0.2, y: 0.5)
        layer.lineJoin = .round
        return layer
    }()

    private let marksLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor.white.cgColor
        layer.lineWidth = 3
        return layer
    }()

    private let minorMarksLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor.white.cgColor
        layer.lineCap = .round
        layer.lineWidth = 2
        return layer
    }()

    private let minAngle = 135 * CGFloat.pi / 180
    private let maxAngle = 405 * CGFloat.pi / 180

    private let maxSpeed: Speed

    private let speedLabels: [Speed: UILabel]

    private var displayLink: CADisplayLink?

    private var isAccelerating: Bool = false {
        didSet { acceleration = 0 }
    }
    private var acceleration: Speed = 0
    private var speed: Speed = 0

    init(
        frame: CGRect,
        maxSpeed: Speed
    ) {
        self.maxSpeed = maxSpeed
        var speedLabels = [Speed: UILabel]()
        stride(from: 0, to: Int(maxSpeed) + 1, by: 20).forEach { speed in
            let label = UILabel()
            label.textColor = .white
            label.text = "\(speed)"
            label.font = .systemFont(ofSize: 16, weight: .bold)
            speedLabels[Speed(speed)] = label
        }
        self.speedLabels = speedLabels

        super.init(frame: frame)

        layer.backgroundColor = UIColor.black.cgColor
        layer.masksToBounds = true

        layer.addSublayer(marksLayer)
        layer.addSublayer(minorMarksLayer)
        speedLabels.values.forEach { addSubview($0) }
        layer.addSublayer(arrowLayer)
        layer.addSublayer(centerPointLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: API

    func setSpeed(_ newSpeed: Speed) {
        speed = newSpeed
        let angle = angle(forSpeed: speed)
        arrowLayer.transform = CATransform3DMakeRotation(angle, 0, 0, 1)
    }

    func startAccelerating() {
        isAccelerating = true
    }

    func endAccelerating() {
        isAccelerating = false
    }

    // MARK: Overrides

    override func didMoveToWindow() {
        super.didMoveToWindow()

        guard window != nil else {
            displayLink?.invalidate()
            displayLink = nil
            return
        }

        displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayUpdate))
        displayLink?.add(to: .current, forMode: .common)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = bounds.width / 2

        arrowLayer.bounds.size = CGSize(
            width: bounds.width * 0.50,
            height: bounds.width * 0.03
        )
        arrowLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)

        let path = UIBezierPath()
        path.move(to: CGPoint(x: arrowLayer.bounds.width, y: arrowLayer.bounds.height * 0.3))
        path.addLine(to: CGPoint(x: arrowLayer.bounds.width, y: arrowLayer.bounds.height * 0.7))
        path.addLine(to: CGPoint(x: 0.0, y: arrowLayer.bounds.height))
        path.addLine(to: CGPoint(x: 0.0, y: 0.0))
        path.close()
        arrowLayer.path = path.cgPath

        centerPointLayer.frame.size = CGSize(
            width: bounds.width * 0.1,
            height: bounds.width * 0.1
        )
        centerPointLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        centerPointLayer.cornerRadius = centerPointLayer.bounds.width / 2

        marksLayer.bounds.size = bounds.size
        marksLayer.position =  CGPoint(x: bounds.midX, y: bounds.midY)
        let marksLayerPath = UIBezierPath()
        stride(from: 0, to: Int(maxSpeed) + 1, by: 20).forEach { speed in
            let angle = angle(forSpeed: Speed(speed))
            let radius = marksLayer.bounds.width / 2
            marksLayerPath.move(
                to: CGPoint(
                    x: radius + radius * cos(angle),
                    y: radius + radius * sin(angle)
                )
            )
            marksLayerPath.addLine(
                to: CGPoint(
                    x: radius + radius * 0.88 * cos(angle),
                    y: radius + radius * 0.88 * sin(angle)
                )
            )
        }
        marksLayer.path = marksLayerPath.cgPath

        minorMarksLayer.bounds.size = bounds.size
        minorMarksLayer.position =  CGPoint(x: bounds.midX, y: bounds.midY)
        let minorMarksLayerPath = UIBezierPath()
        stride(from: 0, to: Int(maxSpeed) + 1, by: 5).forEach { speed in
            let angle = angle(forSpeed: Speed(speed))
            let radius = minorMarksLayer.bounds.width / 2
            minorMarksLayerPath.move(
                to: CGPoint(
                    x: radius + radius * cos(angle),
                    y: radius + radius * sin(angle)
                )
            )
            minorMarksLayerPath.addLine(
                to: CGPoint(
                    x: radius + radius * 0.96 * cos(angle),
                    y: radius + radius * 0.96 * sin(angle)
                )
            )
        }
        minorMarksLayer.path = minorMarksLayerPath.cgPath

        speedLabels.forEach { speed, label in
            label.sizeToFit()
            let angle = angle(forSpeed: speed)
            let radius = bounds.width / 2
            label.center = CGPoint(
                x: radius + radius * 0.76 * cos(angle),
                y: radius + radius * 0.76 * sin(angle)
            )
        }
    }

    // MARK: Helpers

    @objc
    private func handleDisplayUpdate() {
        if isAccelerating {
            acceleration *= 0.05
        } else {
            acceleration -= 0.5
        }
        setSpeed(speed + acceleration)
    }

    private func angle(forSpeed speed: Speed) -> CGFloat {
        let speedRatio = speed > 0 ? speed / maxSpeed : 0
        return minAngle + (maxAngle - minAngle) * speedRatio
    }
}
