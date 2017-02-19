#import <UIKit/UIKit.h>

@interface MPUNowPlayingMetadata
	@property (nonatomic,readonly) NSString * title; 
	@property (nonatomic,readonly) NSString * artist;
@end

@interface MPUNowPlayingController
	@property bool isPlaying;
	@property (nonatomic,readonly) NSString * nowPlayingAppDisplayID;
	@property (nonatomic,readonly) MPUNowPlayingMetadata * currentNowPlayingMetadata;
	@property (nonatomic,readonly) UIImage * currentNowPlayingArtwork;
@end

@interface JBBulletinManager : NSObject
	+(id)sharedInstance;
	-(id)showBulletinWithTitle:(NSString *)title message:(NSString *)message bundleID:(NSString *)bundleID;
	-(id)showBulletinWithTitle:(NSString *)title message:(NSString *)message bundleID:(NSString *)bundleID soundPath:(NSString *)soundPath;
	-(id)showBulletinWithTitle:(NSString *)title message:(NSString *)message bundleID:(NSString *)bundleID soundID:(int)inSoundID;
	-(id)showBulletinWithTitle:(NSString *)title message:(NSString *)message overrideBundleImage:(UIImage *)overridBundleImage;
	-(id)showBulletinWithTitle:(NSString *)title message:(NSString *)message overrideBundleImage:(UIImage *)overridBundleImage soundPath:(NSString *)soundPath;
	-(id)showBulletinWithTitle:(NSString *)title message:(NSString *)message overridBundleImage:(UIImage *)overridBundleImage soundID:(int)inSoundID;
	-(id)showBulletinWithTitle:(NSString *)title message:(NSString *)message bundleID:(NSString *)bundleID hasSound:(BOOL)hasSound soundID:(int)soundID vibrateMode:(int)vibrate soundPath:(NSString *)soundPath attachmentImage:(UIImage *)attachmentImage overrideBundleImage:(UIImage *)overrideBundleImage;
@end

%hook MPUNowPlayingController
	static NSString *cachedTitle;
	static NSString *artist;
	-(void)_updateCurrentNowPlaying{
		%orig;
		double delayInSeconds = 0.5;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			if(self.isPlaying && ([self.nowPlayingAppDisplayID isEqualToString:@"com.apple.Music"] || [self.nowPlayingAppDisplayID isEqualToString:@"com.spotify.client"]) && ![cachedTitle isEqualToString:self.currentNowPlayingMetadata.title]){
				cachedTitle = [self.currentNowPlayingMetadata.title copy];
				if([self.currentNowPlayingMetadata.artist length] > 1){
					artist = [NSString stringWithFormat: @"\nBy: %@", self.currentNowPlayingMetadata.artist];
				}else{
					artist = @"";
				}
				if(self.currentNowPlayingArtwork != nil){
					[[objc_getClass("JBBulletinManager") sharedInstance] showBulletinWithTitle:@"Now Playing" message:[NSString stringWithFormat: @"%@%@", self.currentNowPlayingMetadata.title, artist] bundleID:self.nowPlayingAppDisplayID hasSound:false soundID:0 vibrateMode:0 soundPath:@"" attachmentImage:self.currentNowPlayingArtwork overrideBundleImage:nil];
				}else{
					[[objc_getClass("JBBulletinManager") sharedInstance] showBulletinWithTitle:@"Now Playing" message:[NSString stringWithFormat: @"%@%@", self.currentNowPlayingMetadata.title, artist] bundleID:self.nowPlayingAppDisplayID];
				}
			}
		});
	}
%end
