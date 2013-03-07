//
//  OTRBuddyViewController.m
//  Off the Record
//
//  Created by David on 3/6/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRBuddyViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "OTRSafariActionSheet.h"

@interface OTRBuddyViewController ()

@end

@implementation OTRBuddyViewController

@synthesize buddy;


-(id)initWithBuddyID:(NSManagedObjectID *)buddyID
{
    if(self = [self init])
    {
        self.buddy = (OTRManagedBuddy *)[[NSManagedObjectContext MR_contextForCurrentThread] existingObjectWithID:buddyID error:nil];
        self.title = @"Buddy Info";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
    
    self.view.backgroundColor = [UIColor darkGrayColor];
    
    UIImageView * buddyImageView = [[UIImageView alloc] initWithFrame:CGRectMake(15.0, 15.0, 50.0, 50.0)];
    buddyImageView.backgroundColor = [UIColor lightGrayColor];
    
    if (self.buddy.photo) {
        UIImage * image = self.buddy.photo;
        CGSize size = image.size;
        buddyImageView.image = buddy.photo;
    }
    else
    {
        buddyImageView.image = [UIImage imageNamed:@"person"];
    }
    [buddyImageView.layer setCornerRadius:10.0];
    buddyImageView.layer.masksToBounds = YES;
    
    [self.view addSubview:buddyImageView];
    
    
    
    UILabel * nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    nameLabel.font = [UIFont boldSystemFontOfSize:18];
    nameLabel.numberOfLines = 0;
    //nameLabel.lineBreakMode = UILineBreakModeWordWrap;
    nameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    nameLabel.backgroundColor = [UIColor clearColor];
    nameLabel.shadowOffset = CGSizeMake(1, 1);
    nameLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:nameLabel];
    if([buddy.displayName length])
    {
        nameLabel.text = buddy.displayName;
    }
    else{
        nameLabel.text = buddy.accountName;
    }
    
    [nameLabel sizeToFit];
    
    CGFloat xPos = buddyImageView.frame.size.width + buddyImageView.frame.origin.x + 10;
    
    CGRect tempFrame = nameLabel.frame;
    tempFrame.size.width = self.view.frame.size.width -xPos;
    tempFrame.origin = CGPointMake(xPos, 15.0);
    nameLabel.frame = tempFrame;
    
    
    
    TTTAttributedLabel * statusMessageLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
    NSMutableDictionary *mutableLinkAttributes = [NSMutableDictionary dictionary];
    [mutableLinkAttributes setObject:(id)[statusMessageLabel.textColor CGColor] forKey:(NSString*)kCTForegroundColorAttributeName];
    [mutableLinkAttributes setObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCTUnderlineStyleAttributeName];
    statusMessageLabel.linkAttributes = mutableLinkAttributes;
    statusMessageLabel.delegate = self;
    statusMessageLabel.dataDetectorTypes = UIDataDetectorTypeLink;
    statusMessageLabel.numberOfLines = 0;
    statusMessageLabel.lineBreakMode = UILineBreakModeWordWrap;
    statusMessageLabel.backgroundColor = [UIColor clearColor];
    statusMessageLabel.shadowOffset = CGSizeMake(1, 1);
    statusMessageLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:statusMessageLabel];
    statusMessageLabel.text = self.buddy.currentStatusMessage.message;
    
    [statusMessageLabel sizeToFit];
    
    
    
    tempFrame = statusMessageLabel.frame;
    tempFrame.size.width = self.view.frame.size.width -xPos;
    tempFrame.origin = CGPointMake(xPos, nameLabel.frame.origin.y+nameLabel.frame.size.height+5.0);
    statusMessageLabel.frame = tempFrame;
    

}

-(void)doneButtonPressed:(id)sender
{
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

-(void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    OTRSafariActionSheet * actionSheet = [[OTRSafariActionSheet alloc] initWithUrl:url];
    [actionSheet showInView:self.view];
}

@end
