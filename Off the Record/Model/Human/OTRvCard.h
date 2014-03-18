#import "_OTRvCard.h"

@class XMPPvCardTemp;

@interface OTRvCard : _OTRvCard {}

@property (nonatomic,strong) XMPPvCardTemp * vCardTemp;
@property (nonatomic,strong) NSData * photoData;

+(OTRvCard *)fetchOrCreateWithJidString:(NSString *)jidString inContext:(NSManagedObjectContext *)context;

@end
