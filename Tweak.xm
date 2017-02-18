#import <AudioToolbox/AudioToolbox.h>
#import <AudioToolbox/AudioServices.h>
#import <UIKit/UIKit.h>

@interface MPUNowPlayingMetadata
@property (nonatomic,readonly) NSString * title; 
@property (nonatomic,readonly) NSString * artist;
@end

@interface MPUNowPlayingController
@property bool isPlaying;
@property (nonatomic,readonly) NSString * nowPlayingAppDisplayID;
@property (nonatomic,readonly) MPUNowPlayingMetadata * currentNowPlayingMetadata;
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
-(void)_updateCurrentNowPlaying{
%orig;


double delayInSeconds = 0.5;
dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
dispatch_after(popTime, dispatch_get_main_queue(), ^(void){

if(self.isPlaying && ([self.nowPlayingAppDisplayID isEqualToString:@"com.apple.Music"] || [self.nowPlayingAppDisplayID isEqualToString:@"com.spotify.client"]) && ![cachedTitle isEqualToString:self.currentNowPlayingMetadata.title]){

cachedTitle = [self.currentNowPlayingMetadata.title copy];


[[objc_getClass("JBBulletinManager") sharedInstance] showBulletinWithTitle:self.currentNowPlayingMetadata.title message:self.currentNowPlayingMetadata.artist bundleID:self.nowPlayingAppDisplayID];


}

});
}
%end
