//
//  OTRRemotePushRegistrationInfoViewController.m
//  Off the Record
//
//  Created by David Chiles on 5/1/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRRemotePushRegistrationInfoViewController.h"
#import "OTRPushManager.h"
#import "OTRConstants.h"

@interface OTRRemotePushRegistrationInfoViewController ()

@property (nonatomic, strong) UITextView *textView;

@property (nonatomic, strong) UIButton *registerForPushButton;

@end

@implementation OTRRemotePushRegistrationInfoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectZero];
    self.textView.text = @"Explain why we need push";
    self.textView.userInteractionEnabled = NO;
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:self.textView];
    
    self.registerForPushButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.registerForPushButton setTitle:@"I want push" forState:UIControlStateNormal];
    self.registerForPushButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.registerForPushButton addTarget:self action:@selector(registerForPush:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.registerForPushButton];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_registerForPushButton,_textView);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_registerForPushButton]-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_textView]-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(70)-[_textView(100)]-[_registerForPushButton]" options:0 metrics:nil views:views]];
    
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(failedToRegister:)
                                                 name:OTRFailedRemoteNotificationRegistration
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(successfullRegistration:)
                                                 name:OTRSuccessfulRemoteNotificationRegistration
                                               object:nil];
    
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)registerForPush:(id)sender
{
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
}

- (void)failedToRegister:(NSNotification *)notification
{
    NSError *error = [notification.userInfo objectForKey:kOTRNotificationErrorKey];
    if (error) {
        //display error
    }
    else {
        //display generic error
    }
}

- (void)successfullRegistration:(NSNotification *)notification
{
    
}

@end
