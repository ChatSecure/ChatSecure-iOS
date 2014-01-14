//
//  OTRSectionHeaderView.h
//  Off the Record
//
//  Created by David on 3/1/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OTRSectionHeaderViewDelegate;
@class OTRBuddyListSectionInfo;


@interface OTRSectionHeaderView : UITableViewHeaderFooterView

@property (nonatomic, strong) UIImageView * discolureImageView;
@property (nonatomic, weak) id <OTRSectionHeaderViewDelegate> delegate;
@property (nonatomic, weak) OTRBuddyListSectionInfo *sectionInfo;

+ (NSString*) reuseIdentifier;

@end


@protocol OTRSectionHeaderViewDelegate <NSObject>
@optional
-(void)sectionHeaderViewChanged:(OTRSectionHeaderView*)sectionHeaderView;
@end