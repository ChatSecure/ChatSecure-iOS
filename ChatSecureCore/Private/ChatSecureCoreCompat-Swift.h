//
//  ChatSecureCoreCompat-Swift.h
//  ChatSecureCore
//
//  Created by Christopher Ballinger on 9/14/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

// Import this header instead of <ChatSecureCore/ChatSecureCore-Swift.h>
// This allows the pod to be built as a static or dynamic framework
// See https://github.com/CocoaPods/CocoaPods/issues/7594
#if __has_include("ChatSecureCore-Swift.h")
#import "ChatSecureCore-Swift.h"
#else
#import <ChatSecureCore/ChatSecureCore-Swift.h>
#endif
