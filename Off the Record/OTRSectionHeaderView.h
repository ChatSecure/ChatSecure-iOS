//
//  OTRSectionHeaderView.h
//  Off the Record
//
//  Created by David on 3/1/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OTRSectionHeaderViewDelegate;



@interface OTRSectionHeaderView : UIView

@property (nonatomic, weak) UILabel *titleLabel;
@property (nonatomic, weak) UIButton *disclosureButton;
@property (nonatomic, assign) NSUInteger section;
@property (nonatomic, weak) id <OTRSectionHeaderViewDelegate> delegate;

-(id)initWithFrame:(CGRect)frame title:(NSString*)title section:(NSUInteger)sectionNumber delegate:(id <OTRSectionHeaderViewDelegate>)delegate;

@end


@protocol OTRSectionHeaderViewDelegate <NSObject>

@optional
-(void)sectionHeaderView:(OTRSectionHeaderView*)sectionHeaderView section:(NSUInteger)section opened:(BOOL)opened;

@end