//
//  OTRAcknowledgementViewController.m
//  ChatSecure
//
//  Created by David Chiles on 9/5/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRAcknowledgementsViewController.h"
#import "TTTAttributedLabel.h"
#import "OTRKit.h"
#import "OTRTorManager.h"
#import "PureLayout.h"

@interface VTAcknowledgementsViewController()
// private methods from superclass
+ (NSString *)defaultAcknowledgementsPlistPath;
- (void)configureHeaderView;
@end

@interface OTRAcknowledgementsViewController ()

@property (nonatomic, strong) TTTAttributedLabel *headerLabel;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic) BOOL hasAddedConstraints;

@end

@implementation OTRAcknowledgementsViewController

- (instancetype) initWithHeaderLabel:(TTTAttributedLabel*)headerLabel {
    if (self = [super initWithAcknowledgementsPlistPath:[[self class] defaultAcknowledgementsPlistPath]]) {
        self.headerText = headerLabel.text;
        self.headerLabel = headerLabel;
        self.headerLabel.delegate = self;
        [self setupHeaderView];
    }
    return self;
}

- (void) setupHeaderView {
    CGRect headerFrame = CGRectMake(0, 0, 300, 150);
    self.headerView = [[UIView alloc] initWithFrame:headerFrame];
    [self.headerView addSubview:self.headerLabel];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateViewConstraints];
}

- (void) updateViewConstraints {
    
    if (!self.hasAddedConstraints) {
        [self.headerLabel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
        [self.headerLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
        self.hasAddedConstraints = YES;
    }
    [super updateViewConstraints];
}

// Overriding private method
- (void)configureHeaderView {
    self.tableView.tableHeaderView = self.headerView;
}

- (void)attributedLabel:(TTTAttributedLabel *)label
   didSelectLinkWithURL:(NSURL *)url {
    [[UIApplication sharedApplication] openURL:url];
}



+ (instancetype)defaultAcknowledgementViewController
{
    TTTAttributedLabel *headerLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
    
    NSString *libotrString = @"libotr";
    NSString *libgpgErrorString = @"libgpg-error";
    NSString *libgcryptString = @"libgcrypt";
    NSString *torString = @"tor";
    NSString *openSSLString = @"OpenSSL";
    NSString *libEventString =@"libevent";
    
    NSString *libEventVersionString = [CPAProxyManager libeventVersion];
    NSString *torVersionString = [CPAProxyManager torVersion];
    NSString *openSSLVersionString = [CPAProxyManager opensslVersion];
    openSSLVersionString = [[openSSLVersionString stringByReplacingOccurrencesOfString:openSSLString withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    
    NSString *libgcryptVersionString = [OTRKit libgcryptVersion];
    NSString *libgpgErrorVersionString = [OTRKit libgpgErrorVersion];
    NSString *libotrVersionString = [OTRKit libotrVersion];
    
    
    
    NSString *headerText = [NSString stringWithFormat:@"%@ - %@\n%@ - %@\n%@ - %@\n%@ - %@\n%@ - %@\n%@ - %@",libotrString,libotrVersionString,libgpgErrorString,libgpgErrorVersionString,libgcryptString,libgcryptVersionString,torString,torVersionString,openSSLString,openSSLVersionString,libEventString,libEventVersionString];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:headerText];
    
    [attributedString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]] range:[headerText rangeOfString:libotrString]];
    
    headerLabel.numberOfLines = 0;
    headerLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    [headerLabel setText:headerText afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
        [mutableAttributedString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:17.0] range:[headerText rangeOfString:libotrString]];
        [mutableAttributedString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:17.0] range:[headerText rangeOfString:libgpgErrorString]];
        [mutableAttributedString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:17.0] range:[headerText rangeOfString:libgcryptString]];
        [mutableAttributedString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:17.0] range:[headerText rangeOfString:torString]];
        [mutableAttributedString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:17.0] range:[headerText rangeOfString:openSSLString]];
        [mutableAttributedString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:17.0] range:[headerText rangeOfString:libEventString]];
        
        return mutableAttributedString;
    }];
    
    return [[self alloc] initWithHeaderLabel:headerLabel];
}

@end
