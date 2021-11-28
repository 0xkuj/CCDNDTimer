#include "../CCDNDTimer.h"
#include "Tweak.h"

@interface CCUIToggleViewController
-(id)module;
@end

%hook SpringBoard
NSTimer* sbDNDTimer;
NSNumber* sbDNDTimeLeft;
NSDate* sbDNDFireDate;
- (void)applicationDidFinishLaunching:(id)application {
  NSMutableDictionary* timerLeftDict = [[NSMutableDictionary alloc] initWithContentsOfFile:DND_TIMER_PLIST];
  if ([timerLeftDict objectForKey:@"DNDFireDate"]) {
      sbDNDFireDate = [timerLeftDict objectForKey:@"DNDFireDate"];
      double timeDelta = [sbDNDFireDate timeIntervalSinceDate:[NSDate date]];
      if (timeDelta > 0) {
          sbDNDTimer = [NSTimer scheduledTimerWithTimeInterval:1
                              target:self
                              selector:@selector(updateDNDTimer)
                              userInfo:nil
                              repeats:YES];
      }
  }
   %orig(application);
}

//duplicate code.. yack
static bool isDNDEnabled() {
	id service = MSHookIvar<id>(UIApplication.sharedApplication, "_dndNotificationsService");
	if(!service) return 0;
	else return MSHookIvar<BOOL>(service, "_doNotDisturbActive");
}

%new
-(void)updateDNDTimer {
  double timeDelta = [sbDNDFireDate timeIntervalSinceDate:[NSDate date]];
  if (!isDNDEnabled() || timeDelta <= 0) {
      [sbDNDTimer invalidate];
      sbDNDTimer = nil;
      sbDNDTimeLeft = 0;
      //posting notification to the module
      [[NSNotificationCenter defaultCenter] postNotificationName:@"com.0xkuj.ccdndtimer.timerover" object:nil];
      return;
  }
}
%end

%hook CCUIModuleCollectionViewController
NSDictionary *moduleDictionary;
UILabel *timeRemainingLabel;
NSTimer* labelTimer;
CCUIContentModuleContainerView *CCDNDModuleContainerView;
NSDate* dndFireDate;
-(void)viewWillAppear:(BOOL)arg1 {
	%orig(arg1);
	moduleDictionary = MSHookIvar<NSDictionary *>(self, "_moduleContainerViewByIdentifier");
  //if timer is active.. add label here
  double timeDelta = [sbDNDFireDate timeIntervalSinceDate:[NSDate date]];
  if (timeDelta > 0) {
      [self addDNDLabel];
  }
	return;
}

-(void)contentModuleContainerViewController:(id)arg1 didBeginInteractionWithModule:(id)arg2 {
  %orig(arg1,arg2);
  if ([arg2 isKindOfClass:[NSClassFromString(@"CCDNDTimer") class]]) {
      static dispatch_once_t onceToken;
      //add observer only once, since adding more observers will flood you with the same notifications!
      dispatch_once(&onceToken, ^{
          [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addDNDLabel) name:@"com.0xkuj.ccdndtimer.moduleactivated" object:nil];
      }); 
  }
}

//something is messed up.. you may need to save firedate AND THATS IT. YOU MAY NEED TO REFACTOR.
%new
-(void)addDNDLabel {
    CCDNDModuleContainerView = [moduleDictionary objectForKey:@"com.0xkuj.ccdndtimer"];
    NSMutableDictionary* timerLeftDict = [[NSMutableDictionary alloc] initWithContentsOfFile:DND_TIMER_PLIST];
    sbDNDFireDate = [timerLeftDict objectForKey:@"DNDFireDate"];
    double timeDelta = [sbDNDFireDate timeIntervalSinceDate:[NSDate date]];
    if (timeDelta > 0) {
        [[CCDNDModuleContainerView containerView] setAlpha:0.5f];
        if (timeRemainingLabel) {
            [timeRemainingLabel removeFromSuperview];
            timeRemainingLabel = nil;
        }
        timeRemainingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [CCDNDModuleContainerView frame].size.width, [CCDNDModuleContainerView frame].size.height+45)];
        [timeRemainingLabel setText:[self timeFromSec:timeDelta]];
        [timeRemainingLabel setFont:[UIFont systemFontOfSize:12]];
        [timeRemainingLabel setTextColor:[UIColor whiteColor]];
        [timeRemainingLabel setTextAlignment:NSTextAlignmentCenter];
        [CCDNDModuleContainerView addSubview:timeRemainingLabel];
        if ((labelTimer == nil) || ![labelTimer isValid]){
           labelTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(updateLabelTimer) userInfo:nil repeats:YES];
        } 
    }

}

%new
- (void)updateLabelTimer 
{
	if ([sbDNDFireDate timeIntervalSinceDate:[NSDate date]] <= 0 || !isDNDEnabled()) {
		[timeRemainingLabel removeFromSuperview];
		timeRemainingLabel = nil;
		[[CCDNDModuleContainerView containerView] setAlpha:1.0f];
    [labelTimer invalidate];
    labelTimer = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"com.0xkuj.ccdndtimer.timerover" object:nil];
	} 
	[timeRemainingLabel setText:[self timeFromSec:[sbDNDFireDate timeIntervalSinceDate:[NSDate date]]]];	
}

%new
- (NSString *)timeFromSec:(int)seconds {
	int hours = floor(seconds /  (60 * 60));
	float minute_divisor = seconds % (60 * 60);
	int minutes = floor(minute_divisor / 60);
	float seconds_divisor = seconds % 60;
	seconds = ceil(seconds_divisor);
	if (hours > 0) {
		return [NSString stringWithFormat:@"%0.2d:%0.2d:%0.2d", hours, minutes, seconds];
	} else {
		return [NSString stringWithFormat:@"%0.2d:%0.2d", minutes, seconds];
	}
}
%end

#if 0
//begin to support prysm.. probably wont do that.
@interface PrysmButtonView
- (NSString *)timeFromSec:(int)seconds;
-(void)addDNDLabel;
@end

%hook PrysmButtonView
UIView* buttonView;
-(void)setCcButton:(id)arg1 {
  
  if ([arg1 isKindOfClass:[NSClassFromString(@"CCUIToggleViewController") class]] && [[((CCUIToggleViewController*)arg1) module] isKindOfClass:[NSClassFromString(@"CCDNDTimer") class]]) {
    ((UIView*)self).alpha = 0.2f;
    buttonView = (UIView*)self;
    [self addDNDLabel];
  }
  %orig(arg1);
}

%new
-(void)addDNDLabel {
    CCDNDModuleContainerView = [moduleDictionary objectForKey:@"com.0xkuj.ccdndtimer"];
    NSMutableDictionary* timerLeftDict = [[NSMutableDictionary alloc] initWithContentsOfFile:DND_TIMER_PLIST];
    sbDNDFireDate = [timerLeftDict objectForKey:@"DNDFireDate"];
    double timeDelta = [sbDNDFireDate timeIntervalSinceDate:[NSDate date]];
    if (timeDelta > 0) {
        buttonView.alpha = 0.5f;
        if (timeRemainingLabel) {
            [timeRemainingLabel removeFromSuperview];
            timeRemainingLabel = nil;
        }
        timeRemainingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [buttonView frame].size.width, [buttonView frame].size.height)];
        [timeRemainingLabel setText:[self timeFromSec:timeDelta]];
        [timeRemainingLabel setFont:[UIFont systemFontOfSize:12]];
        [timeRemainingLabel setTextColor:[UIColor whiteColor]];
        [timeRemainingLabel setTextAlignment:NSTextAlignmentCenter];
        [buttonView addSubview:timeRemainingLabel];
        if ((labelTimer == nil) || ![labelTimer isValid]){
           labelTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(updateLabelTimer) userInfo:nil repeats:YES];
        } 
    }

}

%new
- (NSString *)timeFromSec:(int)seconds {
	int hours = floor(seconds /  (60 * 60));
	float minute_divisor = seconds % (60 * 60);
	int minutes = floor(minute_divisor / 60);
	float seconds_divisor = seconds % 60;
	seconds = ceil(seconds_divisor);
	if (hours > 0) {
		return [NSString stringWithFormat:@"%0.2d:%0.2d:%0.2d", hours, minutes, seconds];
	} else {
		return [NSString stringWithFormat:@"%0.2d:%0.2d", minutes, seconds];
	}
}

%new
- (void)updateLabelTimer 
{
	if ([sbDNDFireDate timeIntervalSinceDate:[NSDate date]] <= 0 || !isDNDEnabled()) {
		[timeRemainingLabel removeFromSuperview];
		timeRemainingLabel = nil;
		[[CCDNDModuleContainerView containerView] setAlpha:1.0f];
    [labelTimer invalidate];
    labelTimer = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"com.0xkuj.ccdndtimer.timerover" object:nil];
	} 
	[timeRemainingLabel setText:[self timeFromSec:[sbDNDFireDate timeIntervalSinceDate:[NSDate date]]]];	
}
%end

#endif