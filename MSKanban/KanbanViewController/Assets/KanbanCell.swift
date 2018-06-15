//
//  KanbanCell.swift
//  Trelloesque
//
//  Created by Matej Svrznjak on 11/06/2018.
//  Copyright © 2018 Monetor. All rights reserved.
//


import Foundation
import UIKit

class KanbanCell: UITableViewCell {
    @IBOutlet var colorView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var avatarImageView: UIImageView!
    @IBOutlet var cellView: UIView!
    @IBOutlet var topConstraint: NSLayoutConstraint!
    override func awakeFromNib() {
        self.backgroundColor = .white
        self.contentView.backgroundColor = MSColor.defaultColor()
        self.colorView.clipsToBounds = true
        self.avatarImageView.layer.cornerRadius = 20
        self.avatarImageView.clipsToBounds = true
        self.cellView.backgroundColor = .white
        self.cellView.clipsToBounds = true
        self.cellView.layer.cornerRadius = 3
    }
}

