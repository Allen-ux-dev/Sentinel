#if os(macOS)
import SwiftUI
import SentinelCore

struct EyeView: View {
    @ObservedObject var model: EyeViewModel
    var trackingEnabled: Bool = true
    var intensity: AnimationIntensity = .standard

    private let gold = Color(red: 1.0, green: 0.78, blue: 0.18)
    private let softGold = Color(red: 1.0, green: 0.88, blue: 0.46)

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            GeometryReader { proxy in
                let side = min(proxy.size.width, proxy.size.height)
                let t = timeline.date.timeIntervalSinceReferenceDate
                let amplitude: CGFloat = intensity == .quiet ? 0.006 : (intensity == .lively ? 0.018 : 0.011)
                let breathing = 1 + CGFloat(sin(t * .pi * 2 / 3.65)) * amplitude
                let pupilPulsePhase = sin(t * .pi * 2 / 4.8)

                Canvas { context, size in
                    drawEye(context: &context, size: size, pupilPulsePhase: pupilPulsePhase)
                }
                .scaleEffect(breathing)
                .frame(width: side, height: side)
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }
        }
        .accessibilityHidden(true)
    }

    private func drawEye(context: inout GraphicsContext, size: CGSize, pupilPulsePhase: Double) {
        let side = min(size.width, size.height)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let ringRect = CGRect(
            x: center.x - side * 0.43,
            y: center.y - side * 0.43,
            width: side * 0.86,
            height: side * 0.86
        )

        context.stroke(
            Path(ellipseIn: ringRect),
            with: .color(gold.opacity(model.state == .alertHigh ? 1 : 0.90)),
            lineWidth: max(2, side * 0.014)
        )

        if model.rippleOpacity > 0 {
            let expansion = side * 0.075 * model.ripplePhase
            let ripple = ringRect.insetBy(dx: -expansion, dy: -expansion)
            context.stroke(
                Path(ellipseIn: ripple),
                with: .color(softGold.opacity(Double(model.rippleOpacity))),
                lineWidth: max(1, side * 0.008)
            )
        }

        let eyeWidth = side * 0.70 * model.innerScale
        let eyeHeight = side * 0.25 * model.innerScale
        let left = center.x - eyeWidth / 2
        let right = center.x + eyeWidth / 2
        let midY = center.y
        let openFactor = max(0.02, 1 - model.eyelidClosure)
        let arch = eyeHeight * 0.72 * openFactor

        var upper = Path()
        upper.move(to: CGPoint(x: left, y: midY))
        upper.addCurve(
            to: CGPoint(x: right, y: midY),
            control1: CGPoint(x: left + eyeWidth * 0.24, y: midY - arch),
            control2: CGPoint(x: right - eyeWidth * 0.24, y: midY - arch)
        )

        var lower = Path()
        lower.move(to: CGPoint(x: left, y: midY))
        lower.addCurve(
            to: CGPoint(x: right, y: midY),
            control1: CGPoint(x: left + eyeWidth * 0.24, y: midY + arch),
            control2: CGPoint(x: right - eyeWidth * 0.24, y: midY + arch)
        )

        var eyeClip = Path()
        eyeClip.move(to: CGPoint(x: left, y: midY))
        eyeClip.addCurve(
            to: CGPoint(x: right, y: midY),
            control1: CGPoint(x: left + eyeWidth * 0.24, y: midY - arch),
            control2: CGPoint(x: right - eyeWidth * 0.24, y: midY - arch)
        )
        eyeClip.addCurve(
            to: CGPoint(x: left, y: midY),
            control1: CGPoint(x: right - eyeWidth * 0.24, y: midY + arch),
            control2: CGPoint(x: left + eyeWidth * 0.24, y: midY + arch)
        )
        eyeClip.closeSubpath()

        if model.eyelidClosure < 0.98 {
            let cursor = trackingEnabled ? model.mouseTracker.normalizedOffset : .zero
            let normalizedX = Double(cursor.width * 0.55 + model.gazeBias.width)
            let normalizedY = Double(cursor.height * 0.50 + model.gazeBias.height)
            let offset = EyeMotionPolicy.offset(
                normalizedX: normalizedX,
                normalizedY: normalizedY,
                side: Double(side),
                eyelidClosure: Double(model.eyelidClosure)
            )
            let irisCenter = CGPoint(x: center.x + CGFloat(offset.x), y: center.y + CGFloat(offset.y))
            let irisRadius = side * 0.095 * model.innerScale

            var innerContext = context
            innerContext.clip(to: eyeClip)

            for i in 0..<36 {
                let angle = CGFloat(i) / 36 * .pi * 2
                let inner = irisRadius * 0.44
                let outer = irisRadius * (0.82 + CGFloat(i % 4) * 0.025)
                var ray = Path()
                ray.move(to: CGPoint(x: irisCenter.x + cos(angle) * inner, y: irisCenter.y + sin(angle) * inner))
                ray.addLine(to: CGPoint(x: irisCenter.x + cos(angle) * outer, y: irisCenter.y + sin(angle) * outer))
                innerContext.stroke(ray, with: .color(softGold.opacity(0.62)), lineWidth: max(0.7, side * 0.0032))
            }

            innerContext.stroke(
                Path(ellipseIn: CGRect(x: irisCenter.x - irisRadius, y: irisCenter.y - irisRadius, width: irisRadius * 2, height: irisRadius * 2)),
                with: .color(gold.opacity(0.92)),
                lineWidth: max(1.3, side * 0.007)
            )

            let pulsedPupilScale = CGFloat(EyeMotionPolicy.pupilPulseScale(
                baseScale: Double(model.pupilScale),
                phase: pupilPulsePhase
            ))
            let pupilRadius = irisRadius * 0.39 * pulsedPupilScale
            let pupilRect = CGRect(x: irisCenter.x - pupilRadius, y: irisCenter.y - pupilRadius, width: pupilRadius * 2, height: pupilRadius * 2)
            innerContext.fill(Path(ellipseIn: pupilRect), with: .color(.black.opacity(0.92)))

            let highlight = CGRect(
                x: irisCenter.x - pupilRadius * 0.32,
                y: irisCenter.y - pupilRadius * 0.48,
                width: max(2, pupilRadius * 0.28),
                height: max(2, pupilRadius * 0.28)
            )
            innerContext.fill(Path(ellipseIn: highlight), with: .color(.white.opacity(0.70)))
        }

        let line = max(2, side * 0.014)
        context.stroke(upper, with: .color(gold), style: StrokeStyle(lineWidth: line, lineCap: .round))
        context.stroke(lower, with: .color(gold), style: StrokeStyle(lineWidth: line, lineCap: .round))
    }
}
#endif
