//
//  OTRDonateSetting.m
//  Off the Record
//
//  Created by Christopher Ballinger on 2/9/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRDonateSetting.h"
#import "Strings.h"

@implementation OTRDonateSetting

-(id)initWithTitle:(NSString *)newTitle description:(NSString *)newDescription
{
    self = [super initWithTitle:newTitle description:newDescription];
    if (self) {
        self.action = @selector(openPaypal);
    }
    return self;
}

- (void) openPaypal {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=6YFSLLQGDZFXY"]];
}


@end
