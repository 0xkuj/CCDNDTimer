#define DND_TIMER_PLIST @"/var/mobile/Library/Preferences/com.0xkuj.ccdndtimer.plist"
#import <ControlCenterUIKit/CCUIToggleModule.h>
#import <objc/objc.h>
#pragma clang diagnostic ignored "-Wunused-variable"
#pragma clang diagnostic ignored "-Wunused-function"


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

static void disableDND(){
	if (!assertionService) assertionService = (DNDModeAssertionService *)[NSClassFromString(@"DNDModeAssertionService") serviceForClientIdentifier:@"com.apple.donotdisturb.control-center.module"];
	[assertionService invalidateAllActiveModeAssertionsWithError:NULL];
}

@interface CCDNDTimer : CCUIToggleModule
{
  BOOL _selected;
}
- (void)setSelected:(BOOL)selected;
+(void)enableDND;
//-(NSTimer*)getTimer;
-(BOOL)getGotDeselected;
+ (id)sharedInstance;
@end