#import <UIKit/UIKit.h>
#include "CCDNDTimer.h"

@interface UIWindow ()
- (void)_setSecure:(BOOL)arg1;
@end

@implementation CCDNDTimer
__strong static id _sharedObject;
NSTimer *DNDTimer;
NSNumber* DNDTimeLeft;
BOOL gotDeselected;
+ (id)sharedInstance
{
    if (!_sharedObject) {
        _sharedObject = [[self alloc] init];
    }
    return _sharedObject;
}

//Return the icon of your module here
- (UIImage *)iconGlyph
{
    return [UIImage imageNamed:@"Icon" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
}

+ (void)enableDND {
	if (!assertionService) assertionService = (DNDModeAssertionService *)[%c(DNDModeAssertionService) serviceForClientIdentifier:@"com.apple.donotdisturb.control-center.module"];
	DNDModeAssertionDetails *newAssertion = [%c(DNDModeAssertionDetails) userRequestedAssertionDetailsWithIdentifier:@"com.apple.control-center.manual-toggle" modeIdentifier:@"com.apple.donotdisturb.mode.default" lifetime:nil];
	[assertionService takeModeAssertionWithDetails:newAssertion error:NULL];
}

- (void)enableDND {
	if (!assertionService) assertionService = (DNDModeAssertionService *)[%c(DNDModeAssertionService) serviceForClientIdentifier:@"com.apple.donotdisturb.control-center.module"];
	DNDModeAssertionDetails *newAssertion = [%c(DNDModeAssertionDetails) userRequestedAssertionDetailsWithIdentifier:@"com.apple.control-center.manual-toggle" modeIdentifier:@"com.apple.donotdisturb.mode.default" lifetime:nil];
	[assertionService takeModeAssertionWithDetails:newAssertion error:NULL];
}

static BOOL isDNDEnabled(){
	id service = MSHookIvar<id>(UIApplication.sharedApplication, "_dndNotificationsService");
	if(!service) return 0;
	else return MSHookIvar<BOOL>(service, "_doNotDisturbActive");
}

-(NSTimer*)getTimer {
  return DNDTimer;
}

//Return the color selection color of your module here
- (UIColor *)selectedColor
{
	return [UIColor blueColor];
}

- (BOOL)isSelected
{
  NSLog(@"omriku checking toggle state..");
  NSMutableDictionary* timerLeftDict = [[NSMutableDictionary alloc] initWithContentsOfFile:DND_TIMER_PLIST];
  DNDTimeLeft = [NSNumber numberWithInt:[[timerLeftDict objectForKey:@"DNDTimeLeft"] intValue]];
  if ([DNDTimeLeft intValue] > 0 && isDNDEnabled() && !gotDeselected) {
      return YES;
  }
  return _selected;
}

- (void)setSelected:(BOOL)selected
{
	_selected = selected;
  [super refreshState];

  if(_selected)
  {
    NSLog(@"omriku toggle got selected!");
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"CCDNDTimer" message:[NSString stringWithFormat:@"Enter time below (minutes)"] preferredStyle:UIAlertControllerStyleAlert];
		[alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) { textField.placeholder = @"Enter Minutes";	textField.keyboardType = UIKeyboardTypeNumberPad;}];
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"Enable DND" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
          if ([[[alertController textFields][0] text] intValue] == 0) {
            [self setSelected:NO];
            return;
          }
          [self updateDNDTimerSettingsWithTimeLeft:[NSNumber numberWithInt:[[[alertController textFields][0] text] intValue]]];
          NSLog(@"omriku starting DNDTimer with time of: %@ firedate: %@", DNDTimeLeft, [NSDate dateWithTimeIntervalSinceNow:([DNDTimeLeft intValue]*60)]);
          [self resetTimer];
          DNDTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                           target:self
                                            selector:@selector(updateDNDTimer)
                                            userInfo:nil
                                            repeats:YES];
         // NSLog(@"omriku timer from class? :%@ ", DNDTimer);
          //dispatch_after(dispatch_time(DISPATCH_TIME_NOW, [DNDTimeLeft intValue] * 60 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
              //NSLog(@"omriku DND will be disabled now");
             // disableDND();
          //});
          [self enableDND];
    }];
    
    [alertController addAction:confirmAction];
   // UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
      //  return;
	 // }];

	  //[alertController addAction:cancelAction];
    UIWindow* tempWindowForPrompt;
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
    NSLog(@"omriku got canceled toggle!");
    gotDeselected = YES;
    disableDND();
    [self updateDNDTimerSettingsWithTimeLeft:[NSNumber numberWithInt:0]];
    [self resetTimer];
  }
}

-(void)updateDNDTimer {
  [self updateDNDTimerSettingsWithTimeLeft:[NSNumber numberWithInt:[DNDTimeLeft intValue] - 1]];
  NSLog(@"omriku class timer has been called.. seconds left.. %@",DNDTimeLeft);
  if ([DNDTimeLeft intValue] <= 0) {
      [self setSelected:NO];
  }

}

-(void)resetTimer {
  NSLog(@"omriku reseting timer");
  [DNDTimer invalidate];
  DNDTimer = nil;
}

-(void)updateDNDTimerSettingsWithTimeLeft:(NSNumber*)timeLeft {
  NSLog(@"omriku saving to settings + updating the global variable! with timeleft: %@", timeLeft);
  DNDTimeLeft = timeLeft;
  NSMutableDictionary* settingsFile =  [[NSMutableDictionary alloc] init];
  [settingsFile setObject:DNDTimeLeft forKey:@"DNDTimeLeft"];
  [settingsFile writeToFile:DND_TIMER_PLIST atomically:YES];
}
@end

