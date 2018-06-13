//
//  MSColor.swift
//  MSKanban
//
//  Created by Matej Svrznjak on 13/06/2018.
//  Copyright © 2018 Matej Svrznjak s.p. All rights reserved.
//

import Foundation
import UIKit

@objc class MSColor: NSObject {
    @objc static func defaultColor() -> UIColor {
        return UIColor(hex: 0xF7F7F7)
    }

    @objc static func backgroundColor() -> UIColor {
        return UIColor(hex: 0xeaeaea)
    }

    @objc static func headerColor() -> UIColor {
        return UIColor(hex: 0xF7F7F7)
    }

    @objc static func cellBorderColor() -> UIColor {
        return UIColor(hex: 0xdedede)
    }

    @objc static func avatarColor() -> UIColor {
        return UIColor(hex: 0x00A9E7)
    }

    @objc static func colors() -> [UIColor] {
        return [
            UIColor(hex: 0xF44336),
            UIColor(hex: 0xE91E63),
            UIColor(hex: 0x9C27B0),
            UIColor(hex: 0x673AB7),
            UIColor(hex: 0x3F51B5),
            UIColor(hex: 0x2196F3),
            UIColor(hex: 0x03A9F4),
            UIColor(hex: 0x00BCD4),
            UIColor(hex: 0x009688),
            UIColor(hex: 0x4CAF50),
            UIColor(hex: 0x8BC34A),
            UIColor(hex: 0xCDDC39),
            UIColor(hex: 0xFDD835),
            UIColor(hex: 0xFFC107),
            UIColor(hex: 0xFF9800),
            UIColor(hex: 0xFF5722),
            UIColor(hex: 0x795548),
            UIColor(hex: 0x607D8B)
        ]
    }
    
}
