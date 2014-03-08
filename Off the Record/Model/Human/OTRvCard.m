#import "OTRvCard.h"

#import "OTRvCardTemp.h"
#import "OTRvCardAvatar.h"

#import "NSData+XMPP.h"
#import "OTRLog.h"


@interface OTRvCard ()

// Private interface goes here.

@end


@implementation OTRvCard

+(OTRvCard *)fetchOrCreateWithJidString:(NSString *)jidString inContext:(NSManagedObjectContext *)context{
    
    OTRvCard * vCard = nil;
    NSPredicate * searchPredicate = [NSPredicate predicateWithFormat:@"%K == %@",OTRvCardAttributes.jidString,jidString];
    NSArray * allvCardsArray = [OTRvCard MR_findAllWithPredicate:searchPredicate inContext:context];
    
    if ([allvCardsArray count]) {
        vCard = [allvCardsArray lastObject];
    }
    else {
        vCard = [OTRvCard MR_createInContext:context];
        NSError *error = nil;
        [context obtainPermanentIDsForObjects:@[vCard] error:&error];
        if (error) {
            DDLogError(@"Error obtaining permanent ID for vCard: %@", error);
        }
        vCard.jidString = jidString;
    }
    return vCard;
}

-(void)setVCardTemp:(XMPPvCardTemp *)vCardTemp {
    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
    OTRvCard *localSelf = [self MR_inContext:localContext];
    if (!vCardTemp && localSelf.vCardAvatarRelationship) {
        [localSelf.vCardTempRelationship MR_deleteInContext:localContext];
    }
    else {
        OTRvCardTemp * newvCardTemp = [OTRvCardTemp MR_createInContext:localContext];
        NSError *error = nil;
        [localContext obtainPermanentIDsForObjects:@[newvCardTemp] error:&error];
        if (error) {
            DDLogError(@"Error obtaining permanent ID for OTRvCardTemp: %@", error);
        }
        newvCardTemp.vCardTemp = vCardTemp;
        localSelf.vCardTempRelationship = newvCardTemp;
    }
    [localContext MR_saveToPersistentStoreAndWait];
}

-(XMPPvCardTemp *)vCardTemp {
    
    return self.vCardTempRelationship.vCardTemp;
}

-(void)setPhotoData:(NSData *)photoData
{
    NSManagedObjectContext * context = [self managedObjectContext];
    if (!photoData && self.vCardAvatarRelationship) {
        [self.vCardAvatarRelationship MR_deleteInContext:context];
        self.photoHash = nil;
    }
    else {
        OTRvCardAvatar * vCardAvatar = [OTRvCardAvatar MR_createInContext:context];
        NSError *error = nil;
        [context obtainPermanentIDsForObjects:@[vCardAvatar] error:&error];
        if (error) {
            DDLogError(@"Error obtaining permanent ID for vCardAvatar: %@", error);
        }
        vCardAvatar.photoData = photoData;
        self.vCardAvatarRelationship = vCardAvatar;
        
        self.photoHash = [[photoData xmpp_sha1Digest] xmpp_hexStringValue];
    }
}

-(NSData *)photoData {
    return self.vCardAvatarRelationship.photoData;
}

@end
