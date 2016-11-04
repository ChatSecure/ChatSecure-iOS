//
//  OTRCertificatesViewController.h
//  Off the Record
//
//  Created by David Chiles on 12/9/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

@import UIKit;

@interface OTRCertificatesViewController : UITableViewController


- (id)initWithHostName:(NSString *)hostname withCertificates:(NSArray *)certificates;

@property (nonatomic) BOOL canEdit;

@end
