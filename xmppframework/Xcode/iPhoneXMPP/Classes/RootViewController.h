#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "ChatWindowManager.h"


@interface RootViewController : UITableViewController <NSFetchedResultsControllerDelegate>
{
	NSFetchedResultsController *fetchedResultsController;
    ChatWindowManager *chatManager;
}

- (IBAction)settings:(id)sender;

@end
