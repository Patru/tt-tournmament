//
//  Tournament.swift
//  Tournament
//
//  Created by Paul Trunz on 03.07.17.
//
//

import Foundation

class Tournament : NSObject {
   @objc var id: String
   @objc var apiKey: String
   @objc var title: String
   @objc var subtitle: String
   @objc var dateRange: String
   @objc var referee: String
   @objc var associations: String
   @objc var upload: String
   @objc var commercial: String
   @objc var depotStartingNumber: Double
   @objc var clickTtId: String
   @objc var dateFrom: Date = Date(timeIntervalSinceNow: TimeInterval(exactly: 60*60*24*60)!)
   @objc var dateTo: Date = Date(timeIntervalSinceNow: TimeInterval(exactly: 60*60*24*60)!)
   @objc var dateForExport: Date = Date(timeIntervalSinceNow: TimeInterval(exactly: 60*60*24*60)!)
   @objc var region: String
   @objc var type: String
   
   override init() {
      id = ""
      apiKey = ""
      title = ""
      subtitle = ""
      dateRange = ""
      referee = ""
      associations = ""
      upload = ""
      commercial = ""
      depotStartingNumber = 0.0
      clickTtId = ""
      region = ""
      type = ""
      dateFrom = Date(timeIntervalSinceNow: TimeInterval(exactly: 60*60*24*60)!)
      dateTo = dateFrom
      dateForExport = dateFrom
   }
   
   init(from rs: PGSQLRecordset) {
      id = rs.field(byName: "tournamentId").asString()
      apiKey = rs.field(byName: "apiKey").asString()
      title = rs.field(byName: "title").asString()
      subtitle = rs.field(byName: "subtitle").asString()
      dateRange = rs.field(byName: "dateRange").asString()
      referee = rs.field(byName: "referee").asString()
      associations = rs.field(byName: "associations").asString()
      upload = rs.field(byName: "upload").asString()
      commercial = rs.field(byName: "commercial").asString()
      if let depot = rs.field(byName: "depotStartingNumber").asNumber() {
         depotStartingNumber = Double(truncating: depot)
      } else {
         depotStartingNumber = 0.0
      }
      clickTtId = rs.field(byName: "clickTtId").asString()
      region = rs.field(byName: "region").asString()
      type = rs.field(byName: "type").asString()
      dateFrom = rs.field(byName: "dateFrom").asDate()
      dateTo = rs.field(byName: "dateTo").asDate()
      dateForExport = rs.field(byName: "dateForExport").asDate()
   }
   
   func save() {
      if let database = TournamentDelegate.shared.database() {
         if let rs = database.open("SELECT Count(*) from Tournament where tournamentId = '\(id)'") as? PGSQLRecordset {
            let tournamentCount = rs.field(by: 0).asLong()
            if tournamentCount == 0 {
               insert(into:database)
            } else if tournamentCount == 1 {
               update(in:database)
            }
         }
      }
   }
   
   static let AllFields = "tournamentId, apiKey, title, subtitle, dateRange, referee, associations, upload, commercial, depotStartingNumber, clickTtId, region, type, dateFrom, dateTo , dateForExport"

   func insert(into database: PGSQLConnection) {
      let insertSql = String(format: "INSERT INTO Tournament (%@) VALUES ('%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', %f, '%@', '%@', '%@',  '%@', '%@', '%@')", Tournament.AllFields, id.sqlEscaped(), apiKey.sqlEscaped(), title.sqlEscaped(), subtitle.sqlEscaped(), dateRange.sqlEscaped(), referee.sqlEscaped(), associations.sqlEscaped(), upload.sqlEscaped(), commercial.sqlEscaped(), depotStartingNumber, clickTtId.sqlEscaped(), region.sqlEscaped(), type.sqlEscaped(), dateFrom.pgDate(), dateTo.pgDate(), dateForExport.pgDate() )
      if database.execCommand(insertSql) != 1 {
         NSLog("%@", database.errorDescription)
      }
   }
   
   func update(in database: PGSQLConnection) {
      let updateSql = String(format: "UPDATE Tournament SET apiKey = '%@', title = '%@', subtitle = '%@', dateRange = '%@', referee = '%@', associations = '%@', upload = '%@', commercial = '%@', depotStartingNumber = %f, clickTtId = '%@', region = '%@', type = '%@', dateFrom = '%@', dateTo = '%@' , dateForExport = '%@' WHERE tournamentId = '%@'", apiKey.sqlEscaped(), title.sqlEscaped(), subtitle.sqlEscaped(), dateRange.sqlEscaped(), referee.sqlEscaped(), associations.sqlEscaped(), upload.sqlEscaped(), commercial.sqlEscaped(), depotStartingNumber, clickTtId.sqlEscaped(), region.sqlEscaped(), type.sqlEscaped(), dateFrom.pgDate(), dateTo.pgDate(), dateForExport.pgDate(), id.sqlEscaped())
      
      if database.execCommand(updateSql) != 1 {
         NSLog("%@", database.errorDescription)
      }
   }
   
   @objc lazy var commercialImage : NSImage = {
      let commercialArea = NSSize(width: 100, height: 80)
      if let image = NSImage(contentsOfFile: self.commercial) {
         var commercialSize = commercialArea
         let imageSize = image.size
         if imageSize.width/imageSize.height > commercialSize.width/commercialSize.height {
            commercialSize.height = commercialSize.width/imageSize.width * imageSize.height
         } else {
            commercialSize.width = commercialSize.height/imageSize.height * imageSize.width;
         }
         image.size = commercialSize
         return image
      } else {
         return NSImage(size: commercialArea)
      }
   }()
   /* - (NSImage *)  commercialImage;
    {
    if(commercialImage == nil) {
    commercialImage = [[NSImage alloc]
    initWithContentsOfFile:[self commercial]];
    //      [commercialImage setScalesWhenResized:YES];
    [self sizeCommercial];
    } // if
    
    return commercialImage;
    }
    
    - (void)sizeCommercial;
    // sizes the commercial NXImage to the space available
    {  NSSize  commercialSize, actualSize;
    
    commercialSize.width = 180;
    commercialSize.height = 80;
    actualSize = [commercialImage size];
    if(actualSize.width/actualSize.height >
    commercialSize.width/commercialSize.height){
    commercialSize.height = commercialSize.width/actualSize.width
    * actualSize.height;
    } else {
    commercialSize.width = commercialSize.height/actualSize.height
    * actualSize.width;
    }
    [commercialImage setSize:commercialSize];
    
    }// sizeCommercial
 */
   
   static func fetch(with id: String) -> Tournament? {
      let selectOne = String(format: "SELECT %@ FROM Tournament WHERE TournamentID = '%@'", AllFields, id)
      if let database = TournamentDelegate.shared.database() {
         if let rs = database.open(selectOne) as? PGSQLRecordset {
            if !rs.isEOF {
               return Tournament(from: rs)
            }
         }
      }
      return nil
   }
   
   @objc static func all() -> [Tournament] {
      let selectAll = String(format: "SELECT %@ FROM Tournament", AllFields)
      var tournaments = [Tournament]()
      if let database = TournamentDelegate.shared.database() {
         if let rs = database.open(selectAll) as? PGSQLRecordset {
            while !rs.isEOF {
               tournaments.append(Tournament(from: rs))
               rs.moveNext()
            }
         }
      }
      return tournaments
   }
}
