#import "notify.h"
#import <UIKit/UIKit.h>
#import <MediaRemote/MediaRemote.h>

@interface JBBulletinManager : NSObject
+(id)sharedInstance;
-(id)showBulletinWithTitle:(NSString *)title message:(NSString *)message bundleID:(NSString *)bundleID;
-(id)showBulletinWithTitle:(NSString *)title message:(NSString *)message bundleID:(NSString *)bundleID hasSound:(BOOL)hasSound soundID:(int)soundID vibrateMode:(int)vibrate soundPath:(NSString *)soundPath attachmentImage:(UIImage *)attachmentImage overrideBundleImage:(UIImage *)overrideBundleImage;
@end

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
@property (nonatomic,readonly) double currentElapsed;
@property (nonatomic,readonly) double currentDuration;
-(void)_updateCurrentNowPlaying;
-(void)_updatePlaybackState;
-(void)setShouldUpdateNowPlayingArtwork:(BOOL)arg1 ;
@end

@interface SBMediaController
@property (retain) NSDictionary * currentNowPlayingInfo;
-(id/*SBApplication **/)nowPlayingApplication;
-(void)setNowPlayingInfo:(NSDictionary *)arg1 ;
-(BOOL)isPlaying;
@end

@interface NotifyMusic : NSObject {
    int token;
    
    BOOL notifyMusicPrefsLoaded;
    BOOL enablewhilelocked;
    BOOL showalbumname;
    BOOL albumastitle;
    BOOL enableinapp;
    BOOL showagainwhenartavail;
    
    BOOL isInProgress;
    SBMediaController *cachedMediaController;
    MPUNowPlayingController *cachedNowPlayingController;
    NSString *cachedMediaInfo;
    double durationMod;
    BOOL isArtworkUpdated;
}
+(NotifyMusic *)sharedInstance;
-(void)dealloc;
-(void)_updateNotifyMusicPrefs;
-(BOOL)isPlaying;
-(NSString *)nowPlayingAppDisplayID;
-(UIImage *)currentNowPlayingArtwork;
-(NSDictionary *)currentNowPlayingInfo;
-(double)currentDuration;
-(BOOL)_shouldShowNotifyMusic;
-(void)_showNotifyMusic;
@end

@implementation NotifyMusic
+(NotifyMusic *)sharedInstance {
    static NotifyMusic *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

-(id)init {
    if (self = [super init]) {
        notify_register_dispatch("com.gilshahar7.notifymusicprefs", &token, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(int token) {
            [self _updateNotifyMusicPrefs];
        });
    }
    return self;
}

-(void)dealloc {
    notify_cancel(token);
    [super dealloc];
}

-(void)_updateNotifyMusicPrefs {
    NSString *settingsPath = @"/var/mobile/Library/Preferences/com.gilshahar7.notifymusicprefs.plist";
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];
    enablewhilelocked = [[prefs objectForKey:@"enablewhilelocked"] boolValue];
    showalbumname = [[prefs objectForKey:@"showalbumname"] boolValue];
    albumastitle = [[prefs objectForKey:@"albumastitle"] boolValue];
    enableinapp = [[prefs objectForKey:@"enableinapp"] boolValue];
    showagainwhenartavail = [[prefs objectForKey:@"showagainwhenartavail"] boolValue];
}

-(void)_updateDependencyInjectionWithMC:(SBMediaController *)mediaController NPC:(MPUNowPlayingController *)nowPlayingController {
    cachedMediaController = mediaController;
    cachedNowPlayingController = nowPlayingController;
}

-(BOOL)isPlaying {
    if (cachedNowPlayingController) return [cachedNowPlayingController isPlaying];
    else if (cachedMediaController) return [cachedMediaController isPlaying];
    return NO;
}

-(NSString *)nowPlayingAppDisplayID {
    if (cachedNowPlayingController) return [cachedNowPlayingController nowPlayingAppDisplayID];
    else if (cachedMediaController) return [[cachedMediaController nowPlayingApplication] bundleIdentifier];
    return NULL;
}

-(UIImage *)currentNowPlayingArtwork {
    if (cachedNowPlayingController) {
        [cachedNowPlayingController setShouldUpdateNowPlayingArtwork:YES];
        return [cachedNowPlayingController currentNowPlayingArtwork];
    }
    else if (cachedMediaController) {
        if (![cachedMediaController currentNowPlayingInfo]) return NULL;
        NSData *artworkData = [cachedMediaController currentNowPlayingInfo][(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtworkData];
        if (!artworkData) return NULL;
        return [UIImage imageWithData:artworkData];
    }
    return NULL;
}

-(NSDictionary *)currentNowPlayingInfo {
    if (cachedNowPlayingController) return [cachedNowPlayingController currentNowPlayingInfo];
    else if (cachedMediaController) return [cachedMediaController currentNowPlayingInfo];
    return NULL;
}

-(double)currentDuration {
    if (cachedNowPlayingController) return [cachedNowPlayingController currentDuration];
    else if (cachedMediaController) {
        if (![cachedMediaController currentNowPlayingInfo]) return 0;
        if (![cachedMediaController currentNowPlayingInfo][(__bridge NSString *)kMRMediaRemoteNowPlayingInfoDuration]) return 0;
        return [[cachedMediaController currentNowPlayingInfo][(__bridge NSString *)kMRMediaRemoteNowPlayingInfoDuration] doubleValue];
    }
    return 0;
}

-(BOOL)_shouldShowNotifyMusic {
    if (!notifyMusicPrefsLoaded) [self _updateNotifyMusicPrefs];
    NSString *frontMost = [[(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication] bundleIdentifier];
    if(!enablewhilelocked && [[%c(SBLockScreenManager) sharedInstance] isUILocked]) return NO;
    if(!enableinapp && [self.nowPlayingAppDisplayID isEqualToString:frontMost])
        return NO;
    return YES;
}

-(void)_showNotifyMusic {
    //%orig;
    //if (![self _shouldShowNotifyMusic]) return;
    
    if (isInProgress) return;
    if (!self.isPlaying) return;
    double currentDuration = self.currentDuration;
    if (!currentDuration || currentDuration <= 0) return;
    isInProgress = YES;
    
    NSString *_title = self.currentNowPlayingInfo[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoTitle];
    NSString *_artist = self.currentNowPlayingInfo[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtist];
    NSString *_album = self.currentNowPlayingInfo[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoAlbum];
    NSString *_mediaInfo = [NSString stringWithFormat:@"%@:%@:%@:%@:%d", self.nowPlayingAppDisplayID, _title, _artist, _album, (int)currentDuration];
    if (![_mediaInfo isEqualToString:cachedMediaInfo]) durationMod = currentDuration - (int)currentDuration;
    
    BOOL hasArtwork = [self.currentNowPlayingInfo[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtworkMIMEType] containsString:@"image"];
    double delayInSeconds = 0.5;
    if (hasArtwork) delayInSeconds = 2;
    if (hasArtwork && self.currentNowPlayingArtwork == nil) delayInSeconds = 4;
    if (currentDuration - (int)currentDuration != durationMod) delayInSeconds = 8;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        NSString *nowPlayingAppDisplayID = self.nowPlayingAppDisplayID;
        NSString *title = self.currentNowPlayingInfo[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoTitle];
        NSString *artist = self.currentNowPlayingInfo[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtist];
        NSString *album = self.currentNowPlayingInfo[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoAlbum];
        NSString *mediaInfo = [NSString stringWithFormat:@"%@:%@:%@:%@:%d", nowPlayingAppDisplayID, title, artist, album, (int)self.currentDuration];
        if (![mediaInfo isEqualToString:_mediaInfo]) return;
        UIImage *artwork = self.currentNowPlayingArtwork;
        if ([mediaInfo isEqualToString:cachedMediaInfo] && (artwork == nil || !showagainwhenartavail || isArtworkUpdated)) return;
        //if (artwork) artwork = [artwork copy];
        cachedMediaInfo = [mediaInfo copy];
        isArtworkUpdated = artwork != nil;
        if (![self _shouldShowNotifyMusic]) return;
        if(!showalbumname){
            album = @"Now Playing";
        }
        if (showalbumname) {
            NSString *_title, *_message;
            if (albumastitle) {
                _title = album;
                _message = [NSString stringWithFormat: @"%@\n%@", title, artist];
            } else {
                _title = title;
                _message = [NSString stringWithFormat: @"%@\n%@", artist, album];
            }
            if(artwork != nil){
                [[%c(JBBulletinManager) sharedInstance] showBulletinWithTitle:_title message:_message bundleID:nowPlayingAppDisplayID hasSound:false soundID:0 vibrateMode:0 soundPath:@"" attachmentImage:artwork overrideBundleImage:nil];
            }else{
                [[%c(JBBulletinManager) sharedInstance] showBulletinWithTitle:_title message:_message bundleID:nowPlayingAppDisplayID];
            }
        } else {
            if ([album length] <= 0) {
                album = @"Now Playing";
            }
            if(artwork != nil){
                [[%c(JBBulletinManager) sharedInstance] showBulletinWithTitle:album message:[NSString stringWithFormat: @"%@\n%@", title, artist] bundleID:nowPlayingAppDisplayID hasSound:false soundID:0 vibrateMode:0 soundPath:@"" attachmentImage:artwork overrideBundleImage:nil];
            }else{
                [[%c(JBBulletinManager) sharedInstance] showBulletinWithTitle:album message:[NSString stringWithFormat: @"%@\n%@", title, artist] bundleID:nowPlayingAppDisplayID];
            }
        }
    });
    isInProgress = NO;
}
@end

%hook MPUNowPlayingController
static int token;

-(id)init {
    self = %orig;
    if (self) {
        notify_register_dispatch("com.gilshahar7.notifymusic", &token, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(int token) {
            [self _updatePlaybackState];
        });
    }
    return self;
}

-(void)dealloc {
    notify_cancel(token);
    %orig;
}

/*-(void)_updateCurrentNowPlaying{
    %orig;
    [[NotifyMusic sharedInstance] _updateDependencyInjectionWithMC:nil NPC:self];
    [[NotifyMusic sharedInstance] _showNotifyMusic];
}*/

-(void)_updatePlaybackState {
    %orig;
    [[NotifyMusic sharedInstance] _updateDependencyInjectionWithMC:nil NPC:self];
    [[NotifyMusic sharedInstance] _showNotifyMusic];
}
%end

%hook SBMediaController
%property (retain) NSDictionary * currentNowPlayingInfo;

-(void)setNowPlayingInfo:(NSDictionary *)arg1 {
    %orig;
    if (UIDevice.currentDevice.systemVersion.floatValue >= 11.0) {
        MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef nowPlayingInfo) {
            if (self.currentNowPlayingInfo) [self.currentNowPlayingInfo release];
            self.currentNowPlayingInfo = [(__bridge NSDictionary *)nowPlayingInfo copy];
            [[NotifyMusic sharedInstance] _updateDependencyInjectionWithMC:self NPC:nil];
            [[NotifyMusic sharedInstance] _showNotifyMusic];
        });
    }
    else notify_post("com.gilshahar7.notifymusic");
}

-(void)_nowPlayingAppIsPlayingDidChange {
    %orig;
    [self setNowPlayingInfo:[self _nowPlayingInfo]];
}
%end
