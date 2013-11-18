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
#import "OTRAppDelegate.h"

#define ACTIONSHEET_SHARE_TAG 2
#define ACTIONSHEET_LINK_TAG 1

@interface OTRAboutViewController(Private)
- (NSArray*) buttonTitlesForShareButton;
@end

@implementation OTRAboutViewController
@synthesize versionLabel, aboutTextView,lastActionLink, imageView;
@synthesize scrollView;


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
    

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    // Do any additional setup after loading the view from its nib.
    NSString *aboutString = [NSString stringWithFormat:@"%@: libotr, libgcrypt, libgpg-error, LibOrange, XMPPFramework, MBProgressHUD, Appirater, SSKeychain, Crittercism, UserVoice.<br><a href=\"https://chatsecure.org/\">%@</a><br><a href=\"https://github.com/chrisballinger/Off-the-Record-iOS\">%@</a><br><a href=\"https://www.transifex.com/projects/p/chatsecure\">%@</a>", ATTRIBUTION_STRING, PROJECT_HOMEPAGE_STRING, SOURCE_STRING, CONTRIBUTE_TRANSLATION_STRING];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    aboutTextView = [[UIWebView alloc] init];
	aboutTextView.delegate = self;
    [aboutTextView loadHTMLString:aboutString baseURL:[NSURL URLWithString:@"/"]];
    
    aboutTextView.userInteractionEnabled = YES;
    if([aboutTextView respondsToSelector:@selector(scrollView)]) {
        aboutTextView.scrollView.scrollEnabled = NO;
    }

    NSString *version = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"];
    versionLabel.text = [NSString stringWithFormat:@"%@ %@", VERSION_STRING, version];
    
    [scrollView addSubview:aboutTextView];
    [scrollView addSubview:imageView];
    [scrollView addSubview:versionLabel];
    
    [self.view addSubview:scrollView];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    CGFloat imageViewFrameWidth = imageView.image.size.width;
    CGFloat imageViewFrameHeight = imageView.image.size.height;
    imageView.frame = CGRectMake(self.view.frame.size.width/2 - imageViewFrameWidth/2, 20, imageViewFrameWidth, imageViewFrameHeight);
    imageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    
    CGSize versionLabelSize = [[versionLabel text]sizeWithFont:[versionLabel font]];
    versionLabel.frame = CGRectMake(floorf(self.view.frame.size.width/2 - versionLabelSize.width/2), self.view.frame.size.height-versionLabelSize.height-20, versionLabelSize.width, versionLabelSize.height);
    versionLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    
    CGFloat aboutTextViewFrameWidth = self.view.frame.size.width-40;
    CGFloat aboutTextViewFrameYOrigin = imageView.frame.origin.y + imageViewFrameHeight + 10;
    aboutTextView.frame = CGRectMake(self.view.frame.size.width/2-aboutTextViewFrameWidth/2, aboutTextViewFrameYOrigin, aboutTextViewFrameWidth, versionLabel.frame.origin.y - aboutTextViewFrameYOrigin);
    aboutTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
    
    scrollView.contentSize = CGSizeMake(self.view.frame.size.width, versionLabel.frame.origin.y+versionLabelSize.height);
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

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == ACTIONSHEET_LINK_TAG) {
        if (buttonIndex != actionSheet.cancelButtonIndex)
        {
            [[UIApplication sharedApplication] openURL:[lastActionLink absoluteURL]];
        }
    }
}

@end
