@interface SpringBoard
-(void)updateDNDTimer;
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