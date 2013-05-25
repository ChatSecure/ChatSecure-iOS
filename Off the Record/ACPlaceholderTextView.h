#import <UIKit/UIKit.h>

@interface ACPlaceholderTextView : UITextView

@property (strong, nonatomic) NSString *placeholder;

- (void)updateShouldDrawPlaceholder;

@end
