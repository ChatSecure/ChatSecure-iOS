//
//  OTRAboutViewController.h
//  Off the Record
//
//  Created by Chris Ballinger on 12/9/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DTAttributedTextView.h"

@interface OTRAboutViewController : UIViewController <DTAttributedTextContentViewDelegate, UIActionSheetDelegate>
{
    NSURL *lastActionLink;
    DTAttributedTextView *aboutTextView;
}

@end
