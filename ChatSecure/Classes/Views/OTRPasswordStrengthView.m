//
//  OTRPasswordStrengthTextField.m
//  Off the Record
//
//  Created by David Chiles on 5/1/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRPasswordStrengthView.h"
@import PureLayout;

@interface OTRPasswordStrengthView ()

@property (nonatomic, strong) UIProgressView *passwordStrengthMeterView;
@property (nonatomic, strong) NJOPasswordValidator *validator;
@property (nonatomic) BOOL addedContraints;

@property (nonatomic, weak) id UITextFieldTextDidChangeNotificationObject;

@end

@implementation OTRPasswordStrengthView

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self.UITextFieldTextDidChangeNotificationObject];
}

- (id)initWithRules:(NSArray *)rules
{
    if (self = [self initWithFrame:CGRectZero]) {
        self.validator = [NJOPasswordValidator validatorWithRules:rules];
        self.addedContraints = NO;
    }
    return self;
}

- (id)initWithDefaultRules
{
    if (self = [self initWithFrame:CGRectZero]) {
        self.validator = [NJOPasswordValidator standardValidator];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.passwordStrengthMeterView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        self.passwordStrengthMeterView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self addSubview:self.passwordStrengthMeterView];
        
        self.textField = [[UITextField alloc] initWithFrame:CGRectZero];
        self.textField.secureTextEntry = YES;
        self.textField.translatesAutoresizingMaskIntoConstraints = NO;
        self.textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        
        [self addSubview:self.textField];
        
        __weak OTRPasswordStrengthView *welf = self;
        self.UITextFieldTextDidChangeNotificationObject = [[NSNotificationCenter defaultCenter] addObserverForName:UITextFieldTextDidChangeNotification object:self.textField queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            [welf updatePasswordStrength:note.object];
        }];
        
        [self updatePasswordStrength:self];
    }
    return self;
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(self.passwordStrengthMeterView.frame.size.width, self.passwordStrengthMeterView.frame.size.height+self.textField.frame.size.height+2);
}

- (void)updatePasswordStrength:(id)sender
{
    NSString *password = self.textField.text;
    NJOPasswordStrength strength = [NJOPasswordStrengthEvaluator strengthOfPassword:password];
    
    
    NSArray *failingRules = nil;
    if ([self.validator validatePassword:password failingRules:&failingRules]) {
        switch (strength) {
                
            case NJOVeryWeakPasswordStrength:
                self.passwordStrengthMeterView.progress = 0.05f;
                self.passwordStrengthMeterView.tintColor = [UIColor redColor];
                break;
            case NJOWeakPasswordStrength:
                self.passwordStrengthMeterView.progress = 0.25f;
                self.passwordStrengthMeterView.tintColor = [UIColor orangeColor];
                break;
            case NJOReasonablePasswordStrength:
                self.passwordStrengthMeterView.progress = 0.5f;
                self.passwordStrengthMeterView.tintColor = [UIColor yellowColor];
                break;
            case NJOStrongPasswordStrength:
                self.passwordStrengthMeterView.progress = 0.75f;
                self.passwordStrengthMeterView.tintColor = [UIColor greenColor];
                break;
            case NJOVeryStrongPasswordStrength:
                self.passwordStrengthMeterView.progress = 1.0f;
                self.passwordStrengthMeterView.tintColor = [UIColor cyanColor];
                break;
        }
    }
    else {
        self.passwordStrengthMeterView.progress = 0.0f;
        self.passwordStrengthMeterView.tintColor = [UIColor redColor];
    }
    
    if ([password length] == 0) {
        self.passwordStrengthMeterView.progress = 0.0f;
    }
    
    if ([self.delegate respondsToSelector:@selector(passwordView:didChangePassword:strength:failingRules:)]) {
        [self.delegate passwordView:self didChangePassword:password strength:strength failingRules:failingRules];
    }
}

- (void)updateConstraints
{
    if (!self.addedContraints) {
        
        [self.textField autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
        
        [self.passwordStrengthMeterView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
        [self.passwordStrengthMeterView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.textField withOffset:2.0];
        
        self.addedContraints = YES;
    }
    [super updateConstraints];
    
   
}

@end
