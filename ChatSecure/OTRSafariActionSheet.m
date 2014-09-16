//
//  OTRSafariActionSheet.m
//  Off the Record
//
//  Created by David on 3/6/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRSafariActionSheet.h"
#import "Strings.h"
#import "OpenInChromeController.h"

@interface OTRSafariActionSheet()

@property (nonatomic, strong) NSURL *url;

@end

@implementation OTRSafariActionSheet

-(id)initWithUrl:(NSURL *)newUrl
{
    
    if([[OpenInChromeController sharedInstance] isChromeInstalled])
    {
        self = [self initWithTitle:[[newUrl absoluteURL] description] delegate:self cancelButtonTitle:CANCEL_STRING destructiveButtonTitle:nil otherButtonTitles:OPEN_IN_SAFARI_STRING,@"Open in Chrome", nil];
    }
    else{
        self = [self initWithTitle:[[newUrl absoluteURL] description] delegate:self cancelButtonTitle:CANCEL_STRING destructiveButtonTitle:nil otherButtonTitles:OPEN_IN_SAFARI_STRING, nil];
    }
    
    self.url = newUrl;
   
    
    return self;
}


-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex)
    {
        if (buttonIndex == 0) {
            [[UIApplication sharedApplication] openURL:[self.url absoluteURL]];
        }
        else
        {
            [[OpenInChromeController sharedInstance] openInChrome:self.url];
        }
    }
}

@end
