//
//  OTRViewSetting.h
//  Off the Record
//
//  Created by Chris Ballinger on 4/11/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRSetting.h"

@protocol OTRViewSettingDelegate <NSObject>
@required
- (void)showViewControllerClass:(Class)viewControllerClass;
@end

@interface OTRViewSetting : OTRSetting

@property (nonatomic, readonly) Class viewControllerClass;
@property (nonatomic, retain) id<OTRViewSettingDelegate> delegate;

- (id) initWithTitle:(NSString*)newTitle description:(NSString*)newDescription viewControllerClass:(Class)newViewControllerClass;

- (void) showView;

@end
