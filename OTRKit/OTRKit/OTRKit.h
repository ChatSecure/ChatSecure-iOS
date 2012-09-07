/*
 * OTRKit.m
 * OTRKit
 *
 * Created by Chris Ballinger on 9/4/11.
 * Copyright (c) 2012 Chris Ballinger. All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * 
 * Neither the name of the project's author nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#import <Foundation/Foundation.h>

typedef unsigned int OTRKitMessageState;

enum OTRKitMessageState { // OtrlMessageState
    kOTRKitMessageStatePlaintext = 0, //OTRL_MSGSTATE_PLAINTEXT
    kOTRKitMessageStateEncrypted = 1, // OTRL_MSGSTATE_ENCRYPTED
    kOTRKitMessageStateFinished = 2 // OTRL_MSGSTATE_FINISHED
}; //

@protocol OTRKitDelegate <NSObject>
@required
// Implement this delegate method to forward the injected message to the appropriate protocol
- (void) injectMessage:(NSString*)message recipient:(NSString*)recipient accountName:(NSString*)accountName protocol:(NSString*)protocol;
- (void) updateMessageStateForUsername:(NSString*)username accountName:(NSString*)accountName protocol:(NSString*)protocol messageState:(OTRKitMessageState)messageState; 

@optional
// If you don't implement these methods there are some defaults in place that you might want to check out in OTRCodec.m

// You will probably want to show a dialog for fingerprint confirmation though
- (void) showFingerprintConfirmationForAccountName:(NSString*)accountName protocol:(NSString*)protocol userName:(NSString*)userName theirHash:(NSString*)theirHash ourHash:(NSString*)ourHash;

- (void) createPrivateKeyForAccountName:(NSString*)accountName protocol:(NSString*)protocol;
- (BOOL) recipientIsLoggedIn:(NSString*)recipient accountName:(NSString*)accountName protocol:(NSString*)protocol;
- (void) writeFingerprints;
- (int) maxMessageSizeForProtocol:(NSString*)protocol;
- (void) updateContextList;
- (void) logMessage:(NSString*)message;
- (void) showNotificationForAccountName:(NSString*)accountName protocol:(NSString*)protocol userName:(NSString*)userName title:(NSString*)title primary:(NSString*)primary secondary:(NSString*)secondary level:(int)level;
- (void) showMessageDialogForAccountName:(NSString*)accountName protocol:(NSString*)protocol userName:(NSString*)userName message:(NSString*)message;
@end

@interface OTRKit : NSObject

@property (nonatomic, assign) id<OTRKitDelegate> delegate;
@property (nonatomic, retain) NSTimer *pollTimer;

- (NSString*) privateKeyPath;
- (NSString*) fingerprintsPath;
- (NSString*) instanceTagsPath;

- (NSString*) decodeMessage:(NSString*)message recipient:(NSString*)recipient accountName:(NSString*)accountName protocol:(NSString*)protocol;
- (NSString*) encodeMessage:(NSString*)message recipient:(NSString*)recipient accountName:(NSString*)accountName protocol:(NSString*)protocol;

- (NSString*) fingerprintForAccountName:(NSString*)accountName protocol:(NSString*) protocol; // Returns your fingerprint
- (NSString *) fingerprintForUsername:(NSString*)username accountName:(NSString*)accountName protocol:(NSString*) protocol; // Returns buddy's fingerprint

- (void) disableEncryptionForUsername:(NSString*)username accountName:(NSString*)accountName protocol:(NSString*) protocol;


- (OTRKitMessageState) messageStateForUsername:(NSString*)username accountName:(NSString*)accountName protocol:(NSString*) protocol;


+ (OTRKit*) sharedInstance; // Singleton method


@end