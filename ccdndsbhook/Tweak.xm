#include "../CCDNDTimer.h"
#include "Tweak.h"

%hook SpringBoard
NSTimer* sbDNDTimer;
NSNumber* sbDNDTimeLeft;
NSDate* sbDNDFireDate;
- (void)applicationDidFinishLaunching:(id)application {
  NSLog(@"omriku got back from respring! starting to check if file exists, if not nil");
  NSMutableDictionary* timerLeftDict = [[NSMutableDictionary alloc] initWithContentsOfFile:DND_TIMER_PLIST];
  if ([timerLeftDict objectForKey:@"DNDFireDate"]) {
      NSLog(@"omriku not nil! time left after respring is.. %@",[timerLeftDict objectForKey:@"DNDFireDate"]);
      sbDNDFireDate = [timerLeftDict objectForKey:@"DNDFireDate"];
      NSLog(@"omriku updating sb dndtimeleft? :%@",sbDNDFireDate);
      double timeDelta = [sbDNDFireDate timeIntervalSinceDate:[NSDate date]];
      if (timeDelta > 0) {
          NSLog(@"omriku time left is bigger than 0! dndtimeleft? :%@",sbDNDFireDate);
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
  NSLog(@"omriku sb timer has been called! time left.. %@ + updating settings!", sbDNDFireDate);
  double timeDelta = [sbDNDFireDate timeIntervalSinceDate:[NSDate date]];
  if (!isDNDEnabled() || timeDelta <= 0) {
      NSLog(@"omriku timer IS ON from the class! deactivating sb timer....");
      [sbDNDTimer invalidate];
      sbDNDTimer = nil;
      sbDNDTimeLeft = 0;
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
  NSLog(@"omriku pressed the module interaction: arg1: %@, arg2: %@??",arg1,arg2);
  if ([arg2 isKindOfClass:[NSClassFromString(@"CCDNDTimer") class]]) {
      NSLog(@"omriku adding observer...");
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addDNDLabel) name:@"com.0xkuj.ccdndtimer.moduleactivated" object:nil];
  }
}

//something is messed up.. you may need to save firedate AND THATS IT. YOU MAY NEED TO REFACTOR.
%new
-(void)addDNDLabel {
    NSLog(@"omriku got called form notifcation...");
    CCDNDModuleContainerView = [moduleDictionary objectForKey:@"com.0xkuj.ccdndtimer"];
    NSMutableDictionary* timerLeftDict = [[NSMutableDictionary alloc] initWithContentsOfFile:DND_TIMER_PLIST];
    sbDNDFireDate = [timerLeftDict objectForKey:@"DNDFireDate"];
    double timeDelta = [sbDNDFireDate timeIntervalSinceDate:[NSDate date]];
    NSLog(@"omriku firedate for dnd: %@ and delta: %f",sbDNDFireDate, timeDelta);
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
- (void)updateLabelTimer {
	if ([sbDNDFireDate timeIntervalSinceDate:[NSDate date]] <= 0 || !isDNDEnabled()) {
		[timeRemainingLabel removeFromSuperview];
		timeRemainingLabel = nil;
		[[CCDNDModuleContainerView containerView] setAlpha:1.0f];
    [labelTimer invalidate];
    labelTimer = nil;
    NSLog(@"omriku posting notif timer is over!");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"com.0xkuj.ccdndtimer.timerover" object:nil];
		return;
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