//
//  OTRSetting.h
//  Off the Record
//
//  Created by Chris Ballinger on 4/11/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTRSetting : NSObject

@property (nonatomic, strong, readonly) NSString *title;
@property (nonatomic, strong, readonly) NSString *description;
@property (nonatomic, strong) NSString *imageName;
@property (nonatomic) SEL action;

- (id) initWithTitle:(NSString *)newTitle description:(NSString *)newDescription;

@end
