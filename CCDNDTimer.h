
#import <ControlCenterUIKit/CCUIToggleModule.h>
#import <objc/objc.h>
#pragma clang diagnostic ignored "-Wunused-variable"
#pragma clang diagnostic ignored "-Wunused-function"
#import <rootless.h>

#define DND_TIMER_PLIST ROOT_PATH_NS(@"/var/mobile/Library/Preferences/com.0xkuj.ccdndtimer.plist")

@class DNDModeAssertionLifetime;
@interface DNDModeAssertionDetails : NSObject
+ (id)userRequestedAssertionDetailsWithIdentifier:(NSString *)identifier modeIdentifier:(NSString *)modeIdentifier lifetime:(DNDModeAssertionLifetime *)lifetime;
- (BOOL)invalidateAllActiveModeAssertionsWithError:(NSError **)error;
- (id)takeModeAssertionWithDetails:(DNDModeAssertionDetails *)assertionDetails error:(NSError **)error;
@end

@interface DNDModeAssertionService : NSObject
+ (id)serviceForClientIdentifier:(NSString *)clientIdentifier;
- (BOOL)invalidateAllActiveModeAssertionsWithError:(NSError **)error;
- (id)takeModeAssertionWithDetails:(DNDModeAssertionDetails *)assertionDetails error:(NSError **)error;
@end

static BOOL DNDPreviouslyEnabled = true;
static DNDModeAssertionService *assertionService;

@interface CCDNDTimer : CCUIToggleModule
{
  BOOL _selected;
}
- (void)setSelected:(BOOL)selected;
@end