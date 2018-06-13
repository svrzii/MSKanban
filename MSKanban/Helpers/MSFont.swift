//
//  MSFont.swift
//  MSKanban
//
//  Created by Matej Svrznjak on 13/06/2018.
//  Copyright © 2018 Matej Svrznjak s.p. All rights reserved.
//

import Foundation

@objc class MSFont: NSObject {
    @objc static func fontWithSize(_ size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size)
    }

    @objc static func boldFontWithSize(_ size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: UIFont.Weight.bold)
    }

    @objc static func lightFontWithSize(_ size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: UIFont.Weight.light)
    }

    @objc static func mediumFontWithSize(_ size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: UIFont.Weight.medium)
    }
}
