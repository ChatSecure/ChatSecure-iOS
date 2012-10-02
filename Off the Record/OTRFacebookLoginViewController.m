//
//  OTRFacebookLoginViewController.m
//  Off the Record
//
//  Created by David on 10/2/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

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
    
    facebookHelpLabel = [[UILabel alloc] init];
    facebookHelpLabel.text = FACEBOOK_HELP_STRING;
    facebookHelpLabel.textAlignment = UITextAlignmentLeft;
    facebookHelpLabel.lineBreakMode = UILineBreakModeWordWrap;
    facebookHelpLabel.numberOfLines = 0;
    facebookHelpLabel.font = [UIFont systemFontOfSize:14];
    CGSize labelSize = [FACEBOOK_HELP_STRING sizeWithFont:facebookHelpLabel.font forWidth:280 lineBreakMode:facebookHelpLabel.lineBreakMode];
    labelSize = [FACEBOOK_HELP_STRING sizeWithFont:facebookHelpLabel.font constrainedToSize:CGSizeMake(260, 100) lineBreakMode:facebookHelpLabel.lineBreakMode];
    facebookHelpLabel.frame = CGRectMake(5, 3, labelSize.width, labelSize.height);
    facebookHelpLabel.backgroundColor = [UIColor clearColor];
    facebookHelpLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
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
    self.account.username = usernameText;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
