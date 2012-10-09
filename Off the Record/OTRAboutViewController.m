//
//  OTRAboutViewController.m
//  Off the Record
//
//  Created by Chris Ballinger on 12/9/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
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

#import "OTRAboutViewController.h"
#import "Strings.h"
#import "OTRQRCodeViewController.h"
#import "OTRAppDelegate.h"

#define ACTIONSHEET_SHARE_TAG 2
#define ACTIONSHEET_LINK_TAG 1

@interface OTRAboutViewController(Private)
- (NSArray*) buttonTitlesForShareButton;
@end

@implementation OTRAboutViewController
@synthesize versionLabel, aboutTextView, lastActionLink, imageView;

- (void) dealloc {
    self.lastActionLink = nil;
}

- (id)init {
    if (self = [super init]) {
        self.title = ABOUT_STRING;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


#pragma mark - View lifecycle


- (void) loadView 
{
    [super loadView];
    self.versionLabel = [[UILabel alloc] init];
    self.imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chatsecure_banner.png"]];
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithTitle:SHARE_STRING style:UIBarButtonItemStyleBordered target:self action:@selector(shareButtonPressed:)];
    self.navigationItem.rightBarButtonItem = shareButton;

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    // Do any additional setup after loading the view from its nib.
    NSString *aboutString = [NSString stringWithFormat:@"%@: libotr, libgcrypt, libgpg-error, LibOrange, XMPPFramework, MBProgressHUD, Appirater, and SFHFKeychainUtils.<br><a href=\"https://chatsecure.org/\">%@</a><br><a href=\"https://github.com/chrisballinger/Off-the-Record-iOS\">%@</a><br><a href=\"https://www.transifex.com/projects/p/chatsecure\">%@</a>", ATTRIBUTION_STRING, PROJECT_HOMEPAGE_STRING, SOURCE_STRING, CONTRIBUTE_TRANSLATION_STRING];
    
    
    aboutTextView = [[UIWebView alloc] init];
	aboutTextView.delegate = self;
    [aboutTextView loadHTMLString:aboutString baseURL:[NSURL URLWithString:@"/"]];
    
    aboutTextView.userInteractionEnabled = YES;
    if([aboutTextView respondsToSelector:@selector(scrollView)]) {
        aboutTextView.scrollView.scrollEnabled = NO;
    }

    NSString *version = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"];
    versionLabel.text = [NSString stringWithFormat:@"%@ %@", VERSION_STRING, version];
    
    [self.view addSubview:aboutTextView];
    [self.view addSubview:imageView];
    [self.view addSubview:versionLabel];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    CGFloat imageViewFrameWidth = imageView.image.size.width;
    CGFloat imageViewFrameHeight = imageView.image.size.height;
    imageView.frame = CGRectMake(self.view.frame.size.width/2 - imageViewFrameWidth/2, 20, imageViewFrameWidth, imageViewFrameHeight);
    imageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    
    CGFloat versionLabelFrameWidth = 101;
    CGFloat versionLabelFrameHeight = 21;
    versionLabel.frame = CGRectMake(floorf(self.view.frame.size.width/2 - versionLabelFrameWidth/2), self.view.frame.size.height-versionLabelFrameHeight-20, versionLabelFrameWidth, versionLabelFrameHeight);
    versionLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
    
    CGFloat aboutTextViewFrameWidth = self.view.frame.size.width-40;
    CGFloat aboutTextViewFrameYOrigin = imageView.frame.origin.y + imageViewFrameHeight + 10;
    aboutTextView.frame = CGRectMake(self.view.frame.size.width/2-aboutTextViewFrameWidth/2, aboutTextViewFrameYOrigin, aboutTextViewFrameWidth, versionLabel.frame.origin.y - aboutTextViewFrameYOrigin);
    aboutTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.versionLabel = nil;
    self.aboutTextView = nil;
    self.imageView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    }
}

- (void) shareButtonPressed:(id)sender {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:SHARE_STRING delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    NSArray *buttonTitles = [self buttonTitlesForShareButton];
    for (NSString *title in buttonTitles) {
        [sheet addButtonWithTitle:title];
    }
    sheet.tag = ACTIONSHEET_SHARE_TAG;
    sheet.cancelButtonIndex = [buttonTitles count] - 1;
    
    [OTR_APP_DELEGATE presentActionSheet:sheet inView:self.view];
}

- (NSArray*) buttonTitlesForShareButton {
    NSMutableArray *titleArray = [NSMutableArray arrayWithCapacity:4];
    [titleArray addObject:@"SMS"];
    [titleArray addObject:@"E-mail"];
    [titleArray addObject:@"QR Code"];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 5.0)
    {
        [titleArray addObject:@"Twitter"];
    }
    [titleArray addObject:CANCEL_STRING];
    return titleArray;
}

- (NSString*) shareString {
    return [NSString stringWithFormat:@"%@: http://get.chatsecure.org", SHARE_MESSAGE_STRING];
}

- (NSString*) twitterShareString {
    return [NSString stringWithFormat:@"%@ @ChatSecure", [self shareString]];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == ACTIONSHEET_LINK_TAG) {
        if (buttonIndex != actionSheet.cancelButtonIndex)
        {
            [[UIApplication sharedApplication] openURL:[lastActionLink absoluteURL]];
        }
    } else if (actionSheet.tag == ACTIONSHEET_SHARE_TAG) {
        if (buttonIndex == 0) // SMS
        {
            if (![MFMessageComposeViewController canSendText]) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:ERROR_STRING message:[NSString stringWithFormat:@"SMS %@", NOT_AVAILABLE_STRING] delegate:nil cancelButtonTitle:OK_STRING otherButtonTitles:nil];
                [alert show];
            } else {
                MFMessageComposeViewController *sms = [[MFMessageComposeViewController alloc] init];
                sms.messageComposeDelegate = self;
                sms.body = [self shareString];
                sms.modalPresentationStyle = UIModalPresentationFormSheet;
                [self presentModalViewController:sms animated:YES];
            }
        }
        else if (buttonIndex == 1) // Email
        {
            if (![MFMailComposeViewController canSendMail])
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:ERROR_STRING message:[NSString stringWithFormat:@"E-mail %@", NOT_AVAILABLE_STRING] delegate:nil cancelButtonTitle:OK_STRING otherButtonTitles:nil];
                [alert show];
            }
            else
            {
                MFMailComposeViewController *email = [[MFMailComposeViewController alloc] init];
                email.mailComposeDelegate = self;
                [email setSubject:@"ChatSecure"];
                [email setMessageBody:[self shareString] isHTML:NO];
                email.modalPresentationStyle = UIModalPresentationFormSheet;
                
                [self presentModalViewController:email animated:YES];
            }
        }
        else if (buttonIndex == 2) // QR code
        {
            OTRQRCodeViewController *qrCode = [[OTRQRCodeViewController alloc] init];
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:qrCode];
            nav.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentModalViewController:nav animated:YES];
        } else if (buttonIndex == [[self buttonTitlesForShareButton] count] - 2 && [[[UIDevice currentDevice] systemVersion] floatValue] >= 5.0)
        {
            TWTweetComposeViewController *tweetSheet =
            [[TWTweetComposeViewController alloc] init];
            [tweetSheet setInitialText:[self twitterShareString]];
            [self presentModalViewController:tweetSheet animated:YES];
        }
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([request.URL.absoluteString isEqualToString:@"file:///"]) {
        return YES;
    }
    if ([[UIApplication sharedApplication] canOpenURL:request.URL])
    {
        self.lastActionLink = request.URL;
        UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:[[request.URL absoluteURL] description] delegate:self cancelButtonTitle:CANCEL_STRING destructiveButtonTitle:nil otherButtonTitles:OPEN_IN_SAFARI_STRING, nil];
        action.tag = ACTIONSHEET_LINK_TAG;
        [OTR_APP_DELEGATE presentActionSheet:action inView:self.view];
    }
    return NO;
}

#pragma mark MFMessageComposeViewControllerDelegate methods

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark MFMailComposeViewControllerDelegate Methods

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissModalViewControllerAnimated:YES];
}

@end
