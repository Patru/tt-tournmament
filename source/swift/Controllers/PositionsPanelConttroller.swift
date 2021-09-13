//
//  PositionsPanelConttroller.swift
//  Tournament
//
//  Created by Paul Trunz on 13.02.20.
//

import Cocoa

class PositionsPanelController : NSViewController {
    @IBOutlet var positions: NSPanel!
    @IBOutlet weak var pos1: NSTextField!
    @IBOutlet weak var pos2: NSTextField!
    @IBOutlet weak var group1: NSTextField!
    @IBOutlet weak var group2: NSTextField!
    @IBOutlet weak var grPos1: NSTextField!
    @IBOutlet weak var grPos2: NSTextField!
    @IBOutlet weak var seriesLabel: NSTextField!
    
    var series: Series? {
        didSet {
            if let series = series {
                seriesLabel.stringValue = series.fullName()
                let maxPos = series.maxPositionNumber();

                pos1.stringValue = ""
                pos1.placeholderString = "1-\(maxPos)"
                pos2.stringValue = ""
                pos2.placeholderString = "1-\(maxPos)"
            }
        }
    }
    
    var modalWindow : NSWindow?
    
    @IBAction func switchPositions(_ sender: NSButton) {
        if let modalWindow = modalWindow {
            let p1 = pos1.intValue, p2 = pos2.intValue
            if p1 > 0 && p2 > 0 {
                series?.switchPos(Int(p1), with: Int(p2))
                modalWindow.endSheet(view.window!, returnCode: .OK)
            } else {
                modalWindow.endSheet(view.window!, returnCode: .cancel)
                let alert = NSAlert()
                alert.informativeText = "Zum Tauschen müssen beide Positionen gesetzt sein"
                alert.addButton(withTitle: §.ok)
                alert.beginSheetModal(for: modalWindow, completionHandler: nil)
            }
        }
    }
    
    func showModal(for window: NSWindow, with seris: Series) {
        series = seris
        modalWindow = window
        if let selfWindow = view.window {
            window.beginSheet(selfWindow) { (response) in
                if response == NSApplication.ModalResponse.stop {
                    
                }
            }
        }

    }
}
