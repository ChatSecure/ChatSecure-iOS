//
//  BlankChatViewController.m
//  Off the Record
//
//  Created by Chris Ballinger on 3/24/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRBlankChatViewController.h"

#define LABEL_WIDTH 400
#define LABEL_HEIGHT 100

@implementation OTRBlankChatViewController
@synthesize instructionsLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Chat";
    }
    return self;
}

- (void) loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor whiteColor];
    self.instructionsLabel = [[UILabel alloc] init];
    instructionsLabel.text = @"Go to the Accounts tab to log in, then select\n a buddy from the Buddy List to start chatting.";
    instructionsLabel.numberOfLines = 2;
    instructionsLabel.textAlignment = UITextAlignmentCenter;
    instructionsLabel.autoresizingMask =  UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
    [self.view addSubview:instructionsLabel];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    instructionsLabel.frame = CGRectMake(self.view.frame.size.width/2-LABEL_WIDTH/2, self.view.frame.size.height/2-LABEL_HEIGHT/2, LABEL_WIDTH, LABEL_HEIGHT);
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.instructionsLabel = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}


//detailedView delegate methods
- (void)splitViewController:(UISplitViewController*)svc 
     willHideViewController:(UIViewController *)aViewController 
          withBarButtonItem:(UIBarButtonItem*)barButtonItem 
       forPopoverController:(UIPopoverController*)pc
{  
    [barButtonItem setTitle:@"Buddy List"];
    
    
    
    self.navigationItem.leftBarButtonItem = barButtonItem;
}


- (void)splitViewController:(UISplitViewController*)svc 
     willShowViewController:(UIViewController *)aViewController 
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    self.navigationItem.leftBarButtonItem = nil;
}


@end
