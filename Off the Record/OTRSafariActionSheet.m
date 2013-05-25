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

@implementation OTRSafariActionSheet

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(id)initWithUrl:(NSURL *)newUrl
{
    
    if([[[OpenInChromeController alloc]init] isChromeInstalled])
    {
        self = [self initWithTitle:[[newUrl absoluteURL] description] delegate:self cancelButtonTitle:CANCEL_STRING destructiveButtonTitle:nil otherButtonTitles:OPEN_IN_SAFARI_STRING,@"Open in Chrome", nil];
    }
    else{
        self = [self initWithTitle:[[newUrl absoluteURL] description] delegate:self cancelButtonTitle:CANCEL_STRING destructiveButtonTitle:nil otherButtonTitles:OPEN_IN_SAFARI_STRING, nil];
    }
    
    url = newUrl;
   
    
    return self;
}


-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex)
    {
        if (buttonIndex == 0) {
            [[UIApplication sharedApplication] openURL:[url absoluteURL]];
        }
        else
        {
            [[[OpenInChromeController alloc]init] openInChrome:url];
        }
    }
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
