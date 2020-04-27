//
//  ViewController.swift
//  StampKitDemo
//
//  Created by Sam Smallman on 14/04/2020.
//  Copyright © 2020 Artifice Industries Ltd. All rights reserved.
//

import Cocoa
import StampKit
import OSCKit

class ViewController: NSViewController {
    
    @IBOutlet weak var textField: NSTextField!
    @IBOutlet weak var tableView: NSTableView!
    
    let browser = SKBrowser()
    var timeline: SKTimeline?
    var rows: [AnyObject] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.doubleAction = #selector(connect)
        browser.delegate = self
        browser.start()
        browser.refresh(every: 3)
    }
    
    func updateView() {
        let selected = tableView.selectedRowIndexes
        rows.removeAll()
        for server in browser.servers {
            rows.append(server)
            server.timelines.sorted(by: { $0.name < $1.name }).forEach({ rows.append($0) })
        }
        tableView.reloadData()
        tableView.selectRowIndexes(selected, byExtendingSelection: false)
    }
    
    @objc func connect() {
        disconnect()
        let selectedRow = tableView.selectedRow
        guard selectedRow > -1, let selectedTimeline = rows[selectedRow] as? SKTimeline else { return }
        if selectedTimeline.password.required {
            let viewController = PasswordViewController(timeline: selectedTimeline, connectedTimeline: &timeline)
            viewController.delegate = self
            self.view.window?.contentViewController?.presentAsSheet(viewController)
        } else {
            selectedTimeline.connect(completionHandler: { timeline in
                print("Connected: \(timeline.name)!")
                self.timeline = timeline
                self.updateView()
            })
        }
    }
    
    func disconnect() {
        guard let connectedTimeline = timeline else { return }
        connectedTimeline.disconnect()
        timeline = nil
    }
    
    @IBAction func note(_ sender: Any) {
        guard let connectedTimeline = timeline, !textField.stringValue.isEmpty else { return }
        connectedTimeline.request(note: textField.stringValue, withColour: .green, completionHandler: { description in
            print("Received:")
            print("Note: \(description.note)")
            print("Colour: \(description.colour)")
            print("Code: \(description.code)")
        })
        textField.stringValue = ""
    }
    
}

extension ViewController: NSTableViewDataSource {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("cell"), owner: self) as! NSTableCellView
        if let server = rows[row] as? SKServerFacade {
            cell.textField?.stringValue = server.name
        }
        if let timeline = rows[row] as? SKTimeline {
            if tableColumn?.identifier == NSUserInterfaceItemIdentifier("name") {
                cell.textField?.stringValue = timeline.name
                cell.textField?.isEditable = false
            } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier("uuid") {
                cell.textField?.stringValue = timeline.uniqueID
                cell.textField?.isEditable = false
            } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier("connection") {
                cell.textField?.stringValue = timeline.connected ? "Connected" : ""
                cell.textField?.isEditable = false
            }
            return cell
        }
        return cell
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return rows.count
    }
    
    func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        return rows[row] is SKServerFacade
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return rows[row] is SKServerFacade == false
    }
    
}

extension ViewController: NSTableViewDelegate {
    
}

extension ViewController: SKBrowserDelegate {
    
    func browser(_: SKBrowser, didUpdateTimelinesForServer server: SKServerFacade) {
        updateView()
    }
    
    func browser(_: SKBrowser, didUpdateServers servers: Set<SKServerFacade>) {
        updateView()
    }
    
}

extension ViewController: SKTimelineDelegate {
    func timeline(error: Error) {
        print(error)
    }
    
    func timelineDidDisconnect(timeline: SKTimeline) {
        print("Disconnected: \(timeline.name)")
        guard self.timeline == timeline else { return }
        self.timeline = nil
    }
}

extension ViewController: PasswordDelegate {
    func passwordController(_ controller: PasswordViewController, didConnectToTimeline timeline: SKTimeline) {
        self.timeline = timeline
        self.updateView()
    }
    
    
}

