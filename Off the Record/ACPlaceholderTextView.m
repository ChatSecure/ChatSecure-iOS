#import <QuartzCore/QuartzCore.h>
#import "ACPlaceholderTextView.h"

@implementation ACPlaceholderTextView {
    BOOL shouldDrawPlaceholder;
}

#pragma mark - Properties

@synthesize placeholder;

- (void)setPlaceholder:(NSString *)string {
    if (![string isEqualToString:placeholder]) {
        placeholder = string;
        [self updateShouldDrawPlaceholder];
    }
}

- (void)setText:(NSString *)text {
    super.text = text;
    [self updateShouldDrawPlaceholder];
}

#pragma mark - NSObject

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]
     removeObserver:self name:UITextViewTextDidChangeNotification object:self];
}

#pragma mark - UIView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [[NSNotificationCenter defaultCenter]
         addObserver:self selector:@selector(textViewDidChange)
         name:UITextViewTextDidChangeNotification object:self];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];

    if (shouldDrawPlaceholder) {
        [[UIColor colorWithWhite:0.702f alpha:1.0f] set]; // was [UIColor lightGrayColor]
        [placeholder drawInRect:CGRectMake(8.0f, 8.5f, self.frame.size.width-16.0f,
                                           self.frame.size.height-16.0f) withFont:self.font];
    }
}

#pragma mark - UITextViewTextDidChangeNotification

- (void)updateShouldDrawPlaceholder {
    BOOL prev = shouldDrawPlaceholder;
    BOOL isAnimating = [[self.superview.layer animationKeys] count] != 0;
    shouldDrawPlaceholder = placeholder && ![self hasText] && !isAnimating;

    if (prev != shouldDrawPlaceholder) { // !animating
        [self setNeedsDisplay];
    }
}

- (void)textViewDidChange {
    [self updateShouldDrawPlaceholder];
}

@end
