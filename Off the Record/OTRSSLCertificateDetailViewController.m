//
//  OTRSSLCertificateDetailViewController.m
//  Off the Record
//
//  Created by David Chiles on 2/18/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRSSLCertificateDetailViewController.h"

#import "OTRSSLCertificate.h"

@interface OTRSSLCertificateDetailViewController ()

@property (nonatomic, strong) OTRSSLCertificate * sslCertificate;
@property (nonatomic, strong) NSDateFormatter * dateFormatter;

@end

@implementation OTRSSLCertificateDetailViewController

- (id)initWithSSLCertificate:(OTRSSLCertificate *)sslCertificate
{
    if (self = [self initWithStyle:UITableViewStylePlain]) {
        self.sslCertificate = sslCertificate;
        self.dateFormatter = [[NSDateFormatter alloc] init];
        self.dateFormatter.timeStyle = NSDateFormatterMediumStyle;
        self.dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.title = self.sslCertificate.subjectCommonName;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0 || section == 1) {
        return 2;
    }
    return 5;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return @"Subject Name";
    }
    else if (section == 1) {
        return  @"Issuer Name";
    }
    else if (section == 2) {
        return @"Other";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    NSString * textLabelText = nil;
    NSString * detailLableText = nil;
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            textLabelText = @"Orginization Name";
            detailLableText = self.sslCertificate.subjectOrganization;
        }
        else if (indexPath.row == 1) {
            textLabelText = @"Common Name";
            detailLableText = self.sslCertificate.subjectCommonName;
        }
    }
    else if (indexPath.section == 1){
        if (indexPath.row == 0) {
            textLabelText = @"Orginization Name";
            detailLableText = self.sslCertificate.issuerOrganization;
        }
        else if (indexPath.row == 1) {
            textLabelText = @"Common Name";
            detailLableText = self.sslCertificate.issuerCommonName;
        }
    }
    else if (indexPath.section == 2){
        if (indexPath.row == 0) {
            textLabelText = @"Start Date";
            detailLableText = [self.dateFormatter stringFromDate:self.sslCertificate.notValidBefore];
        }
        else if (indexPath.row == 1) {
            textLabelText = @"Expiration Date";
            detailLableText = [self.dateFormatter stringFromDate:self.sslCertificate.notValidAfter];

        }
        else if (indexPath.row == 2) {
            textLabelText = @"Serial Number";
            detailLableText = [self.sslCertificate.serialNumber stringByReplacingOccurrencesOfString:@" " withString:@":"];
        }
        else if (indexPath.row == 3) {
            textLabelText = @"Version";
            detailLableText = [NSString stringWithFormat:@"%d",[self.sslCertificate.version intValue]];
        }
        else if (indexPath.row == 4) {
            textLabelText = @"SHA1 Fingerprint";
            detailLableText = [self.sslCertificate.SHA1fingerprint stringByReplacingOccurrencesOfString:@" " withString:@":"];
        }
    }
    
    cell.textLabel.text = textLabelText;
    cell.detailTextLabel.text = detailLableText;
    
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

@end
