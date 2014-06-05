//
//  OTRMessagesCollectionViewCell.h
//  Off the Record
//
//  Created by David Chiles on 6/3/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "JSQMessagesCollectionViewCell.h"

@class OTRMessagesCollectionViewCell;

@protocol OTRMessagesCollectionViewCellDelegate <JSQMessagesCollectionViewCellDelegate>

@required

@optional

- (void)messagesCollectionViewCellDidTapDelete:(OTRMessagesCollectionViewCell *)cell;
- (void)messagesCollectionViewCellDidTapError:(OTRMessagesCollectionViewCell *)cell;

@end

@interface OTRMessagesCollectionViewCell : JSQMessagesCollectionViewCell

@property (weak, nonatomic) id<OTRMessagesCollectionViewCellDelegate> delegate;

@property (weak, nonatomic, readonly) UIImageView *errorImageView;

@property (weak, nonatomic, readonly) UIImageView *lockImageView;

@end
