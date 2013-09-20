#import "_OTRManagedOAuthAccount.h"

@protocol OTRManagedOAuthAccountProtocol <NSObject>

@optional
-(void)refreshToken:(void (^)(NSError *error))completionBlock;
-(void)refreshTokenIfNeeded:(void (^)(NSError *error))completion;
-(NSString *)accessTokenString;

@end

@interface OTRManagedOAuthAccount : _OTRManagedOAuthAccount <OTRManagedOAuthAccountProtocol>


@property (nonatomic,strong) NSDictionary * tokenDictionary;

+ (id)createWithXmppAccount:(OTRManagedXMPPAccount *)xmppAccount;

@end
