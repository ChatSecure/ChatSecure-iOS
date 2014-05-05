//
//  OTRPasswordStrengthTextField.h
//  Off the Record
//
//  Created by David Chiles on 5/1/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NJOPasswordStrengthEvaluator.h"

@class OTRPasswordStrengthView;

@protocol OTRPasswordStrengthViewDelegate <NSObject>

- (void)passwordView:(OTRPasswordStrengthView *)view didChangePassword:(NSString *)password strength:(NJOPasswordStrength)strength failingRules:(NSArray *)rules;


@end

@interface OTRPasswordStrengthView : UIView

- (id)initWithRules:(NSArray *)rules;
- (id)initWithDefaultRules;

@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, weak) id<OTRPasswordStrengthViewDelegate> delegate;

@end
