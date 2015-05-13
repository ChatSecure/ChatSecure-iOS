//
//  OTRLoginCreateViewController.h
//  ChatSecure
//
//  Created by David Chiles on 5/7/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, OTRCellType) {
    OTRCellTypeNone = 0,
    OTRCellTypeTextField,
    OTRCellTypeSecureTextField,
    OTRCellTypeTextLabel,
    OTRCellTypeButton,
    OTRCellTypeSwitch,
    OTRCellTypeHelp
};

@interface OTRLoginCellInfo : NSObject

@property (nonatomic) OTRCellType cellType;
@property (nonatomic, weak) UIView *inputView;
@property (nonatomic, strong) NSString *labelText;
@property (nonatomic, strong) NSString *selectorName;

@end

@interface OTRLoginCreateViewController : UIViewController

@property (nonatomic, strong, readonly) NSArray *cellInfoArray;

@end
