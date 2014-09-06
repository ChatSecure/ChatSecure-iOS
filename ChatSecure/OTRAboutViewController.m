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
#import "UIActionSheet+Blocks.h"
#import "OTRAppDelegate.h"
#import "PureLayout.h"
#import "TTTAttributedLabel.h"
#import "OTRSocialButtonsView.h"
#import "OTRAcknowledgementsViewController.h"
#import "OTRSafariActionSheet.h"

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

@interface OTRAboutViewController() <TTTAttributedLabelDelegate>

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
    }
    return self;
}

#pragma mark - View lifecycle

- (void) setupVersionLabel {
    self.versionLabel = [[UILabel alloc] init];
    NSString *version = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
    self.versionLabel.text = [NSString stringWithFormat:@"%@ %@", VERSION_STRING, version];
    self.versionLabel.textAlignment = NSTextAlignmentCenter;
    self.versionLabel.frame = CGRectMake(0, 0, self.view.frame.size.width, 30);
}

- (void) setupImageView {
    self.imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chatsecure_banner.png"]];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
    self.imageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapImageView:)];
    [self.imageView addGestureRecognizer:tapGestureRecognizer];
    
    [self.view addSubview:self.imageView];
}

- (void) setupSocialView {
    self.socialView = [[UIView alloc] initForAutoLayout];
    
    CGFloat labelMargin = 10;
    self.headerLabel = [[TTTAttributedLabel alloc] init];
    NSString *chrisballingerString = @"@chrisballinger";
    NSURL *chrisballingerURL = [NSURL URLWithString:@"https://github.com/chrisballinger"];
    NSString *davidchilesString = @"@davidchiles";
    NSURL *davidChilesURL = [NSURL URLWithString:@"https://github.com/davidchiles"];
    NSString *headerText = [NSString stringWithFormat:@"Created by %@ & %@.", chrisballingerString, davidchilesString];
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
    OTRAboutTableCellData *translateData = [OTRAboutTableCellData cellDataWithTitle:@"Help Translate" url:[NSURL URLWithString:@"https://www.transifex.com/projects/p/chatsecure"]];
    OTRAboutTableCellData *aboutThisVersion = [OTRAboutTableCellData cellDataWithTitle:@"About This Version" url:nil];
    self.cellData = @[aboutThisVersion,translateData];
    self.view.backgroundColor = [UIColor whiteColor];

    
    [self setupVersionLabel];
    [self setupImageView];
    [self setupSocialView];
    [self setupTableView];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    CGFloat padding = 10.0f;
    self.imageView.frame = CGRectMake(padding, padding, self.view.frame.size.width - padding*2, 100);
}

- (void) updateViewConstraints {
    [super updateViewConstraints];
    if (self.hasAddedConstraints) {
        return;
    }
    CGFloat padding = 10.0f;
    [self.socialView autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.socialView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.imageView withOffset:padding];
    [self.socialButtonsView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, padding, padding, padding) excludingEdge:ALEdgeTop];
    [self.socialButtonsView autoSetDimension:ALDimensionHeight toSize:45];
    [self.socialButtonsView autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.headerLabel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
    [self.headerLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.socialButtonsView];
    [self.headerLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
    
    [self.aboutTableView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.view];
    [self.aboutTableView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.view];
    [self.aboutTableView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.socialView];
    [self.aboutTableView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.view];
    
    self.hasAddedConstraints = YES;
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

- (void)didTapImageView:(id)sender
{
    [self handleOpeningURL:[NSURL URLWithString:@"https://chatsecure.org"]];
}

- (void)handleOpeningURL:(NSURL *)url
{
    OTRSafariActionSheet *safariActionSheet = [[OTRSafariActionSheet alloc] initWithUrl:url];
    [OTRAppDelegate presentActionSheet:safariActionSheet inView:self.view];
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
        [self handleOpeningURL:url];
    }
    
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma - mark TTTatributedLabelDelegate Methods

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    [self handleOpeningURL:url];
}

@end
