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
#import "OTRConstants.h"
#import "OTRAppDelegate.h"
#import "PureLayout.h"
#import "TTTAttributedLabel.h"
#import "OTRSocialButtonsView.h"
#import "OTRAcknowledgementsViewController.h"
#import "NSURL+chatsecure.h"
#import "Strings.h"
#import "OTRUtilities.h"
#import "UIActionSheet+ChatSecure.h"
#import "UIActivityViewController+ChatSecure.h"

static NSString *const kDefaultCellReuseIdentifier = @"kDefaultCellReuseIdentifier";

@interface OTRAboutTableCellData : NSObject
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSURL *url;
+ (instancetype) cellDataWithTitle:(NSString*)title url:(NSURL*)url;
@end
@implementation OTRAboutTableCellData
+ (instancetype) cellDataWithTitle:(NSString *)title url:(NSURL *)url {
    OTRAboutTableCellData *cellData = [[OTRAboutTableCellData alloc] init];
    cellData.title = title;
    cellData.url = url;
    return cellData;
}
@end

@interface OTRAboutViewController() <TTTAttributedLabelDelegate, OTRSocialButtonsViewDelegate>

@property (nonatomic, strong) UIView *socialView;
@property (nonatomic, strong) TTTAttributedLabel *headerLabel;
@property (nonatomic, strong) OTRSocialButtonsView *socialButtonsView;
@property (nonatomic, strong) NSArray *cellData;
@property (nonatomic) BOOL hasAddedConstraints;
@end

@implementation OTRAboutViewController

- (id)init {
    if (self = [super init]) {
        self.title = ABOUT_STRING;
        self.hasAddedConstraints = NO;
    }
    return self;
}

#pragma mark - View lifecycle

- (void) setupVersionLabel {
    self.versionLabel = [[UILabel alloc] init];
    NSString *version = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleName"];
    self.versionLabel.text = [NSString stringWithFormat:@"%@ %@", VERSION_STRING, version];
    self.versionLabel.textAlignment = NSTextAlignmentCenter;
    self.versionLabel.frame = CGRectMake(0, 0, self.view.frame.size.width, 30);
}

- (void) setupImageView {
    self.imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chatsecure_logo_transparent"]];
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapImageView:)];
    [self.imageView addGestureRecognizer:tapGestureRecognizer];
    
    [self.view addSubview:self.imageView];
}

- (void) setupSocialView {
    self.socialView = [[UIView alloc] initForAutoLayout];
    
    CGFloat labelMargin = 10;
    self.headerLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
    NSString *chrisballingerString = @"@chrisballinger";
    NSURL *chrisballingerURL = [NSURL URLWithString:@"https://github.com/chrisballinger"];
    NSString *davidchilesString = @"@davidchiles";
    NSURL *davidChilesURL = [NSURL URLWithString:@"https://github.com/davidchiles"];
    NSString *headerText = [NSString stringWithFormat:@"%@ %@ & %@.", CREATED_BY_STRING, chrisballingerString, davidchilesString];
    NSRange chrisRange = [headerText rangeOfString:chrisballingerString];
    NSRange davidRange = [headerText rangeOfString:davidchilesString];
    
    UIFont *font = [UIFont systemFontOfSize:12];
    CGFloat labelWidth = CGRectGetWidth(self.view.frame) - 2 * labelMargin;;
    CGFloat labelHeight;
    
    NSStringDrawingOptions options = (NSLineBreakByWordWrapping | NSStringDrawingUsesLineFragmentOrigin);
    CGRect labelBounds = [headerText boundingRectWithSize:CGSizeMake(labelWidth, CGFLOAT_MAX)
                                                  options:options
                                               attributes:@{NSFontAttributeName: font}
                                                  context:nil];
    labelHeight = CGRectGetHeight(labelBounds) + 5; // emoji hearts are big
    
    CGRect labelFrame = CGRectMake(labelMargin, labelMargin*2, labelWidth, labelHeight);
    
    NSDictionary *linkAttributes = @{(NSString*)kCTForegroundColorAttributeName:(id)[[UIColor blackColor] CGColor],
                                     (NSString *)kCTUnderlineStyleAttributeName: @NO};
    self.headerLabel.linkAttributes = linkAttributes;
    
    self.headerLabel.frame = labelFrame;
    self.headerLabel.font             = font;
    self.headerLabel.textColor        = [UIColor grayColor];
    self.headerLabel.backgroundColor  = [UIColor clearColor];
    self.headerLabel.numberOfLines    = 0;
    self.headerLabel.textAlignment    = NSTextAlignmentCenter;
    self.headerLabel.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin);
    self.headerLabel.text = headerText;
    self.headerLabel.delegate = self;
    
    [self.headerLabel addLinkToURL:chrisballingerURL withRange:chrisRange];
    [self.headerLabel addLinkToURL:davidChilesURL withRange:davidRange];
    
    self.socialButtonsView = [[OTRSocialButtonsView alloc] initWithFrame:CGRectZero];
    self.socialButtonsView.delegate = self;
    [self.socialView addSubview:self.socialButtonsView];
    [self.socialView addSubview:self.headerLabel];
    [self.view addSubview:self.socialView];
    
}

- (void) setupTableView {
    self.aboutTableView = [[UITableView alloc] initForAutoLayout];
    self.aboutTableView.delegate = self;
    self.aboutTableView.dataSource = self;
    [self.aboutTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kDefaultCellReuseIdentifier];
    self.aboutTableView.scrollEnabled = NO;
    
    [self.view addSubview:self.aboutTableView];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Fixes frame problems on iOS 7
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        [self.navigationController.view setBackgroundColor:[UIColor whiteColor]];
    }
    OTRAboutTableCellData *translateData = [OTRAboutTableCellData cellDataWithTitle:HELP_TRANSLATE_STRING url:[NSURL otr_transifexURL]];
    OTRAboutTableCellData *aboutThisVersion = [OTRAboutTableCellData cellDataWithTitle:ABOUT_VERSION_STRING url:nil];
    self.cellData = @[aboutThisVersion,translateData];
    self.view.backgroundColor = [UIColor whiteColor];
    
    
    if ([self isModal]) {
        UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
        
        self.navigationItem.rightBarButtonItem = doneBarButtonItem;
    }
    
    [self setupVersionLabel];
    [self setupImageView];
    [self setupSocialView];
    [self setupTableView];
    [self.view setNeedsUpdateConstraints];
}

- (void) updateViewConstraints {

    if (!self.hasAddedConstraints) {
        CGFloat padding = 10.0f;
        [self.imageView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [self.imageView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(padding, padding, padding, padding) excludingEdge:ALEdgeBottom];
        [self.imageView autoSetDimension:ALDimensionHeight toSize:100.0];
        
        [self.socialView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [self.socialView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.imageView withOffset:padding];
        
        [self.headerLabel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
        [self.headerLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
        
        [self.socialButtonsView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(padding, padding, padding, padding) excludingEdge:ALEdgeTop];
        [self.socialButtonsView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [self.socialButtonsView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.headerLabel withOffset:padding];
        
        [self.aboutTableView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:0];
        [self.aboutTableView autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:0];
        [self.aboutTableView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0];
        [self.aboutTableView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.socialView];
        
        self.hasAddedConstraints = YES;
    }
    [super updateViewConstraints];
    
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

 #pragma - mark Utilitie Methods

- (BOOL)isModal {
    return self.presentingViewController.presentedViewController == self || self.navigationController.presentingViewController.presentedViewController == self.navigationController || [self.tabBarController.presentingViewController isKindOfClass:[UITabBarController class]];
}

#pragma - mark Tap Methods

- (void)doneButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didTapImageView:(id)sender
{
    [self handleOpeningURLArray:@[[NSURL otr_projectURL]] fromView:self.imageView];
}

- (void)handleOpeningURLArray:(NSArray *)urlArray fromView:(UIView *)view
{
    UIActivityViewController *activityViewController = [UIActivityViewController otr_linkActivityViewControllerWithURLs:urlArray];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        activityViewController.popoverPresentationController.sourceView = view;
        activityViewController.popoverPresentationController.sourceRect = view.bounds;
    }
    
    [self presentViewController:activityViewController animated:YES completion:nil];
}

#pragma - mark UItableView Delegate & Datasource

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _cellData.count;
}

- (UIView*) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return self.versionLabel;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return self.versionLabel.frame.size.height;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kDefaultCellReuseIdentifier forIndexPath:indexPath];
    OTRAboutTableCellData *cellData = [self.cellData objectAtIndex:indexPath.row];
    cell.textLabel.text = cellData.title;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        OTRAcknowledgementsViewController *viewController = [OTRAcknowledgementsViewController defaultAcknowledgementViewController];
        viewController.headerLabel.delegate = self;
        [self.navigationController pushViewController:viewController animated:YES];
    } else {
        OTRAboutTableCellData *cellData = [self.cellData objectAtIndex:indexPath.row];
        NSURL *url = cellData.url;
        [self handleOpeningURLArray:@[url] fromView:[tableView cellForRowAtIndexPath:indexPath]];
    }
    
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma - mark OTRSocialButtonsViewDelegate Methods

- (void)socialButton:(UIButton *)button openURLs:(NSArray *)urlArray
{
    [self handleOpeningURLArray:urlArray fromView:button];
}

#pragma - mark TTTatributedLabelDelegate Methods

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    [self handleOpeningURLArray:@[url] fromView:label];
}

@end
