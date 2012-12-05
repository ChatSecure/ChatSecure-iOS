//
//  OTRLanguageListSettingViewController.m
//  Off the Record
//
//  Created by David on 11/20/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRLanguageListSettingViewController.h"
#import "Strings.h"

@interface OTRLanguageListSettingViewController ()

@end

@implementation OTRLanguageListSettingViewController



-(void)save:(id)sender
{
    if(![oldValue isEqualToString:newValue])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: LANGUAGE_ALERT_TITLE_STRING message:LANGUAGE_ALERT_MESSAGE_STRING delegate:self cancelButtonTitle:OK_STRING otherButtonTitles:nil];
        [alert show];
    }
    [super save:sender];
}

@end
