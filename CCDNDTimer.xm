#import <UIKit/UIKit.h>
#include "CCDNDTimer.h"
//#import <rootless.h>
//#define CCTOGGLE_ICON_PATH ROOT_PATH_NS(@"/var/jb/Library/ControlCenter/Bundles/CCDNDTimer.bundle/");
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface UIWindow ()
- (void)_setSecure:(BOOL)arg1;
@end

@implementation CCDNDTimer
BOOL gotDeselected;
NSDate* DNDFireDate;

- (CCUICAPackageDescription *)glyphPackageDescription {
    return [CCUICAPackageDescription descriptionForPackageNamed:@"CCDNDTimer" inBundle:[NSBundle bundleForClass:[self class]]];
}

- (UIImage *)iconGlyph {
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
	if(!service) {
		return 0;
	}
	else {
		id state = MSHookIvar<id>(service, "_currentState");
		return [state isActive];
	}
}

//Return the color selection color of your module here
//exact color as the original moon icon of DND
- (UIColor *)selectedColor
{
	return [UIColor colorWithRed:142/255.0 green:83/255.0 blue:251/255.0 alpha:1];
}

- (BOOL)isSelected
{
  //add observer only once, since adding more observers will flood you with the same notifications!
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
    //v.1
    /*
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"CCDNDTimer" message:[NSString stringWithFormat:@"How long you want DND to be active?"] preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) { textField.placeholder = @"Enter Hours";	textField.keyboardType = UIKeyboardTypeNumberPad;}];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) { textField.placeholder = @"Enter Minutes";	textField.keyboardType = UIKeyboardTypeNumberPad;}];
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"Enable DND" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
          
          if ([[[alertController textFields][1] text] intValue] == 0 && [[[alertController textFields][0] text] intValue] == 0) {
            [self setSelected:NO];
            return;
          }
          int minutes = [[[alertController textFields][1] text] intValue];
          int hours = [[[alertController textFields][0] text] intValue];

          NSNumber* hoursAndMinutes = [NSNumber numberWithInt:(minutes+hours*60)]; 
          [self updateDNDTimerSettingsWithTimeLeft:hoursAndMinutes];
          enableDND();
          //post notificvation.. 
          [[NSNotificationCenter defaultCenter] postNotificationName:@"com.0xkuj.ccdndtimer.moduleactivated" object:nil];
    }];
    */
    //reach this number, 270. 60 is fine by me and 100 is the height. fine as well. only 270 is important!
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"CCDNDTimer" message:[NSString stringWithFormat:@"How long you want DND to be active?\n\n\n\n\n\n"] preferredStyle:UIAlertControllerStyleAlert];
    UIDatePicker *picker = [[UIDatePicker alloc] init];
    //picker.frame = CGRectMake(0, 60, 270, 100);
    [picker setDatePickerMode:UIDatePickerModeCountDownTimer];
    [alertController.view addSubview:picker];
    picker.translatesAutoresizingMaskIntoConstraints = NO;
    // added constraints because ios 16..
    [NSLayoutConstraint activateConstraints:@[
        [picker.leadingAnchor constraintEqualToAnchor:alertController.view.leadingAnchor],
        [picker.trailingAnchor constraintEqualToAnchor:alertController.view.trailingAnchor],
        [picker.topAnchor constraintEqualToAnchor:alertController.view.topAnchor constant:60],
        [picker.heightAnchor constraintEqualToConstant:120]
    ]];

    [alertController addAction:({
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:picker.date];
            NSNumber* hoursAndMinutes = [NSNumber numberWithInt:([components minute]+[components hour]*60)]; 
            if ([hoursAndMinutes intValue] < 0) {
              [self setSelected:NO];
              return;
            } else if ([hoursAndMinutes intValue] == 0) {
              hoursAndMinutes = [NSNumber numberWithInt:1];
            }
            [self updateDNDTimerSettingsWithTimeLeft:hoursAndMinutes];
            enableDND();
            [[NSNotificationCenter defaultCenter] postNotificationName:@"com.0xkuj.ccdndtimer.moduleactivated" object:nil];
        }];
        action;
    })];

    /* prepare function for "no" button" */
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style: UIAlertActionStyleCancel handler:^(UIAlertAction * action) { 
            [self setSelected:NO];
            return;
     }];
    /* actually assign those actions to the buttons */
    [alertController addAction:cancelAction];
		UIWindow *originalKeyWindow = [[UIApplication sharedApplication] keyWindow];
		UIResponder *responder = originalKeyWindow.rootViewController.view;
		while ([responder isKindOfClass:[UIView class]]) responder = [responder nextResponder];
		[(UIViewController *)responder presentViewController:alertController animated:YES completion:^{}];
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

