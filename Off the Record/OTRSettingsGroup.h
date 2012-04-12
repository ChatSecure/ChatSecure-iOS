//
//  OTRSettingsGroup.h
//  Off the Record
//
//  Created by Chris Ballinger on 4/11/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTRSettingsGroup : NSObject

@property (nonatomic, readonly) NSArray *settings;
@property (nonatomic, readonly) NSString *title;

- (id) initWithTitle:(NSString*)newTitle settings:(NSArray*)newSettings;

@end
