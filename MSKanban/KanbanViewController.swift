//
//  KanbanViewController.swift
//  MSKanban
//
//  Created by Matej Svrznjak on 13/06/2018.
//  Copyright © 2018 Matej Svrznjak s.p. All rights reserved.
//

import Foundation
import UIKit

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

    private var tableViewData: [(name: String, tableView: UITableView, values: [String], title: String, color: UIColor)] = []

    private var focus: (UITableView, IndexPath)?
    private var element: String?
    private var snapshot: UIView?
    private var offset: CGPoint?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = MSColor.backgroundColor()
        self.view.addSubview(scrollView)

        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[scroll]-0-|", options: [], metrics: nil, views: ["scroll": self.scrollView]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[scroll]-0-|", options: [], metrics: nil, views: ["scroll": self.scrollView]))
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressAction))
        self.scrollView.addGestureRecognizer(longPressGestureRecognizer)

        for index in 1...randomNumber(inRange: 4...12) {
            let table = UITableView(frame: .zero, style: .plain)
            table.tag = index - 1
            table.backgroundColor = .clear
            table.layer.cornerRadius = 3
            table.showsVerticalScrollIndicator = false
            table.translatesAutoresizingMaskIntoConstraints = false
            table.separatorStyle = .none
            table.backgroundView?.backgroundColor = .clear
            table.dataSource = self
            table.delegate = self
            table.register(UINib(nibName: "KanbanCell", bundle: nil), forCellReuseIdentifier: "KanbanCell")
            table.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "HeaderView")

            self.scrollView.addSubview(table)
            var values: [String] = []

            for i in 1...randomNumber(inRange: 1...10) {
                values.append("\(index) - \(i)")
            }
            self.tableViewData.append((name: "table" + "\(index)", tableView: table, values: values, title: "\(index)", color: MSColor.colors().randomItem() ?? .red))
        }

        var horizontalString = "H:"
        var tableViewsDict: [String: UITableView] = [:]
        for (index, value) in self.tableViewData.enumerated() {
            self.view.addConstraint(NSLayoutConstraint(item: value.tableView, attribute: .centerY, relatedBy: .equal, toItem: self.view, attribute: .centerY, multiplier: 1, constant: 0))
            self.view.addConstraint(NSLayoutConstraint(item: value.tableView, attribute: .height, relatedBy: .equal, toItem: self.view, attribute: .height, multiplier: 0.9, constant: 0))
            self.view.addConstraint(NSLayoutConstraint(item: value.tableView, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 0.5, constant: 0))


            if index == 0 {
                horizontalString += "|-10-[" + value.name + "]"
            } else if index == self.tableViewData.count - 1 {
                horizontalString += "-5-[" + value.name + "]-10-|"
            } else {
                horizontalString += "-5-[" + value.name + "]"
            }

            tableViewsDict[value.name] = value.tableView
        }

        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: horizontalString, options: [], metrics: nil, views: tableViewsDict))
    }

    @objc func longPressAction(gr: UILongPressGestureRecognizer) {
        func cancelAction() {
            gr.isEnabled = false
            gr.isEnabled = true
        }

        let location = gr.location(in: scrollView)
        switch gr.state {
        case .began:
            scrollView.autoScrollDragStarted()
            guard let (tableView, indexPath) = convertPointToIndexPath(point: location) else { cancelAction(); return }
            guard tableView.cellForRow(at: indexPath) != nil else { cancelAction(); return }

            for (i, value) in self.tableViewData.enumerated().reversed() {
                if tableView === value.tableView {
                    self.element = self.tableViewData[i].values.remove(at: indexPath.row)
                    break
                }
            }

            // Make a snapshot of the cell
            let cell = tableView.cellForRow(at: indexPath) as! KanbanCell
            offset = gr.location(in: cell)

            let snapshot = cell.cellView.snapshotView(afterScreenUpdates: true)
            snapshot?.frame = scrollView.convert(cell.cellView.frame, from: cell.cellView.superview)
            scrollView.addSubview(snapshot!)

            self.snapshot = snapshot

            focus = (tableView, indexPath)

            tableView.reloadRows(at: [indexPath], with: .fade)
        case .changed:
            guard let focus = focus else { cancelAction(); return }

            var offsetLocation = location
            offsetLocation.x -= offset!.x
            offsetLocation.y -= offset!.y
            snapshot!.frame.origin = offsetLocation

            scrollView.autoScrollDragMoved(location)

            guard let (tableView, indexPath) = convertPointToIndexPath(point: location) else { return }

            if tableView === focus.0 {
                // Simply move row
                let oldIndexPath = focus.1
                self.focus = (tableView, indexPath)
                tableView.moveRow(at: oldIndexPath, to: indexPath)
            } else {
                // Remove row in previous table view, add row in current table view
                let (oldTableView, oldIndexPath) = focus
                self.focus = (tableView, indexPath)
                oldTableView.deleteRows(at: [oldIndexPath], with: .fade)
                tableView.insertRows(at: [indexPath], with: .fade)
            }
        case .ended, .failed, .cancelled:

            scrollView.autoScrollDragEnded()
            guard let _ = focus else { return }

            if let (tableView, indexPath) = convertPointToIndexPath(point: location) ?? focus {
                self.focus = nil

                for (i, value) in self.tableViewData.enumerated() {
                    if tableView === value.tableView {
                        if let element = self.element {
                            self.tableViewData[i].values.insert(element, at: indexPath.row)
                        }
                        break
                    }
                }

                element = nil
                self.snapshot?.removeFromSuperview()
                self.snapshot = nil

                tableView.reloadRows(at: [indexPath], with: .fade)
            }
        default:
            break
        }
    }

    func convertPointToIndexPath(point: CGPoint) -> (UITableView, IndexPath)? {
        if let tableView = self.tableViewData.filter({ $0.tableView.frame.contains(point) }).first?.tableView {
            let localPoint = self.scrollView.convert(point, to: tableView)
            let lastRowIndex = self.focus?.0 === tableView ? tableView.numberOfRows(inSection: 0) - 1 : tableView.numberOfRows(inSection: 0)
            let indexPath = tableView.indexPathForRow(at: localPoint) ?? IndexPath(row: lastRowIndex, section: 0)
            return (tableView, indexPath)
        }

        return nil
    }
}

extension KanbanViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
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
            if data.tableView === tableView {

                return focus?.0 === tableView ? data.values.count + 1 : data.values.count
            }
        }

        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "KanbanCell", for: indexPath) as! KanbanCell
        if let (tv, ip) = focus, tv === tableView && ip == indexPath {
            cell.cellView.alpha = 0.0
        } else {
            cell.cellView.alpha = 1.0
            cell.cellView.backgroundColor = .white

            for data in self.tableViewData {
                if data.tableView === tableView {
                    cell.titleLabel.text = data.values[indexPath.row]
                    cell.colorView.backgroundColor = data.color
                    cell.avatarImageView.image = UIImage().avatarImageWithame(fullName: data.values[indexPath.row], size: CGSize(width: 35, height: 35), fontColor: UIColor(white: 1, alpha: 0.6), font: UIFont.systemFont(ofSize: 16))
                    break
                }
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        for data in self.tableViewData {
            if data.tableView === tableView {
                return data.title + " TITLE"
            }
        }

        return ""
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        for data in self.tableViewData {
            if data.tableView === tableView {
                return data.title + " SUBTITLE"
            }
        }

        return ""
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "HeaderView") {
            headerView.textLabel?.textColor = UIColor.black
            headerView.textLabel?.font = MSFont.lightFontWithSize(15)
            headerView.textLabel?.backgroundColor = .clear
            headerView.contentView.backgroundColor = MSColor.headerColor()

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

