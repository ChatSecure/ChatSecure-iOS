//
//  OTRRememberPasswordView.m
//  Off the Record
//
//  Created by David Chiles on 5/6/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRRememberPasswordView.h"
#import "Strings.h"

@interface OTRRememberPasswordView ()

@property (nonatomic, strong) UISwitch *rememberPasswordSwitch;
@property (nonatomic, strong) UILabel *rememberPasswordLabel;
@property (nonatomic, strong) UIButton *passwordInfoButton;


@end

@implementation OTRRememberPasswordView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
         ////// label //////
        self.rememberPasswordLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.rememberPasswordLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.rememberPasswordLabel.text = @"Remember Passphrase";
        
        ////// switch //////
        self.rememberPasswordSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        self.rememberPasswordSwitch.on = YES;
        self.rememberPasswordSwitch.translatesAutoresizingMaskIntoConstraints = NO;
        
        ////// info button //////
        self.passwordInfoButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
        [self.passwordInfoButton addTarget:self action:@selector(passwordInfoButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        self.passwordInfoButton.translatesAutoresizingMaskIntoConstraints = NO;
        
        
        [self addSubview:self.rememberPasswordLabel];
        [self addSubview:self.rememberPasswordSwitch];
        [self addSubview:self.passwordInfoButton];
    }
    return self;
}

- (void)passwordInfoButtonPressed:(id)sender
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Remember Passphrase" message:@"Your password will be stored in the iOS Keychain of this device only, and is only as safe as your device passphrase or pin. However, it will not persist during a device backup/restore via iTunes, so please don't forget it, or you may lose your conversation history." delegate:nil cancelButtonTitle:nil otherButtonTitles:OK_STRING, nil];
    [alertView show];
}

- (BOOL)rememberPassword
{
    return self.rememberPasswordSwitch.on;
}

- (void)setRememberPassword:(BOOL)rememberPassword
{
    self.rememberPasswordSwitch.on = rememberPassword;
}

- (void)updateConstraints
{
    [super updateConstraints];
    NSDictionary *views = NSDictionaryOfVariableBindings(_rememberPasswordLabel,_rememberPasswordSwitch,_passwordInfoButton);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|->=0-[_rememberPasswordLabel]->=0-|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|->=0-[_rememberPasswordSwitch]->=0-|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|->=0-[_passwordInfoButton]->=0-|" options:0 metrics:nil views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_rememberPasswordLabel]-(2)-[_passwordInfoButton]->=0-[_rememberPasswordSwitch]|" options:0 metrics:nil views:views]];
}

@end
