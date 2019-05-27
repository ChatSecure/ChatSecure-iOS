//
//  YapDatabaseViewConnection+ChatSecure.h
//  ChatSecure
//
//  Created by Chris Ballinger on 2/24/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

@import YapDatabase;

NS_ASSUME_NONNULL_BEGIN
@interface OTRSectionRowChanges : NSObject
@property (nonatomic, strong, readonly) NSArray<YapDatabaseViewSectionChange *> *sectionChanges;
@property (nonatomic, strong, readonly) NSArray<YapDatabaseViewRowChange *> *rowChanges;
@end

@interface YapDatabaseViewConnection (ChatSecure)

- (OTRSectionRowChanges*) otr_getSectionRowChangesForNotifications:(NSArray<NSNotification*> *)notifications
                                                      withMappings:(YapDatabaseViewMappings *)mappings;
@end
NS_ASSUME_NONNULL_END
