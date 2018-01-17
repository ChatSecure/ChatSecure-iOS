//
//  OTRAccountTableViewCell.m
//  Off the Record
//
//  Created by David Chiles on 11/27/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRAccountTableViewCell.h"

#import "OTRAccount.h"
#import "OTRImages.h"

@import OTRAssets;

@implementation OTRAccountTableViewCell

- (instancetype) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier]) {
        self.shareButton = [UIButton buttonWithType:UIButtonTypeSystem];
        UIImage *image = [[UIImage imageNamed:@"OTRShareIcon" inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        NSParameterAssert(image != nil);
        [self.shareButton setImage:image forState:UIControlStateNormal];
        [self.shareButton sizeToFit];
        self.accessoryView = self.shareButton;
    }
    return self;
}

- (void)setAccount:(OTRAccount *)account
{
    _account = account;
    self.textLabel.text = account.username;
    if (account.displayName.length){
        self.textLabel.text = account.displayName;
    }
    
    self.imageView.image = [account accountImage];
}

- (void)setConnectedText:(OTRLoginStatus)connectionStatus {
    if (connectionStatus == OTRLoginStatusAuthenticated) {
        self.detailTextLabel.text = CONNECTED_STRING();
    }
    else if (connectionStatus == OTRLoginStatusDisconnected) {
        self.detailTextLabel.text = nil;
    } else {
        self.detailTextLabel.text = CONNECTING_STRING();
    }
}

+ (NSString*) cellIdentifier {
    return NSStringFromClass([self class]);
}

@end
