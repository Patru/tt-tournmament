//
//  GroupPosition.m
//  Tournament
//
//  Created by Paul Trunz on Fri Apr 18 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "GroupPosition.h"


@implementation GroupPosition

+ (GroupPosition *) forGroup:(long) group position:(long) position;
{
   GroupPosition *aGroupPosition = [[GroupPosition alloc] initForGroup:group position:position];   
   return aGroupPosition;
}

- (GroupPosition *) initForGroup:(long) group position:(long) position;
{
   _group = group;
   _position = position;
   
   return self;
}

- (long)groupNo;
{
   return _group;
}

- (long)position;
{
   return _position;
}

@end
