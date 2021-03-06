//
//  KanbanViewController.swift
//  MSKanban
//
//  Created by Matej Svrznjak on 13/06/2018.
//  Copyright © 2018 Matej Svrznjak s.p. All rights reserved.
//

import Foundation
import UIKit

public typealias TableViewData = (name: String, tableView: UITableView, values: [String], detailValues: [String], title: String, color: UIColor)

class KanbanViewController: UIViewController {
    lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.backgroundColor = .white
        scroll.showsVerticalScrollIndicator = false
        scroll.showsHorizontalScrollIndicator = false
        scroll.delaysContentTouches = false
        scroll.canCancelContentTouches = false
        scroll.bounces = true
        return scroll
    }()

    private var tableViewData: [TableViewData] = []

    private var standardWidthConstraints: [NSLayoutConstraint] = []
    private var zoomedWidthConstraints: [NSLayoutConstraint] = []
    private var standardVisualConstraint: [NSLayoutConstraint] = []
    private var zoomedVisualConstraint: [NSLayoutConstraint] = []

    private var focus: (tableView: UITableView, indexPath: IndexPath)?
    private var titleElement: String?
    private var detailElement: String?

    private var snapshot: UIView?
    private var offset: CGPoint?
    private var zoomed = false {
        didSet {
            self.scrollView.autoScrollMaxVelocity = self.zoomed ? 10 : 6
            self.scrollView.isPagingEnabled = self.zoomed
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = MSColor.backgroundColor()
        self.view.addSubview(scrollView)

        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[scroll]-0-|", options: [], metrics: nil, views: ["scroll": self.scrollView]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[scroll]-0-|", options: [], metrics: nil, views: ["scroll": self.scrollView]))
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressAction))
        self.scrollView.addGestureRecognizer(longPressGestureRecognizer)

        let doubleTap = UITapGestureRecognizer(target: self, action:#selector(self.doubleTapAction))
        doubleTap.numberOfTapsRequired = 2
        self.scrollView.addGestureRecognizer(doubleTap)

        for index in 1...randomNumber(inRange: 4...12) {
            let table = UITableView(frame: .zero, style: .plain)
            table.tag = index - 1
            table.backgroundColor = .clear
            table.showsVerticalScrollIndicator = false
            table.translatesAutoresizingMaskIntoConstraints = false
            table.separatorStyle = .none
            table.backgroundView?.backgroundColor = .clear
            table.estimatedRowHeight = 140
            table.estimatedSectionFooterHeight = 0
            table.sectionHeaderHeight = 50
            table.sectionFooterHeight = 50
            table.estimatedSectionHeaderHeight = 50
            table.estimatedSectionFooterHeight = 50
            if #available(iOS 11.0, *) {
                table.contentInsetAdjustmentBehavior = .never
            }
            table.dataSource = self
            table.delegate = self
            table.autoScrollMaxVelocity = 8
            table.autoScrollEdgeTollerance = 150
            table.register(UINib(nibName: "KanbanCell", bundle: nil), forCellReuseIdentifier: "KanbanCell")
            table.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "HeaderView")

            self.scrollView.addSubview(table)
            var values: [String] = []
            var detailValues: [String] = []

            for i in 1...randomNumber(inRange: 1...10) {
                values.append("\(index) - \(i)")
                detailValues.append("\(randomNumber(inRange: 350...20000))")
            }
            self.tableViewData.append((name: "table" + "\(index)", tableView: table, values: values, detailValues: detailValues, title: "\(index)", color: MSColor.colors().randomItem() ?? .red))
        }

        var horizontalString = "H:"
        var tableViewsDict: [String: UITableView] = [:]
        for (index, value) in self.tableViewData.enumerated() {
            self.view.addConstraint(NSLayoutConstraint(item: value.tableView, attribute: .centerY, relatedBy: .equal, toItem: self.view, attribute: .centerY, multiplier: 1, constant: 0))
            self.view.addConstraint(NSLayoutConstraint(item: value.tableView, attribute: .height, relatedBy: .equal, toItem: self.view, attribute: .height, multiplier: 0.9, constant: 0))

            let standardWidthConstraints = NSLayoutConstraint(item: value.tableView, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 0.5, constant: 0)
            standardWidthConstraints.priority = UILayoutPriority(rawValue: 2)
            self.view.addConstraint(standardWidthConstraints)
            self.standardWidthConstraints.append(standardWidthConstraints)

            let zoomedWidthConstraints = NSLayoutConstraint(item: value.tableView, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 1, constant: 0)
            zoomedWidthConstraints.priority = UILayoutPriority(rawValue: 1)
            self.view.addConstraint(zoomedWidthConstraints)
            self.zoomedWidthConstraints.append(zoomedWidthConstraints)

            if index == 0 {
                horizontalString += "|-0-[" + value.name + "]"
            } else if index == self.tableViewData.count - 1 {
                horizontalString += "-0-[" + value.name + "]-0-|"
            } else {
                horizontalString += "-0-[" + value.name + "]"
            }

            tableViewsDict[value.name] = value.tableView
        }

        self.zoomedVisualConstraint = NSLayoutConstraint.constraints(withVisualFormat: horizontalString, options: [], metrics: nil, views: tableViewsDict)
        self.standardVisualConstraint = NSLayoutConstraint.constraints(withVisualFormat: horizontalString.replacingOccurrences(of: "-0-", with: "-1-"), options: [], metrics: nil, views: tableViewsDict)

        for constraint in self.standardVisualConstraint {
            constraint.priority = UILayoutPriority(rawValue: 2)
        }

        for constraint in self.zoomedVisualConstraint {
            constraint.priority = UILayoutPriority(rawValue: 1)
        }

        self.view.addConstraints(self.standardVisualConstraint)
        self.view.addConstraints(self.zoomedVisualConstraint)
    }

    @objc func doubleTapAction(gr: UITapGestureRecognizer) {
        self.zoomed = !self.zoomed

        for constraint in self.standardWidthConstraints {
            constraint.priority = self.zoomed ? UILayoutPriority(rawValue: 1) : UILayoutPriority(rawValue: 2)
        }

        for constraint in self.zoomedWidthConstraints {
            constraint.priority = self.zoomed ? UILayoutPriority(rawValue: 2) : UILayoutPriority(rawValue: 1)
        }

        for constraint in self.standardVisualConstraint {
            constraint.priority = self.zoomed ? UILayoutPriority(rawValue: 1) : UILayoutPriority(rawValue: 2)
        }

        for constraint in self.zoomedVisualConstraint {
            constraint.priority = self.zoomed ? UILayoutPriority(rawValue: 2) : UILayoutPriority(rawValue: 1)
        }

        let location = gr.location(in: self.scrollView)
        var table: UITableView? = nil

        if let (tableView, _) = self.convertPointToIndexPath(point: location) {
            table = tableView
        }

        UIView.animate(withDuration: 0.3, animations: {
            self.scrollView.layoutIfNeeded()

            for data in self.tableViewData {
                data.tableView.layoutIfNeeded()
            }

            if let table = table {
                self.scrollView.setContentOffset(CGPoint(x: table.frame.origin.x, y: 0), animated: false)
            }
        })
    }

    @objc func longPressAction(gr: UILongPressGestureRecognizer) {
        func cancelAction() {
            gr.isEnabled = false
            gr.isEnabled = true
        }

        let location = gr.location(in: self.scrollView)
        switch gr.state {
        case .began:
            for table in self.tableViewData {
                table.tableView.autoScrollDragStarted()
            }
            self.scrollView.autoScrollDragStarted()
            guard let (tableView, indexPath) = self.convertPointToIndexPath(point: location) else {
                cancelAction()
                return
            }

            guard let cell = tableView.cellForRow(at: indexPath) as? KanbanCell else {
                cancelAction()
                return
            }

            for (i, value) in self.tableViewData.enumerated().reversed() {
                if tableView !== value.tableView {
                    continue
                }

                self.titleElement = self.tableViewData[i].values[indexPath.row]
                self.detailElement = self.tableViewData[i].detailValues[indexPath.row]

                self.tableViewData[i].values[indexPath.row] = "titleValueTemp"
                self.tableViewData[i].detailValues[indexPath.row] = "detailValueTemp"

                break
            }

            // Make a snapshot of the cell
            self.offset = gr.location(in: cell)

            cell.cellView.backgroundColor = .white

            if let snapshot = cell.cellView.snapshotView(afterScreenUpdates: true) {
                snapshot.frame = scrollView.convert(cell.cellView.frame, from: cell.cellView.superview)
                self.scrollView.addSubview(snapshot)
                snapshot.removeConstraints(snapshot.constraints)
                self.snapshot = snapshot
                self.snapshot?.alpha = 0.7
            }

            self.focus = (tableView, indexPath)

            tableView.reloadRows(at: [indexPath], with: .fade)
            self.configure(tableView: tableView, cell: cell, indexPath: indexPath)
        case .changed:
            guard let focus = self.focus else {
                cancelAction()
                return
            }

            if let offset = self.offset {
                var offsetLocation = location
                offsetLocation.x -= offset.x
                offsetLocation.y -= offset.y
                UIView.animate(withDuration: 0.1) {
                    self.snapshot?.frame.origin = offsetLocation
                }
            }

            self.scrollView.autoScrollDragMoved(location)

            for table in self.tableViewData {
                if focus.tableView !== table.tableView {
                    continue
                }

                let tableLocation = gr.location(in: table.tableView)
                table.tableView.autoScrollDragMoved(tableLocation)
                break
            }

            guard let (tableView, indexPath) = self.convertPointToIndexPath(point: location) else { return }

            if tableView === focus.tableView {
                // Simply move row
                let oldIndexPath = focus.indexPath
                self.focus = (tableView, indexPath)

                tableView.beginUpdates()
                for (i, data) in self.tableViewData.enumerated().reversed() {
                    if data.tableView !== tableView {
                        continue
                    }
                    self.tableViewData[i].values.remove(at: oldIndexPath.row)
                    self.tableViewData[i].detailValues.remove(at: oldIndexPath.row)

                    self.tableViewData[i].values.insert("titleValueTemp", at: indexPath.row)
                    self.tableViewData[i].detailValues.insert("detailValueTemp", at: indexPath.row)
                }
                tableView.moveRow(at: oldIndexPath, to: indexPath)
                tableView.endUpdates()

                if let cell = tableView.cellForRow(at: oldIndexPath) as? KanbanCell {
                    self.configure(tableView: tableView, cell: cell, indexPath: oldIndexPath)
                }

            } else {
                // Remove row in previous table view, add row in current table view
                let (oldTableView, oldIndexPath) = focus
                self.focus = (tableView, indexPath)
                oldTableView.beginUpdates()
                for (i, data) in self.tableViewData.enumerated().reversed() {
                    if data.tableView !== oldTableView {
                        continue
                    }

                    self.tableViewData[i].values.remove(at: oldIndexPath.row)
                    self.tableViewData[i].detailValues.remove(at: oldIndexPath.row)
                }

                oldTableView.deleteRows(at: [oldIndexPath], with: .fade)
                oldTableView.endUpdates()

                if let oldCell = oldTableView.cellForRow(at: oldIndexPath) as? KanbanCell {
                    self.configure(tableView: oldTableView, cell: oldCell, indexPath: oldIndexPath)
                }

                tableView.beginUpdates()
                for (i, data) in self.tableViewData.enumerated().reversed() {
                    if data.tableView !== tableView {
                        continue
                    }

                    self.tableViewData[i].values.insert("titleValueTemp", at: indexPath.row)
                    self.tableViewData[i].detailValues.insert("detailValueTemp", at: indexPath.row)
                }

                tableView.insertRows(at: [indexPath], with: .fade)
                tableView.endUpdates()

                if let oldCell = oldTableView.cellForRow(at: oldIndexPath) as? KanbanCell {
                    self.configure(tableView: oldTableView, cell: oldCell, indexPath: oldIndexPath)
                }
            }
        case .ended, .failed, .cancelled:
            self.scrollView.autoScrollDragEnded()

            for table in self.tableViewData {
                table.tableView.autoScrollDragEnded()
            }
            guard let _ = self.focus else {
                return
            }

            if let (tableView, indexPath) = self.convertPointToIndexPath(point: location) ?? self.focus {
                self.focus = nil
                for (i, value) in self.tableViewData.enumerated() {
                    if tableView !== value.tableView {
                        continue
                    }

                    if let titleElement = self.titleElement, let detailElement = self.detailElement {
                        self.tableViewData[i].values[indexPath.row] = titleElement
                        self.tableViewData[i].detailValues[indexPath.row] = detailElement
                    }
                    break
                }

                self.titleElement = nil
                self.detailElement = nil

                guard let snapshot = self.snapshot else {
                    return
                }

                let frame: CGRect
                if let cell = tableView.cellForRow(at: indexPath) as? KanbanCell {
                    frame = self.scrollView.convert(cell.cellView.frame, from: cell.cellView.superview)
                } else if let lastVisibleCell = tableView.visibleCells.last as? KanbanCell {
                    frame = self.scrollView.convert(lastVisibleCell.frame, from: lastVisibleCell.cellView.superview)
                } else {
                    frame = tableView.frame
                }

                UIView.transition(with: snapshot, duration: 0.2, options: .curveEaseOut, animations: {
                    snapshot.frame.origin = frame.origin
                    snapshot.alpha = 1
                }) { (finished) in
                    tableView.reloadRows(at: [indexPath], with: .none)

                    UIView.animate(withDuration: 0.2, animations: {
                        snapshot.alpha = 0
                    }) { (finished) in
                        snapshot.removeFromSuperview()
                        self.snapshot = nil
                        if let cell = tableView.cellForRow(at: indexPath) as? KanbanCell {
                            cell.cellView.backgroundColor = .white
                            self.configure(tableView: tableView, cell: cell, indexPath: indexPath)
                        }
                    }
                }
            }
        default:
            break
        }
    }

    func convertPointToIndexPath(point: CGPoint) -> (UITableView, IndexPath)? {
        if let tableView = self.tableViewData.filter({ $0.tableView.frame.contains(point) }).first?.tableView {
            let localPoint = self.scrollView.convert(point, to: tableView)
            let lastRowIndex = self.focus?.tableView === tableView ? tableView.numberOfRows(inSection: 0) - 1 : tableView.numberOfRows(inSection: 0)
            let indexPath = tableView.indexPathForRow(at: localPoint) ?? IndexPath(row: lastRowIndex, section: 0)
            return (tableView, indexPath)
        }

        return nil
    }
}

extension KanbanViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let cell = tableView.cellForRow(at: indexPath) as? KanbanCell {
            cell.cellView.backgroundColor = .white
        }
    }

    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? KanbanCell {
            UIView.animate(withDuration: 0.15, animations: {
                cell.cellView.backgroundColor = UIColor(white: 0, alpha: 0.035)
            })
        }
    }

    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? KanbanCell {
            UIView.animate(withDuration: 0.15, animations: {
                cell.cellView.backgroundColor = .white
            })
        }
    }
}

extension KanbanViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        for data in self.tableViewData {
            if data.tableView !== tableView {
                continue
            }

            return data.values.count
        }

        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "KanbanCell", for: indexPath) as! KanbanCell
        self.configure(tableView: tableView, cell: cell, indexPath: indexPath)

        return cell
    }

    private func configure(tableView: UITableView, cell: KanbanCell, indexPath: IndexPath, tempCell: Bool = false) {
        for data in self.tableViewData {
            if data.tableView !== tableView {
                continue
            }

            if !data.values.indices.contains(indexPath.row) || !data.detailValues.indices.contains(indexPath.row) {
                continue
            }

            if data.values[indexPath.row] == "titleValueTemp" && data.detailValues[indexPath.row] == "detailValueTemp" {
                cell.cellView.alpha = 0.2
                cell.cellView.backgroundColor = MSColor.defaultColor()
                cell.titleLabel.text = self.titleElement
                cell.titleLabel.backgroundColor = .black
                cell.subtitleLabel.text = (self.detailElement ?? "") + " $"
                cell.subtitleLabel.backgroundColor = .black
                cell.colorView.backgroundColor = .black
                cell.cellView.layer.borderColor = UIColor.black.cgColor
                cell.cellView.layer.borderWidth = 0.5
                cell.avatarImageView.image = UIImage().avatarImageWithame(fullName: "", size: CGSize(width: 35, height: 35), backgroundColor: .black, fontColor: .white, font: UIFont.systemFont(ofSize: 16))
                break
            }

            cell.cellView.alpha = 1.0
            cell.cellView.layer.borderColor = MSColor.cellBorderColor().cgColor
            cell.cellView.layer.borderWidth = 0.5
            cell.titleLabel.backgroundColor = .clear
            cell.subtitleLabel.backgroundColor = .clear

            cell.titleLabel.text = data.values[indexPath.row]
            cell.avatarImageView.image = UIImage().avatarImageWithame(fullName: data.values[indexPath.row], size: CGSize(width: 35, height: 35), fontColor: .white, font: MSFont.mediumFontWithSize(15))

            cell.subtitleLabel.text = data.detailValues[indexPath.row] + " $"

            cell.colorView.backgroundColor = data.color
        }

        cell.topConstraint.constant = indexPath.row == 0 ? 5 : 0
        cell.cellView.backgroundColor = .white
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        for data in self.tableViewData {
            if data.tableView !== tableView {
                continue
            }

            return data.title + " TITLE"
        }

        return ""
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        for data in self.tableViewData {
            if data.tableView !== tableView {
                continue
            }

            return data.title + " SUBTITLE"
        }

        return ""
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "HeaderView") {
            headerView.textLabel?.textColor = UIColor.black
            headerView.textLabel?.font = MSFont.lightFontWithSize(15)
            headerView.textLabel?.backgroundColor = .clear
            headerView.contentView.backgroundColor = MSColor.headerColor()
            headerView.addBorders(edges: [.bottom], color: .white, thickness: 1)
            return headerView
        }

        return nil
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "HeaderView") {
            headerView.textLabel?.textColor = UIColor.black
            headerView.textLabel?.font = MSFont.lightFontWithSize(15)
            headerView.textLabel?.backgroundColor = .clear
            headerView.contentView.backgroundColor = MSColor.headerColor()
            headerView.addBorders(edges: [.top], color: .white, thickness: 1)

            return headerView
        }

        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 50
    }
}
