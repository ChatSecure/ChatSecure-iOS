//
//  OTRUIKeyboardListener.m
//  Off the Record
//
//  Created by David Chiles on 5/15/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRUIKeyboardListener.h"

@implementation OTRUIKeyboardListener


+ (OTRUIKeyboardListener *) shared {
    static OTRUIKeyboardListener * sListener;    
    if ( nil == sListener ) sListener = [[OTRUIKeyboardListener alloc] init];
    
    return sListener;
}

-(id) init {
    self = [super init];
    
    if ( self ) {
        NSNotificationCenter            *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(noticeShowKeyboard:) name:UIKeyboardDidShowNotification object:nil];
        [center addObserver:self selector:@selector(noticeHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    }
    
    return self;
}

-(void) noticeShowKeyboard:(NSNotification *)inNotification {
    visible = true;
    lastNotification = inNotification;
}

-(void) noticeHideKeyboard:(NSNotification *)inNotification {
    visible = false;
    lastNotification = inNotification;
}

-(BOOL) isVisible {
    return visible;
}
-(NSNotification *) lastNotification
{
    return lastNotification;
}
@end
