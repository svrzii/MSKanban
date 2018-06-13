//
//  extensions.swift
//  Trelloesque
//
//  Created by Matej Svrznjak on 11/06/2018.
//  Copyright © 2018 Monetor. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    convenience init(hex: Int) {
        self.init(
            red: CGFloat((hex & 0xFF0000) >> 16)/255.0,
            green: CGFloat((hex & 0x00FF00) >> 8)/255.0,
            blue: CGFloat(hex & 0x0000FF)/255.0,
            alpha: CGFloat(1.0))
    }
}
extension UIImage {
    func initialsForName(_ name: String) -> String {
        var finalChars: String = ""
        guard name.indices.contains(name.startIndex) else {
            return "/"
        }
        let arrayStrings = name.components(separatedBy: " ")
        for string in arrayStrings {
            if string.count > 0 && finalChars.count < 2 {
                if string[string.startIndex] != " " {
                    finalChars += "\(string[string.startIndex])"
                }
            }
        }

        return finalChars.uppercased()
    }

    func avatarImageWithame(fullName: String, size: CGSize = CGSize(width: 75, height: 75), fontColor: UIColor, font: UIFont) -> UIImage? {
        let backgroundColor = MSColor.cellBorderColor()

        let imageRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(imageRect.size, false, 0)
        backgroundColor.setFill()
        UIRectFill(imageRect)

        let name = fullName.replacingOccurrences(of: "-", with: " ").replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: ".", with: "").replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: ",", with: "").replacingOccurrences(of: ";", with: "")

        let letters = self.initialsForName(name)
        let letterSize = letters.size(withAttributes: [NSAttributedStringKey.font: font])

        let rect: CGRect
        if letters.count > 1 {
            rect = CGRect(x: size.width * 0.5 - letterSize.width * 0.5, y: size.height * 0.5 - letterSize.height * 0.5, width: letterSize.width, height: letterSize.height)
        } else {
            rect = CGRect(x: size.width * 0.5 - letterSize.width * 0.48, y: size.height * 0.5 - letterSize.height * 0.5, width: letterSize.width, height: letterSize.height)
        }
        letters.draw(in: rect, withAttributes: [NSAttributedStringKey.font: font, NSAttributedStringKey.foregroundColor: fontColor])


        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

extension Array {
    func randomItem() -> Element? {
        if isEmpty { return nil }
        let index = Int(arc4random_uniform(UInt32(self.count)))
        let element = self[index]
        return element
    }
}

extension UIView {
    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }

}

public func randomNumber<T : SignedInteger>(inRange range: ClosedRange<T> = 1...6) -> T {
    let length = Int64(range.upperBound - range.lowerBound + 1)
    let value = Int64(arc4random()) % length + Int64(range.lowerBound)
    return T(value)
}
