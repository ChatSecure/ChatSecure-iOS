//
//  OTRMessagesCollectionViewCell.h
//  Off the Record
//
//  Created by David Chiles on 6/3/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "JSQMessagesCollectionViewCell.h"

@class OTRMessagesCollectionViewCell;
@class OTRMessage;

@protocol OTRMessagesCollectionViewCellDelegate <NSObject>

@required

@optional

- (void)messagesCollectionViewCellDidTapDelete:(OTRMessagesCollectionViewCell *)cell;
- (void)messagesCollectionViewCellDidTapError:(OTRMessagesCollectionViewCell *)cell;

@end

@interface OTRMessagesCollectionViewCell : JSQMessagesCollectionViewCell

@property (nonatomic, weak) id<OTRMessagesCollectionViewCellDelegate> actionDelegate;

- (void) setMessage:(OTRMessage*)message;

@end
