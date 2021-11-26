#import <UIKit/UIKit.h>
#import <ControlCenterUIKit/CCUIToggleModule.h>
#define DND_TIMER_PLIST @"/var/mobile/Library/Preferences/com.0xkuj.ccdndtimer.plist"

@class DNDModeAssertionLifetime;

#pragma clang diagnostic ignored "-Wunused-variable"
#pragma clang diagnostic ignored "-Wunused-function"

@interface CCDNDTimer : CCUIToggleModule
{
  BOOL _selected;
}
@end

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

@interface UIWindow ()
- (void)_setSecure:(BOOL)arg1;
@end

static BOOL DNDPreviouslyEnabled = true;
static DNDModeAssertionService *assertionService;

static void disableDND(){
	if (!assertionService) assertionService = (DNDModeAssertionService *)[%c(DNDModeAssertionService) serviceForClientIdentifier:@"com.apple.donotdisturb.control-center.module"];
	[assertionService invalidateAllActiveModeAssertionsWithError:NULL];
}

static NSNumber* DNDTimeLeft;
static NSTimer *DNDTimer;

static void updateDNDTimer() {
  NSLog(@"omriku timer has been called..");
  DNDTimeLeft = [NSNumber numberWithInt:[DNDTimeLeft intValue] - 1];
  NSMutableDictionary* settingsFile =  [[NSMutableDictionary alloc] init];
  [settingsFile setObject:DNDTimeLeft forKey:@"DNDTimeLeft"];
  [settingsFile writeToFile:DND_TIMER_PLIST atomically:YES];
  if ([DNDTimeLeft intValue] <= 0) {
    [DNDTimer invalidate];
    disableDND();
  }
}


@implementation CCDNDTimer
//Return the icon of your module here
- (UIImage *)iconGlyph
{
    return [UIImage imageNamed:@"Icon" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
}

//Return the color selection color of your module here
- (UIColor *)selectedColor
{
	return [UIColor blueColor];
}

- (BOOL)isSelected
{
  return _selected;
}

static void enableDND(){
	if (!assertionService) assertionService = (DNDModeAssertionService *)[%c(DNDModeAssertionService) serviceForClientIdentifier:@"com.apple.donotdisturb.control-center.module"];
	DNDModeAssertionDetails *newAssertion = [%c(DNDModeAssertionDetails) userRequestedAssertionDetailsWithIdentifier:@"com.apple.control-center.manual-toggle" modeIdentifier:@"com.apple.donotdisturb.mode.default" lifetime:nil];
	[assertionService takeModeAssertionWithDetails:newAssertion error:NULL];
}


- (void)setSelected:(BOOL)selected
{
	_selected = selected;
  UIWindow* tempWindowForPrompt;
 
  [super refreshState];

  if(_selected)
  {
    //NSLog(@"omriku DND started");
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"CCDNDTimer" message:[NSString stringWithFormat:@"Enter time below (minutes)"] preferredStyle:UIAlertControllerStyleAlert];
		[alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) { textField.placeholder = @"Enter Minutes";	textField.keyboardType = UIKeyboardTypeNumberPad;}];
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"Enable DND" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
          //NSLog(@"omriku DND started");
          enableDND();
          DNDTimeLeft = [NSNumber numberWithInt:[[[alertController textFields][0] text] intValue]];
          NSMutableDictionary* settingsFile =  [[NSMutableDictionary alloc] init];
          [settingsFile setObject:DNDTimeLeft forKey:@"DNDTimeLeft"];
          [settingsFile writeToFile:DND_TIMER_PLIST atomically:YES];
          DNDTimer = [NSTimer scheduledTimerWithTimeInterval:60
                                            target:self
                                            selector:@selector(updateDNDTimer)
                                            userInfo:nil
                                            repeats:YES];

          //dispatch_after(dispatch_time(DISPATCH_TIME_NOW, [DNDTimeLeft intValue] * 60 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
              //NSLog(@"omriku DND will be disabled now");
             // disableDND();
          //});
    }];
    
    [alertController addAction:confirmAction];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self setSelected:NO];
        return;
	  }];

	  [alertController addAction:cancelAction];
    tempWindowForPrompt = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    tempWindowForPrompt.rootViewController = [UIViewController new];
    tempWindowForPrompt.windowLevel = UIWindowLevelAlert+1;
    tempWindowForPrompt.hidden = NO;
    tempWindowForPrompt.tintColor = [[UIWindow valueForKey:@"keyWindow"] tintColor];
    [tempWindowForPrompt _setSecure:YES];
    [tempWindowForPrompt makeKeyAndVisible];
    [tempWindowForPrompt.rootViewController presentViewController:alertController animated:YES completion:nil];
  }
  else
  {
    disableDND();
    //NSLog(@"omriku DND will be disabled now (desslect)");
  }
}

@end

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
  NSMutableDictionary* timerLeftDict = [[NSMutableDictionary alloc] initWithContentsOfFile:DND_TIMER_PLIST];
   if ([timerLeftDict objectForKey:@"DNDTimeLeft"]) {
      NSLog(@"omriku time left after respring is.. %@",[timerLeftDict objectForKey:@"DNDTimeLeft"]);
      DNDTimeLeft = [NSNumber numberWithInt:[[timerLeftDict objectForKey:@"DNDTimeLeft"] intValue]];
      if ([DNDTimeLeft intValue] > 0) {
                  DNDTimer = [NSTimer scheduledTimerWithTimeInterval:5
                                            target:self
                                            selector:@selector(updateDNDTimer)
                                            userInfo:nil
                                            repeats:YES];
      }
   }
   %orig(application);
}
%end