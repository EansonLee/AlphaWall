//
//  PremiumSubscriptionIcon.swift
//  HeartWall
//

import UIKit

enum PremiumSubscriptionIcon {

    static func image(size: CGSize = CGSize(width: 28, height: 28)) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = false

        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            let bounds = CGRect(origin: .zero, size: size)
            let scale = min(bounds.width, bounds.height) / 28
            let cgContext = context.cgContext

            cgContext.setFillColor(UIColor.black.cgColor)
            cgContext.setStrokeColor(UIColor.black.cgColor)
            cgContext.setLineCap(.round)
            cgContext.setLineJoin(.round)

            func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(
                    x: bounds.midX + (x - 14) * scale,
                    y: bounds.midY + (y - 14) * scale
                )
            }

            let diamond = UIBezierPath()
            diamond.move(to: point(14, 4.3))
            diamond.addLine(to: point(24.3, 12.2))
            diamond.addLine(to: point(14, 25.3))
            diamond.addLine(to: point(3.7, 12.2))
            diamond.close()
            diamond.fill()

            cgContext.setBlendMode(.clear)

            let topFacet = UIBezierPath()
            topFacet.move(to: point(8.3, 12.0))
            topFacet.addLine(to: point(11.0, 7.8))
            topFacet.addLine(to: point(17.0, 7.8))
            topFacet.addLine(to: point(19.7, 12.0))
            topFacet.addLine(to: point(14, 19.3))
            topFacet.close()
            topFacet.fill()

            let leftFacet = UIBezierPath()
            leftFacet.move(to: point(5.8, 12.0))
            leftFacet.addLine(to: point(10.0, 12.0))
            leftFacet.addLine(to: point(13.0, 21.2))
            leftFacet.close()
            leftFacet.fill()

            let rightFacet = UIBezierPath()
            rightFacet.move(to: point(22.2, 12.0))
            rightFacet.addLine(to: point(18.0, 12.0))
            rightFacet.addLine(to: point(15.0, 21.2))
            rightFacet.close()
            rightFacet.fill()

            cgContext.setBlendMode(.normal)
            cgContext.setLineWidth(1.55 * scale)

            let topSpark = UIBezierPath()
            topSpark.move(to: point(22.7, 2.9))
            topSpark.addLine(to: point(22.7, 7.1))
            topSpark.move(to: point(20.6, 5.0))
            topSpark.addLine(to: point(24.8, 5.0))
            topSpark.stroke()

            cgContext.setLineWidth(1.35 * scale)

            let lowerSpark = UIBezierPath()
            lowerSpark.move(to: point(4.7, 20.0))
            lowerSpark.addLine(to: point(4.7, 22.9))
            lowerSpark.move(to: point(3.25, 21.45))
            lowerSpark.addLine(to: point(6.15, 21.45))
            lowerSpark.stroke()
        }

        return image.withRenderingMode(.alwaysTemplate)
    }
}
