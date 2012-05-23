//
//  OTRValueSetting.h
//  Off the Record
//
//  Created by Chris Ballinger on 4/11/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRSetting.h"


@interface OTRValueSetting : OTRSetting

@property (nonatomic, readonly) NSString *key;
@property (nonatomic) id value;
@property (nonatomic, retain) NSNumber *defaultValue;


- (id) initWithTitle:(NSString*)newTitle description:(NSString*)newDescription settingsKey:(NSString*)newSettingsKey;

@end
