//
//  OTRTextFieldTableViewCell.h
//  Off the Record
//
//  Created by David Chiles on 4/30/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>


@class JVFloatLabeledTextField;

@interface OTRTextFieldTableViewCell : UITableViewCell

@property (nonatomic, strong) JVFloatLabeledTextField *textField;

+ (NSString *)reuseIdentifier;

@end
