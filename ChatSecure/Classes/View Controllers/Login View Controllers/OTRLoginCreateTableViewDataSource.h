//
//  OTRLoginCreateTableViewDataSource.h
//  ChatSecure
//
//  Created by David Chiles on 5/12/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@import UIKit;

@interface OTRLoginCreateTableViewDataSource : NSObject <UITableViewDataSource>

@property (nonatomic, strong) NSArray *basicInfoArray;
@property (nonatomic, strong) NSArray *advancedInfoArray;


- (instancetype)initWithBasicInfoArray:(NSArray *)basicInfoArray advancedArray:(NSArray *)advancedInfoArray;

@end
