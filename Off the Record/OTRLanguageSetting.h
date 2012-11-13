//
//  OTRLanguageSetting.h
//  Off the Record
//
//  Created by David on 11/13/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRListSetting.h"
#import "OTRLanguageManager.h"

@interface OTRLanguageSetting : OTRListSetting


@property (nonatomic,strong) OTRLanguageManager * languageManager;

@end
