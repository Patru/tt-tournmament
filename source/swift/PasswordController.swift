//
//  PasswordController.swift
//  Tournament
//
//  Created by Paul Trunz on 05.08.17.
//
//

import Foundation

class PasswordController : NSViewController {
   var baseWindow : NSWindow? = nil
   @objc func checkPassword(for window: NSWindow) -> Bool {
      baseWindow = window
      baseWindow?.beginCriticalSheet(self.view.window!) { (returnCode: NSApplication.ModalResponse) in
         NSApp.stopModal(withCode: returnCode)
      }
      
      return NSApp.runModal(for: window) == .OK
   }
   
   @IBAction func checkUserInput(_ pwField: NSSecureTextField) {
      if pwField.stringValue == "Akribisch" {
         baseWindow?.endSheet(self.view.window!, returnCode: .OK)
//         NSApp.stopModal(withCode: 1)
      } else {
         let alert = NSAlert();
         alert.messageText = §.error
         alert.informativeText = §.canntDoThis
         alert.alertStyle = .warning
         alert.addButton(withTitle: §.ok)
     //    alert.synchronousModalSheet(for:self.view.window!.sheetParent)
         baseWindow?.endSheet(self.view.window!, returnCode: .cancel)
         alert.beginSheetModal(for: baseWindow!, completionHandler: nil)
      }
   }
}
