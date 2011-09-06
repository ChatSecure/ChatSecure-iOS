#import <UIKit/UIKit.h>

@class XMPPStream;
@class XMPPMessage;
@class ChatViewController;
@protocol XMPPUser;


@interface ChatWindowManager : NSObject
{
    NSMutableDictionary *chatControllers;
    ChatViewController *activeChatController;
}

- (void)openChatWindowWithStream:(XMPPStream *)xmppStream forUser:(id <XMPPUser>)user;

- (void)handleChatMessage:(XMPPMessage *)message withStream:(XMPPStream *)xmppStream;

@property (nonatomic, retain)     ChatViewController *activeChatController;

@property (nonatomic, retain) XMPPMessage *backgroundMessage;
@property (nonatomic, retain) XMPPStream *backgroundStream;

@end
