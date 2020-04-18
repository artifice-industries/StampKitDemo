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
    
    @IBOutlet weak var tableView: NSTableView!
    
    let server = SKServer()
    var timelineCount: Int = 1

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        server.delegate = self
        server.start()
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func updateView() {
        tableView.reloadData()
    }
    
    @IBAction func addTimeline(_ sender: Any) {
        let timeline = SKTimelineDescription(name: "Untitled Timeline \(timelineCount)", uuid: UUID())
        timelineCount += 1
        server.add(timeline: timeline)
    }
    
    @IBAction func removeTimeline(_ sender: Any) {
        let selectedRow = tableView.selectedRow
        if server.timelines.indices.contains(selectedRow) {
            let timeline = server.timelines[selectedRow]
            server.remove(timeline: timeline)
        }
    }
    
}

extension ViewController: NSTableViewDataSource {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("cell"), owner: self) as! NSTableCellView
        if tableColumn?.identifier == NSUserInterfaceItemIdentifier("name") {
            cell.textField?.stringValue = server.timelines[row].name
            cell.textField?.isEditable = true
            cell.textField?.delegate = self
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier("uuid") {
            cell.textField?.stringValue = server.timelines[row].uuid.uuidString
            cell.textField?.isEditable = false
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier("password") {
            cell.textField?.stringValue = server.timelines[row].password ?? ""
            cell.textField?.isEditable = true
            cell.textField?.delegate = self
        }
        return cell
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return server.timelines.count
    }
    
}

extension ViewController: NSTableViewDelegate {
    
}

extension ViewController: NSTextFieldDelegate {
    
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else { return }
        let columnIndex = tableView.column(for: textField)
        let rowIndex = tableView.row(for: textField)
        if server.timelines.indices.contains(rowIndex) {
            switch columnIndex {
            case tableView.column(withIdentifier: NSUserInterfaceItemIdentifier("name")):
                let timeline = server.timelines[rowIndex]
                server.change(timeline: timeline, name: textField.stringValue)
            case tableView.column(withIdentifier: NSUserInterfaceItemIdentifier("password")):
                let timeline = server.timelines[rowIndex]
                server.change(timeline: timeline, password: textField.stringValue)
            default: break
            }
        }
    }
    
}

extension ViewController: SKServerDelegate {
    func statusCode(for client: SKClientFacade, sendingMessage message: OSCMessage, toServer server: SKServer, forTimelines timelines: [SKTimelineDescription]) -> SKResponseStatusCode {
        return SKResponseStatusCode.created
    }
    
    func server(_: SKServer, didReceiveMessage message: OSCMessage, withTimeline timeline: SKTimelineDescription) {
        print("Incoming message for timeline: \(timeline.name)")
        print("Message: \(OSCAnnotation.annotation(for: message, with: .spaces, andType: true))")
    }
    
    func server(_: SKServer, didReceiveMessage message: OSCMessage, forTimelines timelines: [SKTimelineDescription]) {
        print("Incoming Message for timelines:")
        for timeline in timelines {
            print(timeline.name)
        }
        print("Message: \(OSCAnnotation.annotation(for: message, with: .spaces, andType: true))")
    }
    
    func server(_: SKServer, didUpdateTimelines: [SKTimelineDescription]) {
        updateView()
    }
    
    func server(_: SKServer, didUpdateConnectedClients clients: [SKClientFacade], toTimeline timeline: SKTimelineDescription) {
        print("Timeline: \(timeline.name), Clients: \(clients.count)")
    }
    
}


