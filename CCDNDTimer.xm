#import <UIKit/UIKit.h>
#include "CCDNDTimer.h"

@interface UIWindow ()
- (void)_setSecure:(BOOL)arg1;
@end

@implementation CCDNDTimer
BOOL gotDeselected;
NSDate* DNDFireDate;

//Return the icon of your module here
- (UIImage *)iconGlyph
{
    return [UIImage imageNamed:@"Icon" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
}

static void enableDND() {
	if (!assertionService) assertionService = (DNDModeAssertionService *)[%c(DNDModeAssertionService) serviceForClientIdentifier:@"com.apple.donotdisturb.control-center.module"];
	DNDModeAssertionDetails *newAssertion = [%c(DNDModeAssertionDetails) userRequestedAssertionDetailsWithIdentifier:@"com.apple.control-center.manual-toggle" modeIdentifier:@"com.apple.donotdisturb.mode.default" lifetime:nil];
	[assertionService takeModeAssertionWithDetails:newAssertion error:NULL];
}

static void disableDND() {
	if (!assertionService) assertionService = (DNDModeAssertionService *)[NSClassFromString(@"DNDModeAssertionService") serviceForClientIdentifier:@"com.apple.donotdisturb.control-center.module"];
	[assertionService invalidateAllActiveModeAssertionsWithError:NULL];
}

static bool isDNDEnabled() {
	id service = MSHookIvar<id>(UIApplication.sharedApplication, "_dndNotificationsService");
	if(!service) return 0;
	else return MSHookIvar<BOOL>(service, "_doNotDisturbActive");
}

//Return the color selection color of your module here
//exact color as the original moon icon of DND
- (UIColor *)selectedColor
{
	return [UIColor colorWithRed:142/255.0 green:83/255.0 blue:251/255.0 alpha:1];
}

- (BOOL)isSelected
{
  static dispatch_once_t onceToken2;
  dispatch_once(&onceToken2, ^{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelToggle) name:@"com.0xkuj.ccdndtimer.timerover" object:nil];
  });
  NSMutableDictionary* timerLeftDict = [[NSMutableDictionary alloc] initWithContentsOfFile:DND_TIMER_PLIST];
  NSDate* lastFireDate = [timerLeftDict objectForKey:@"DNDFireDate"];
  long timeDelta = [lastFireDate timeIntervalSinceDate:[NSDate date]];
  if (timeDelta > 0 && isDNDEnabled() && !gotDeselected) {
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
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"CCDNDTimer" message:[NSString stringWithFormat:@"How long you want DND to be active?"] preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) { textField.placeholder = @"Enter Hours";	textField.keyboardType = UIKeyboardTypeNumberPad;}];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) { textField.placeholder = @"Enter Minutes";	textField.keyboardType = UIKeyboardTypeNumberPad;}];
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"Enable DND" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
          //post notificvation..
          if ([[[alertController textFields][1] text] intValue] == 0 && [[[alertController textFields][0] text] intValue] == 0) {
            [self setSelected:NO];
            return;
          }
          int minutes = [[[alertController textFields][1] text] intValue];
          int hours = [[[alertController textFields][0] text] intValue];

          NSNumber* hoursAndMinutes = [NSNumber numberWithInt:(minutes+hours*60)]; 
          [self updateDNDTimerSettingsWithTimeLeft:hoursAndMinutes];
          enableDND();

          [[NSNotificationCenter defaultCenter] postNotificationName:@"com.0xkuj.ccdndtimer.moduleactivated" object:nil];
    }];
    
    [alertController addAction:confirmAction];
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
    gotDeselected = YES;
    disableDND();
    [self updateDNDTimerSettingsWithTimeLeft:[NSNumber numberWithInt:0]];
  }
}

-(void)cancelToggle {
  [self setSelected:NO];
}

-(void)updateDNDTimerSettingsWithTimeLeft:(NSNumber*)timeLeft {
  if ([DNDFireDate timeIntervalSinceDate:[NSDate date]] <= 0 && timeLeft == 0) {
    return;
  }
  // DNDTimeLeft = timeLeft;
  DNDFireDate = [NSDate dateWithTimeIntervalSinceNow:([timeLeft intValue]*60)];
  NSMutableDictionary* settingsFile =  [[NSMutableDictionary alloc] init];
  //[settingsFile setObject:DNDTimeLeft forKey:@"DNDTimeLeft"];
  [settingsFile setObject:DNDFireDate forKey:@"DNDFireDate"];
  [settingsFile writeToFile:DND_TIMER_PLIST atomically:YES];
}
@end

