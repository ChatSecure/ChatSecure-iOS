//
//  OTRFacebookLoginViewController.m
//  Off the Record
//
//  Created by David on 10/2/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//
//  This file is part of ChatSecure.
//
//  ChatSecure is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ChatSecure is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ChatSecure.  If not, see <http://www.gnu.org/licenses/>.

#import "OTRFacebookLoginViewController.h"
#import "Strings.h"
#import "OTRAppDelegate.h"

@interface OTRFacebookLoginViewController ()

@end

@implementation OTRFacebookLoginViewController

@synthesize facebookHelpLabel;
@synthesize facebookInfoButton;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Removes @chat.facebook.com so to display plain username
    self.usernameTextField.text = [self.account.username stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"@%@",kOTRFacebookDomain] withString:[NSString string]];
    
    facebookHelpLabel = [[UILabel alloc] init];
    facebookHelpLabel.text = FACEBOOK_HELP_STRING;
    facebookHelpLabel.textAlignment = UITextAlignmentLeft;
    facebookHelpLabel.lineBreakMode = UILineBreakModeWordWrap;
    facebookHelpLabel.numberOfLines = 0;
    facebookHelpLabel.font = [UIFont systemFontOfSize:14];
    CGSize maximumLabelSize = CGSizeMake(296,9999);
    CGSize labelSize = [FACEBOOK_HELP_STRING sizeWithFont:facebookHelpLabel.font constrainedToSize:maximumLabelSize lineBreakMode:facebookHelpLabel.lineBreakMode];
    
    facebookHelpLabel.frame = CGRectMake(5, 3, labelSize.width, labelSize.height);
    facebookHelpLabel.backgroundColor = [UIColor clearColor];
    //facebookHelpLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    self.facebookInfoButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
    [self.facebookInfoButton addTarget:self action:@selector(facebookInfoButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self addCellinfoWithSection:0 row:1 labelText:facebookHelpLabel cellType:KCellTypeHelp userInputView:facebookInfoButton];
}

-(void)facebookInfoButtonPressed:(id)sender
{
    UIActionSheet * urlActionSheet = [[UIActionSheet alloc] initWithTitle:kOTRFacebookUsernameLink delegate:self cancelButtonTitle:CANCEL_STRING destructiveButtonTitle:nil otherButtonTitles:OPEN_IN_SAFARI_STRING, nil];
    [OTR_APP_DELEGATE presentActionSheet:urlActionSheet inView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        
        NSURL *url = [ [ NSURL alloc ] initWithString: kOTRFacebookUsernameLink ];
        [[UIApplication sharedApplication] openURL:url];
        
    }
}

-(void)readInFields
{
    [super readInFields];
    NSString * usernameText = [self.usernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    usernameText = [NSString stringWithFormat:@"%@@%@",usernameText,kOTRFacebookDomain];
    [self.account setNewUsername:usernameText];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
