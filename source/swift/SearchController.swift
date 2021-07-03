//
//  SearchController.swift
//  Tournament
//
//  Created by Paul Trunz on 28.12.18.
//

import Foundation
import Cocoa

class SearchController : NSObject {
   func playerSearch(for field:NSSearchField) -> [String] {
      var names = [String]()
      guard let players = TournamentDelegate.shared.playerController.players(matching: field.stringValue)
         else {
            return names
      }
      if players.count == 1 {
         let player = players[0]
         let inspector = TournamentDelegate.shared.tournamentInspector
         inspector.inspect(player)
         field.stringValue = player.longName()
         inspector.showPlayerInspector(self)
      } else if players.count > 1 {
         for player in players {
            names.append(player.longName())
         }
      }
      return names
   }
   
   func matchSearch(for number:Int) -> [String] {
      var matches = [String]()
      let plbl = TournamentDelegate.shared.playable(withNumber: number)
      if let playable = plbl {
         let rep = String(format:"%ld %s", number, playable.textRepresentation())
         let inspector = TournamentDelegate.shared.tournamentInspector
         inspector.inspect(playable)
         matches.append(rep)
      }
      return matches
   }
   
   @IBAction func updateSearch(_ sender : NSSearchField) {
      sender.maximumRecents=15
      let searchString = sender.stringValue
      if CharacterSet(charactersIn: searchString).isSubset(of: CharacterSet.decimalDigits) {
         sender.searchMenuTemplate = menuTemplate(with: "Match")
         if let number = Int(searchString) {
            sender.recentSearches = matchSearch(for: number)
         }
      } else {
         if searchString.count >= 2 {
            sender.searchMenuTemplate = menuTemplate(with: "Spieler")
            sender.recentSearches = playerSearch(for: sender)
         }
      }
   }
   
   func menuTemplate(with title:String) -> NSMenu {
      let template = NSMenu(title: "Search Menu")
      
      template.autoenablesItems=true
      let titleItem = template.addItem(withTitle: title, action: nil, keyEquivalent: "")
      titleItem.tag = NSSearchField.recentsTitleMenuItemTag
      let separator = NSMenuItem.separator()
      separator.tag = NSSearchField.recentsTitleMenuItemTag
      template.addItem(separator)
      let dummyItem = template.addItem(withTitle: "Dummy", action: #selector(SearchController.select(_:)), keyEquivalent: "")
      dummyItem.tag = NSSearchField.recentsMenuItemTag
      
      return template
   }
   
   @IBAction func select(_ sender:Any) {
      if let item = sender as? NSMenuItem {
         NSLog("selected title: %s", item.title)
      }
   }
   /*
 
 - (IBAction)updateSearch:(NSSearchField *)sender;
 {
 NSString *searchString = [sender stringValue];
 if ([lastSearch isEqualToString:searchString]) {
 return;
 }
 lastSearch = searchString;
 NSSearchFieldCell *searchCell = [sender cell];
 if ([searchString rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet].invertedSet].location != NSNotFound) {
 if ([searchString length] >= 2) {
 [searchCell setSearchMenuTemplate:[self menuTemplateWithTitle:@"Spieler"]];
 NSArray<NSString *> *names = [self handlePlayerSearch:searchString];
 if (names != nil) {
 [searchCell setRecentSearches:names];
 //            dispatch_async(dispatch_get_main_queue(), ^(void){
 //               [[searchCell searchButtonCell] performClick:nil];
 //            });
 }
 }
 } else {
 [searchCell setSearchMenuTemplate:[self menuTemplateWithTitle:@"Match"]];
 NSArray<NSString *> *matchStrings = [self handleMatchSearch:[searchString intValue]];
 if (matchStrings != nil) {
 [searchCell setRecentSearches:matchStrings];
 }
 }
 }
 
 
 
 - (void)awakeFromNib
 {
 if ([searchField respondsToSelector:@selector(setRecentSearches:)]) {
 
 id searchCell = [searchField cell];
 [searchCell setMaximumRecents:20];
 [searchCell setSearchMenuTemplate:[self menuTemplateWithTitle:@"Spieler"]];
 }
 }
******************************
    - (NSArray<NSString *>*)handlePlayerSearch:(NSString *)fragment {
    NSArray<SinglePlayer *> *pls = [[TournamentDelegate.shared playerController] playersMatching:fragment];
    NSMutableArray<NSString *>* names = nil;
    
    if ([pls count] == 1) {
    TournamentInspectorController *inspector = [TournamentDelegate.shared tournamentInspector];
    SinglePlayer *player = [pls objectAtIndex:0];
    [inspector inspect:player];
    [inspector showPlayerInspector:self];
    [searchField setStringValue:[player longName]];
    } else if ([pls count] > 1) {
    names = [NSMutableArray array];
    for (SinglePlayer *player in pls) {
    [names addObject:[player longName]];
    }
    }
    return names;
    }

    - (NSArray<NSString *>*)handleMatchSearch:(int)number {
    id<Playable> match = [TournamentDelegate.shared playableWithNumber:number];
    if (match != nil) {
    NSString *rep = [NSString stringWithFormat:@"%ld %@", [match rNumber], [match textRepresentation]];
    TournamentInspectorController *inspector = [TournamentDelegate.shared tournamentInspector];
    [inspector inspect:match];
    [inspector showPlayerInspector:self];
    
    return [NSArray<NSString *> arrayWithObjects: rep, nil];
    }
    return nil;
    }
    
    - (IBAction)select:(id)sender; {
    if ([sender isKindOfClass:[NSMenuItem class]]) {
    NSLog(@"selected title: %@", [sender title]);
    }
    }

    - (NSMenu *)menuTemplateWithTitle:(NSString *)title {
    NSMenu *searchMenu = [[NSMenu alloc] initWithTitle:@"Search Menu"];
    [searchMenu setAutoenablesItems:YES];
    
    // first add our custom menu item (Important note: "action" MUST be valid or the menu item is disabled)
    NSMenuItem *item = [searchMenu addItemWithTitle:title action:NULL keyEquivalent:@""];
    [item setTag:NSSearchFieldRecentsTitleMenuItemTag];
    
    item = [NSMenuItem separatorItem];
    [item setTag:NSSearchFieldRecentsTitleMenuItemTag];
    [searchMenu addItem:item];
    
    item = [searchMenu addItemWithTitle:@"dummy" action:@selector(select:) keyEquivalent:@""];
    [item setTarget: self];
    [item setTag:NSSearchFieldRecentsMenuItemTag];
    
    return searchMenu;
    }

    
*/
}
