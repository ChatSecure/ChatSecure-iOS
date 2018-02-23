//
//  OTRAppDelegate.h
//  Off the Record
//
//  Created by Chris Ballinger on 8/11/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//
//  This file is part of ChatSecure.
//
//  ChatSecure is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ChatSecure is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ChatSecure.  If not, see <http://www.gnu.org/licenses/>.

@import UIKit;

@class OTRSplitViewCoordinator, OTRConversationViewController, OTRMessagesViewController;
@protocol AppTheme;

NS_ASSUME_NONNULL_BEGIN

@interface OTRAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong, readonly) OTRConversationViewController *conversationViewController;
@property (nonatomic, strong, readonly) OTRMessagesViewController *messagesViewController;
@property (nonatomic, strong, readonly) OTRSplitViewCoordinator *splitViewCoordinator;

/** Only used from Database Unlock view. */
- (void) showConversationViewController;

@property (class, nonatomic, readonly) __kindof OTRAppDelegate *appDelegate;

@end


NS_ASSUME_NONNULL_END
