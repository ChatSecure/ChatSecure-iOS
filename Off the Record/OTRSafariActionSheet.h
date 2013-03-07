//
//  OTRSafariActionSheet.h
//  Off the Record
//
//  Created by David on 3/6/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OTRSafariActionSheet : UIActionSheet <UIActionSheetDelegate>
{
    NSURL * url;
}

-(id)initWithUrl:(NSURL *)url;

@end
