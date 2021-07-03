//
//  Loader.swift
//  Tournament
//
//  Created by Paul Trunz on 09.06.17.
//
//

import Foundation

class ClickTtLoader : NSObject, URLSessionTaskDelegate {
   let window: NSWindow
   let progress: NSProgressIndicator
   let activity: NSTextField
   
   init(_ window: NSWindow, progress: NSProgressIndicator, activity: NSTextField) {
      self.window = window
      self.progress = progress
      self.activity = activity
   }
   
   func urlSession(_ session: URLSession,
                   task: URLSessionTask,
                   didReceive challenge: URLAuthenticationChallenge,
                   completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
      if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPDigest {
         completionHandler(URLSession.AuthChallengeDisposition.useCredential, URLCredential(user: "stt_export", password: "k89swmxt", persistence: .forSession))
      } else if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
         if challenge.protectionSpace.host.contains("click-tt.ch") {
            completionHandler(.performDefaultHandling, nil)
         }  // performing more authentication than deserved by a public server
      } else {
         print("Do not know how to handle ", challenge.protectionSpace.authenticationMethod)
      }
   }
   
   func advance(_ newActivity:String?, by step: Double) {
      DispatchQueue.main.async {
         if let newActivity = newActivity {
            self.activity.stringValue = newActivity
         }
         self.progress.increment(by: step)
      }
   }
   
   func getPlayersAndReplaceDB() {
      let urlComponents = URLComponents(string: "https://www.click-tt.ch/Protected/Export/STT_Spielerlizenzen.zip")!
      var request = URLRequest(url: urlComponents.url!)
      request.httpMethod = "GET"
      let session = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: OperationQueue.main)
      progress.doubleValue = 0.0
      advance(§.downloadingFile, by: 1.0)
      session.dataTask(with: request) {data, response, err in
         if err == nil {
            switch(response?.mimeType) {
            case .some("application/zip"):
               self.advance(§.unzippingFile, by: 5.0)
               if let data = data , let response = response {
                  self.unzipAndLoadDb(from: data, of: response)
               }
            case .some("text/html"):      // the first request returns a 401 with text/html, but you only see this if the delegate is not configured properly
               if let returnData = String(data: data!, encoding: .isoLatin1) {
                  print(returnData)
               }
            default:
               print("oops, what is ", response?.mimeType ?? "?no Mime-Type!?")
            }
         } else {
            if let error = err {
               print("Error: ", error.localizedDescription)
            } else {
               if let response = response {
                  print("do not know what to do with ", response.mimeType!)
               }
            }
         }
      }.resume()
   }
   
   func unzipAndLoadDb(from data: Data, of response: URLResponse) {
      print("unzipping")
      let fileMgr = FileManager.default
      var tmpUrl : URL
      if #available(OSX 10.12, *) {
         tmpUrl = fileMgr.temporaryDirectory
      } else {
         tmpUrl = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
      }
      let licenceUrl = tmpUrl.appendingPathComponent("Licences", isDirectory: true)
      do {
         try fileMgr.createDirectory(at: licenceUrl, withIntermediateDirectories:true, attributes: nil)
         if let filename = response.suggestedFilename,
            let target = try self.unzip(data, name: filename, inDir: licenceUrl) {
            self.advance(§.countingLines, by: 2.0)
            let allLines = try String(contentsOf: target, encoding: String.Encoding.isoLatin1)
            DispatchQueue.global(qos: .background).async {
               let (before, after) = self.loadDb(from: allLines)
               self.advance(String(format: §.playersBeforeAfter, before, after), by: 1.0)
            }
         }
      } catch  {
         print(error.localizedDescription)          // ignore creation failures
      }
   }
   
   func loadDb(from lines: String) -> (Int, Int) {
      var newCount = 0
      let before = PlayerManager.numberOfClickTTMembers()
      PlayerManager.deleteClickTTMembers()
      var linesCount = 0
      lines.enumerateLines { (line: String, stop: inout Bool) in
         linesCount += 1
      }
      self.advance(String(format: §.parsingLines, linesCount), by: 2.0)
      let linesTick = linesCount/90;
      lines.enumerateLines { (line: String, stop: inout Bool) in
         let attrs = line.components(separatedBy: ";")
         if let licence = Int(attrs[1]) {
            PlayerManager.addToDB(with: licence, attrs)
            newCount += 1
            if newCount%linesTick == 0 {
               self.advance(nil, by: 1.0)
            }
         }
      }
      return (before, newCount)
   }
   
   func unzip(_ data: Data, name: String, inDir dirUrl: URL) throws -> URL? {
      let currentDir = FileManager.default.currentDirectoryPath
      defer {
         FileManager.default.changeCurrentDirectoryPath(currentDir)
      }
      let zipUrl = dirUrl.appendingPathComponent(name, isDirectory: false)
      try data.write(to: zipUrl)
      FileManager.default.changeCurrentDirectoryPath(dirUrl.path)
      let target = zipUrl.deletingPathExtension().appendingPathExtension("csv")
      try? FileManager.default.removeItem(at: target)
      
      let task = Process()
      task.launchPath = "/usr/bin/unzip"
      task.arguments = [name]
         
      let pipe = Pipe()
      task.standardOutput = pipe
      task.standardError = pipe
      task.launch()
      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      let output = String(data: data, encoding: .utf8)
      task.waitUntilExit()
      if task.terminationStatus == 0 {
         return target
      } else {
         print(output!)
      }
      return nil
   }
   
   @objc static func downloadPlayersFromClickTt(_ window: NSWindow, progress: NSProgressIndicator, activity: NSTextField) {
      let loader = ClickTtLoader(window, progress: progress, activity: activity)
      loader.getPlayersAndReplaceDB()
   }
}
