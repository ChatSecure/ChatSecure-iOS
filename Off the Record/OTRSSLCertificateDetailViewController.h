//
//  OTRSSLCertificateDetailViewController.h
//  Off the Record
//
//  Created by David Chiles on 2/18/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OTRSSLCertificate;

@interface OTRSSLCertificateDetailViewController : UITableViewController

- (id)initWithSSLCertificate:(OTRSSLCertificate *)sslCertificate;

@end
