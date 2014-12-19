//
//  JSQMessagesCollectionViewCell+ChatSecure.m
//  ChatSecure
//
//  Created by David Chiles on 12/16/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "JSQMessagesCollectionViewCell+ChatSecure.h"

@implementation JSQMessagesCollectionViewCell (ChatSecure)

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(delete:)) {
        return YES;
    }
    
    return [super canPerformAction:action withSender:sender];
}

- (void)delete:(id)sender
{
    [self performSelectorOnParentCollectionView:@selector(delete:)
                                     withSender:sender];
}


// See issue https://github.com/jessesquires/JSQMessagesViewController/issues/569
// and issue https://github.com/jessesquires/JSQMessagesViewController/issues/483
- (void)performSelectorOnParentCollectionView:(SEL)selector
                                   withSender:(id)sender {
    UIView *view = self;
    do {
        view = view.superview;
    } while (![view isKindOfClass:[UICollectionView class]]);
    UICollectionView *collectionView = (UICollectionView *)view;
    NSIndexPath *indexPath = [collectionView indexPathForCell:self];
    
    if (collectionView.delegate &&
        [collectionView.delegate respondsToSelector:@selector(collectionView:
                                                  performAction:
                                                  forItemAtIndexPath:
                                                  withSender:)])
        
        [collectionView.delegate collectionView:collectionView
                                  performAction:selector
                             forItemAtIndexPath:indexPath
                                     withSender:sender];
}
@end
