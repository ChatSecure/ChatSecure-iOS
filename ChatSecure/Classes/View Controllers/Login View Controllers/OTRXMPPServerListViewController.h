//
//  OTRXMPPServerListViewController.h
//  ChatSecure
//
//  Created by David Chiles on 5/20/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "XLFormViewController.h"
#import "XLForm.h"

@interface OTRXMPPServerListViewController : XLFormViewController <XLFormRowDescriptorViewController>

+ (XLFormDescriptor *)defaultServerForm;

@end
