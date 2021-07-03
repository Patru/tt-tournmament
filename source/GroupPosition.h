//
//  GroupPosition.h
//  Tournament
//
//  Created by Paul Trunz on Fri Apr 18 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface GroupPosition : NSObject {
   long _group;
   long _position;
}

+ (GroupPosition *) forGroup:(long) group position:(long) position;

- (GroupPosition *) initForGroup:(long) group position:(long) position;
- (long)groupNo;
- (long)position;
@end
