#import <UIKit/UIKit.h>

@interface SpringBoard
-(id)_accessibilityFrontMostApplication;
@end

@interface UIApplication (myTweak)
+(id)sharedApplication;
- (id)bundleIdentifier;
@end

@interface SBLockScreenManager
+(SBLockScreenManager *)sharedInstance;
-(BOOL)isUILocked;
@end

@interface MPUNowPlayingController
	@property bool isPlaying;
	@property (nonatomic,readonly) NSString * nowPlayingAppDisplayID;
	@property (nonatomic,readonly) UIImage * currentNowPlayingArtwork;
	@property (nonatomic,readonly) NSDictionary * currentNowPlayingInfo;
@end

@interface JBBulletinManager : NSObject
	+(id)sharedInstance;
	-(id)showBulletinWithTitle:(NSString *)title message:(NSString *)message bundleID:(NSString *)bundleID;
	-(id)showBulletinWithTitle:(NSString *)title message:(NSString *)message bundleID:(NSString *)bundleID hasSound:(BOOL)hasSound soundID:(int)soundID vibrateMode:(int)vibrate soundPath:(NSString *)soundPath attachmentImage:(UIImage *)attachmentImage overrideBundleImage:(UIImage *)overrideBundleImage;
@end

%hook MPUNowPlayingController
	static NSString *cachedTitle;
	static NSString *artist;
	static NSString *album;
	-(void)_updateCurrentNowPlaying{
		%orig;
		NSString *settingsPath = @"/var/mobile/Library/Preferences/com.gilshahar7.notifymusicprefs.plist";
		NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];
		BOOL enablewhilelocked = [[prefs objectForKey:@"enablewhilelocked"] boolValue];
		BOOL showalbumname = [[prefs objectForKey:@"showalbumname"] boolValue];
		BOOL enableinapp = [[prefs objectForKey:@"enableinapp"] boolValue];
		
		double delayInSeconds = 0.5;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			if(![cachedTitle isEqualToString:self.currentNowPlayingInfo[@"kMRMediaRemoteNowPlayingInfoTitle"]]){
				cachedTitle = [self.currentNowPlayingInfo[@"kMRMediaRemoteNowPlayingInfoTitle"] copy];
				NSString *frontMost = [[(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication] bundleIdentifier];
				if((enablewhilelocked || (![[%c(SBLockScreenManager) sharedInstance] isUILocked])) && self.isPlaying){
					if(enableinapp || (![self.nowPlayingAppDisplayID isEqualToString:frontMost])){
						artist = [NSString stringWithFormat: @"\n%@", self.currentNowPlayingInfo[@"kMRMediaRemoteNowPlayingInfoArtist"]];
						
						if([self.currentNowPlayingInfo[@"kMRMediaRemoteNowPlayingInfoAlbum"] length] > 1 && showalbumname){
								album = self.currentNowPlayingInfo[@"kMRMediaRemoteNowPlayingInfoAlbum"];
						}else{
								album = @"Now Playing";
						}
						if(self.currentNowPlayingArtwork != nil){
							[[objc_getClass("JBBulletinManager") sharedInstance] showBulletinWithTitle:album message:[NSString stringWithFormat: @"%@%@", self.currentNowPlayingInfo[@"kMRMediaRemoteNowPlayingInfoTitle"], artist] bundleID:self.nowPlayingAppDisplayID hasSound:false soundID:0 vibrateMode:0 soundPath:@"" attachmentImage:self.currentNowPlayingArtwork overrideBundleImage:nil];
						}else{
							[[objc_getClass("JBBulletinManager") sharedInstance] showBulletinWithTitle:album message:[NSString stringWithFormat: @"%@%@", self.currentNowPlayingInfo[@"kMRMediaRemoteNowPlayingInfoTitle"], artist] bundleID:self.nowPlayingAppDisplayID];
						}
					}
				}
			}
		});
	}
%end
