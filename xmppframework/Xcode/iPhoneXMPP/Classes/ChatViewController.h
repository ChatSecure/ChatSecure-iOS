//
//  ChatViewController.h
//  iPhoneXMPP
//
//  Created by Chris Ballinger on 8/31/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChatWindowManager.h"

@class XMPPStream;
@class XMPPMessage;
@class XMPPJID;

@interface ChatViewController : UIViewController
{
    XMPPStream *xmppStream;
    XMPPJID *jid;
    XMPPMessage *firstMessage;
}

- (id)initWithStream:(XMPPStream *)xmppStream jid:(XMPPJID *)fullJID;
- (id)initWithStream:(XMPPStream *)xmppStream jid:(XMPPJID *)fullJID message:(XMPPMessage *)message;

@property (nonatomic, readonly) XMPPStream *xmppStream;
@property (nonatomic, readonly) XMPPJID *jid;
@property (retain, nonatomic) IBOutlet UITextView *messageView;
@property (retain, nonatomic) IBOutlet UITextField *messageField;

@property (nonatomic, retain) ChatWindowManager *chatManager;

- (IBAction)sendMessage:(id)sender;

@end

