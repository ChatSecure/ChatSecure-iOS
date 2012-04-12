//
//  OTRSetting.h
//  Off the Record
//
//  Created by Chris Ballinger on 4/11/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTRSetting : NSObject

@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *description;
@property (nonatomic, retain) NSString *imageName;
@property (nonatomic) SEL action;

- (id) initWithTitle:(NSString *)newTitle description:(NSString *)newDescription;

@end
