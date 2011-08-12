//
//  AIMNickWInfo+BArt.h
//  LibOrange
//
//  Created by Alex Nichol on 6/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMNickWInfo.h"
#import "AIMBArtID.h"

@interface AIMNickWInfo (BArt)

- (NSArray *)bartIDs;
- (NSArray *)bartIDUpdateToList:(NSArray *)newIDs;
- (AIMBArtID *)bartBuddyIcon;

@end
