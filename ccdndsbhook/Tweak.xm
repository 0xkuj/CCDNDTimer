#include "../CCDNDTimer.h"
@interface SpringBoard
-(void)updateDNDTimer;
-(void)addDNDLabel;
@end

@interface CCUIContentModuleContainerView
- (void)setAlpha:(CGFloat)alpha;
- (CGRect)frame;
- (void)addSubview:(id)arg1;
- (id)containerView;
- (void)viewWillAppear:(BOOL)arg1;
@end

@interface NSTimer ()
- (NSTimeInterval)timeIntervalSinceDate:(NSDate *)anotherDate;
@end

@interface CCUIModuleCollectionViewController
// %new
-(void)addDNDLabel;
// %new
- (NSString *)timeFromSec:(int)seconds;
@end

%hook SpringBoard
NSTimer* sbDNDTimer;
NSNumber* sbDNDTimeLeft;
- (void)applicationDidFinishLaunching:(id)application {
  NSLog(@"omriku got back from respring! starting to check if file exists, if not nil");
  NSMutableDictionary* timerLeftDict = [[NSMutableDictionary alloc] initWithContentsOfFile:DND_TIMER_PLIST];
  if ([timerLeftDict objectForKey:@"DNDTimeLeft"]) {
      NSLog(@"omriku not nil! time left after respring is.. %@",[timerLeftDict objectForKey:@"DNDTimeLeft"]);
      sbDNDTimeLeft = [NSNumber numberWithInt:[[timerLeftDict objectForKey:@"DNDTimeLeft"] intValue]];
      NSLog(@"omriku updating sb dndtimeleft? :%@",sbDNDTimeLeft);
      if ([sbDNDTimeLeft intValue] > 0) {
          NSLog(@"omriku time left is bigger than 0! dndtimeleft? :%@",sbDNDTimeLeft);
          sbDNDTimer = [NSTimer scheduledTimerWithTimeInterval:10
                              target:self
                              selector:@selector(updateDNDTimer)
                              userInfo:nil
                              repeats:YES];
      }
  }
   %orig(application);
}

%new
-(void)updateDNDTimer {
  if ([[[NSClassFromString(@"CCDNDTimer") sharedInstance] getTimer] isValid]) {
      NSLog(@"omriku timer IS ON from the class! deactivating sb timer....");
      [sbDNDTimer invalidate];
      sbDNDTimer = nil;
      sbDNDTimeLeft = 0;
      return;
  }

  sbDNDTimeLeft = [NSNumber numberWithInt:[sbDNDTimeLeft intValue] - 1];
  NSLog(@"omriku sb timer has been called! time left.. %@ + updating settings!", sbDNDTimeLeft);
  if ([sbDNDTimeLeft intValue] <= 0) {
    [sbDNDTimer invalidate];
    sbDNDTimer = nil;
    disableDND();
    [[NSClassFromString(@"CCDNDTimer") sharedInstance] setSelected:NO];
  }
  NSMutableDictionary* settingsFile =  [[NSMutableDictionary alloc] init];
  [settingsFile setObject:sbDNDTimeLeft forKey:@"DNDTimeLeft"];
  [settingsFile writeToFile:DND_TIMER_PLIST atomically:YES];
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
  if ([sbDNDTimeLeft intValue] > 0) {
      [self addDNDLabel];
  }
	return;
}
//something is messed up.. you may need to save firedate AND THATS IT. YOU MAY NEED TO REFACTOR.
%new
-(void)addDNDLabel {
    CCDNDModuleContainerView = [moduleDictionary objectForKey:@"com.0xkuj.ccdndtimer"];
    dndFireDate = [NSDate dateWithTimeIntervalSinceNow:(20*60)];
    int timeDelta = [dndFireDate timeIntervalSinceDate:[NSDate date]];
    NSLog(@"omriku firedate for dnd: %@ and delta: %d",dndFireDate, timeDelta);
    if (timeDelta > 0) {
        [[CCDNDModuleContainerView containerView] setAlpha:0.35f];
        if (timeRemainingLabel) {
            [timeRemainingLabel removeFromSuperview];
            timeRemainingLabel = nil;
        }
        timeRemainingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [CCDNDModuleContainerView frame].size.width, [CCDNDModuleContainerView frame].size.height)];
        [timeRemainingLabel setText:[self timeFromSec:timeDelta]];
        [timeRemainingLabel setFont:[UIFont systemFontOfSize:12]];
        [timeRemainingLabel setTextColor:[UIColor whiteColor]];
        [timeRemainingLabel setTextAlignment:NSTextAlignmentCenter];
        [CCDNDModuleContainerView addSubview:timeRemainingLabel];
        NSLog(@"omriku before calling!!!!!!!!!!!!!");
        //wow timer is not fucking working.. figure this out.
        //next: connect the timer label directly when the timer starts
        //consider refactor: use only firedate instead of keeping track of minutes.. this is more proper
        //ok removing the timer from the timer worked. dunno wtf good night
        labelTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(updateLabelTimer) userInfo:nil repeats:YES];
    }

}

%new
- (void)updateLabelTimer {
  NSLog(@"omriku wtf returns? %f", [dndFireDate timeIntervalSinceDate:[NSDate date]]);
	if ([dndFireDate timeIntervalSinceDate:[NSDate date]] <= 0) {
		[timeRemainingLabel removeFromSuperview];
		timeRemainingLabel = nil;
		[[CCDNDModuleContainerView containerView] setAlpha:1.0f];
		return;
	} 
	[timeRemainingLabel setText:[self timeFromSec:[dndFireDate timeIntervalSinceDate:[NSDate date]]]];	
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
