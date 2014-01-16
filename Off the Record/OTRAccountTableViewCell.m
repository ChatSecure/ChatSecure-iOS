//
//  OTRAccountTableViewCell.m
//  Off the Record
//
//  Created by David Chiles on 11/27/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRAccountTableViewCell.h"

#import "OTRManagedAccount.h"
#import "OTRProtocolManager.h"
#import "OTRProtocol.h"

#import "Strings.h"

@implementation OTRAccountTableViewCell {
    NSString * accountUniqueIdentifier;
    NSObject<OTRProtocol> * protocol;
}

- (id)initWithAccount:(OTRManagedAccount *)account reuseIdentifier:(NSString *)identifier
{
    if(self = [self initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier])
    {
        [self setAccount:account];
    }
    return self;
}

- (void)setAccount:(OTRManagedAccount *)account
{
    [protocol removeObserver:self forKeyPath:NSStringFromSelector(@selector(isConnected))];
    accountUniqueIdentifier = account.uniqueIdentifier;
    
    self.textLabel.text = account.username;
    if (account.displayName.length){
        self.textLabel.text = account.displayName;
    }
    [self setConnectedText:account.isConnected];
    
    self.imageView.image = [UIImage imageNamed:account.imageName];
    
    if( account.accountType == OTRAccountTypeFacebook)
    {
        self.imageView.layer.masksToBounds = YES;
        self.imageView.layer.cornerRadius = 10.0;
    }
    
    OTRProtocolManager * protocolManager = [OTRProtocolManager sharedInstance];
    protocol = [[OTRProtocolManager sharedInstance].protocolManagers objectForKey:accountUniqueIdentifier];
    if (protocol) {
        [protocol addObserver:self forKeyPath:NSStringFromSelector(@selector(isConnected)) options:NSKeyValueObservingOptionNew context:NULL];
    }
    else {
        [protocolManager addObserver:self forKeyPath:NSStringFromSelector(@selector(protocolManagers)) options:NSKeyValueObservingOptionNew context:NULL];
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(isConnected))]) {
        BOOL isConnected = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        [self setConnectedText:isConnected];
    }
    else if ([keyPath isEqualToString:NSStringFromSelector(@selector(protocolManagers))]) {
        protocol = [[OTRProtocolManager sharedInstance].protocolManagers objectForKey:accountUniqueIdentifier];
        if (protocol) {
            [self setConnectedText:protocol.isConnected];
            [protocol addObserver:self forKeyPath:NSStringFromSelector(@selector(isConnected)) options:NSKeyValueObservingOptionNew context:NULL];
            [[OTRProtocolManager sharedInstance] removeObserver:self forKeyPath:NSStringFromSelector(@selector(protocolManagers))];
        }
    }
    
}

- (void)setConnectedText:(BOOL)isConnected {
    if (isConnected) {
        self.detailTextLabel.text = CONNECTED_STRING;
    }
    else {
        self.detailTextLabel.text = nil;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)dealloc {
    [protocol removeObserver:self forKeyPath:NSStringFromSelector(@selector(isConnected))];
    [[OTRProtocolManager sharedInstance] removeObserver:self forKeyPath:NSStringFromSelector(@selector(protocolManagers))];
}

@end
