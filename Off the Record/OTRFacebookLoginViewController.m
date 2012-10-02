//
//  OTRFacebookLoginViewController.m
//  Off the Record
//
//  Created by David on 10/2/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRFacebookLoginViewController.h"
#import "Strings.h"

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
    facebookHelpLabel.frame = CGRectMake(5, 3, 250, 40);
    facebookHelpLabel.backgroundColor = [UIColor clearColor];
    facebookHelpLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
    
    self.facebookInfoButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
    [self.facebookInfoButton addTarget:self action:@selector(facebookInfoButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self addCellinfoWithSection:0 row:1 labelText:facebookHelpLabel cellType:KCellTypeHelp userInputView:facebookInfoButton];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
