#import "OTRvCard.h"

#import "OTRvCardTemp.h"
#import "OTRvCardAvatar.h"

#import "NSData+XMPP.h"


@interface OTRvCard ()

// Private interface goes here.

@end


@implementation OTRvCard

+(OTRvCard *)fetchOrCreateWithJidString:(NSString *)jidString {
    
    OTRvCard * vCard = nil;
    NSPredicate * searchPredicate = [NSPredicate predicateWithFormat:@"%@ == %@",OTRvCardAttributes.jidString,jidString];
    NSArray * allvCardsArray = [OTRvCard MR_findAllWithPredicate:searchPredicate];
    
    if ([allvCardsArray count]) {
        vCard = [allvCardsArray lastObject];
    }
    else {
        vCard = [OTRvCard MR_createEntity];
        vCard.jidString = jidString;
    }
    return vCard;
}

-(void)setVCardTemp:(XMPPvCardTemp *)vCardTemp {
    if (!vCardTemp && self.vCardAvatarRelationship) {
        [self.vCardTempRelationship MR_deleteEntity];
        return;
    }
    else {
        OTRvCardTemp * newvCardTemp = [OTRvCardTemp MR_createEntity];
        newvCardTemp.vCardTemp = vCardTemp;
        self.vCardTempRelationship = newvCardTemp;
    }
    
}

-(XMPPvCardTemp *)vCardTemp {
    
    return self.vCardTempRelationship.vCardTemp;
}

-(void)setPhotoData:(NSData *)photoData
{
    if (!photoData && self.vCardAvatarRelationship) {
        [self.vCardAvatarRelationship MR_deleteEntity];
        self.photoHash = nil;
    }
    else {
        OTRvCardAvatar * vCardAvatar = [OTRvCardAvatar MR_createEntity];
        vCardAvatar.photoData = photoData;
        self.vCardAvatarRelationship = vCardAvatar;
        
        self.photoHash = [[photoData xmpp_sha1Digest] xmpp_hexStringValue];
    }
}

-(NSData *)photoData {
    return self.vCardAvatarRelationship.photoData;
}

@end
