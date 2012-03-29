//
//  OTRAboutViewController.h
//  Off the Record
//
//  Created by Chris Ballinger on 12/9/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OTRAboutViewController : UIViewController <UIWebViewDelegate, UIActionSheetDelegate>

@property (strong, nonatomic) IBOutlet UILabel *versionLabel;
@property (nonatomic, retain) UIWebView *aboutTextView;
@property (nonatomic, retain) NSURL *lastActionLink;

@end
