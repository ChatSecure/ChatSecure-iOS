//
//  OTRBuddyListSectionInfo.h
//  Off the Record
//
//  Created by David on 3/1/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OTRSectionHeaderView;

@interface OTRBuddyListSectionInfo : NSObject

@property (nonatomic) BOOL open;
@property (nonatomic,strong) OTRSectionHeaderView * sectionHeaderView;

@end
