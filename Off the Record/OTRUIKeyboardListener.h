//
//  OTRUIKeyboardListener.h
//  Off the Record
//
//  Created by David Chiles on 5/15/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTRUIKeyboardListener : NSObject
{
    BOOL visible;
    NSNotification * lastNotification;
}

@property (nonatomic) CGRect keyboardFrame;

+ (OTRUIKeyboardListener *) shared;

-(BOOL)isVisible;
-(NSNotification *) lastNotification;


@end
