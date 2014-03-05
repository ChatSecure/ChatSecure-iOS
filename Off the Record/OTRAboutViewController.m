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
#import "UIActionSheet+Blocks.h"

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

@interface OTRAboutViewController()
@property (nonatomic, strong) NSArray *cellData;
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
    NSString *version = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"];
    self.versionLabel.text = [NSString stringWithFormat:@"%@ %@", VERSION_STRING, version];
    self.versionLabel.textAlignment = NSTextAlignmentCenter;
    self.versionLabel.frame = CGRectMake(0, 0, self.view.frame.size.width, 30);
}

- (void) setupImageView {
    self.imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chatsecure_banner.png"]];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
    [self.view addSubview:self.imageView];
}

- (void) setupTableView {
    self.aboutTableView = [[UITableView alloc] init];
    self.aboutTableView.delegate = self;
    self.aboutTableView.dataSource = self;
    [self.aboutTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kDefaultCellReuseIdentifier];
    self.aboutTableView.scrollEnabled = NO;
    self.aboutTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    
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
    OTRAboutTableCellData *homepageData = [OTRAboutTableCellData cellDataWithTitle:PROJECT_HOMEPAGE_STRING url:[NSURL URLWithString:@"https://chatsecure.org"]];
    OTRAboutTableCellData *sourceData = [OTRAboutTableCellData cellDataWithTitle:SOURCE_STRING url:[NSURL URLWithString:@"https://github.com/chrisballinger/Off-the-Record-iOS"]];
    OTRAboutTableCellData *translateData = [OTRAboutTableCellData cellDataWithTitle:CONTRIBUTE_TRANSLATION_STRING url:[NSURL URLWithString:@"https://www.transifex.com/projects/p/chatsecure"]];
    self.cellData = @[homepageData, sourceData, translateData];
    self.view.backgroundColor = [UIColor whiteColor];

    
    [self setupVersionLabel];
    [self setupImageView];
    [self setupTableView];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    CGFloat padding = 10.0f;
    self.imageView.frame = CGRectMake(padding, padding, self.view.frame.size.width - padding*2, 100);
    self.aboutTableView.frame = CGRectMake(0, self.imageView.frame.origin.y + self.imageView.frame.size.height + padding, self.view.frame.size.width, self.view.frame.size.height - self.imageView.frame.size.height - padding * 2);
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
    OTRAboutTableCellData *cellData = [self.cellData objectAtIndex:indexPath.row];
    NSURL *url = cellData.url;
    RIButtonItem *cancelButton = [RIButtonItem itemWithLabel:CANCEL_STRING];
    RIButtonItem *safariButton = [RIButtonItem itemWithLabel:OPEN_IN_SAFARI_STRING action:^{
        [[UIApplication sharedApplication] openURL:url];
    }];
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:url.absoluteString cancelButtonItem:cancelButton destructiveButtonItem:nil otherButtonItems:safariButton, nil];
    [OTR_APP_DELEGATE presentActionSheet:actionSheet inView:self.view];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
