//
//  OTRAudioTrashView.h
//  ChatSecure
//
//  Created by David Chiles on 4/8/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BButton.h"

@interface OTRAudioTrashView : UIView

@property (nonatomic, strong, readonly) BButton *trashButton;
@property (nonatomic, strong, readonly) UILabel *trashLabel;

@end
