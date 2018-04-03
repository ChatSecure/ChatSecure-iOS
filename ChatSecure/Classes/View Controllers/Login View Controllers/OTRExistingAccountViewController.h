//
//  OTRAdvancedWelcomeViewController.h
//  ChatSecure
//
//  Created by Christopher Ballinger on 7/20/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

@import UIKit;

@class OTRAccount;

@interface OTRWelcomeAccountInfo : NSObject

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSString *labelText;
@property (nonatomic, copy) void (^didSelectBlock)(void);

+ (instancetype)accountInfoWithText:(NSString *)text image:(UIImage *)image didSelectBlock:(void (^)(void))didSelectBlock;

@end

@interface OTRExistingAccountViewController : UITableViewController

@property (nonatomic, strong, readonly) NSArray *accountInfoArray;

- (instancetype) initWithAccountInfoArray:(NSArray*)accountInfoArray;

@property (nonatomic, copy) void (^completionBlock)(OTRAccount * account, NSError *error);


@end
