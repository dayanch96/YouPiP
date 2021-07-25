#import "../PSHeader/iOSVersions.h"
#import "Header.h"
#import "../YouTubeHeader/YTHotConfig.h"
#import "../YouTubeHeader/YTSettingsViewController.h"
#import "../YouTubeHeader/YTSettingsSectionItem.h"
#import "../YouTubeHeader/YTSettingsSectionItemManager.h"
#import "../YouTubeHeader/YTAppSettingsSectionItemActionController.h"

extern BOOL PiPActivationMethod();
extern BOOL CompatibilityMode();
extern BOOL SampleBufferWork();
extern BOOL NonBackgroundable();
// extern BOOL PiPStartPaused();

NSString *currentVersion;
NSArray <NSString *> *PiPActivationMethods;

static NSString *YouPiPWarnVersionKey = @"YouPiPWarnVersionKey";

%hook YTSettingsViewController

- (void)setSectionItems:(NSMutableArray <YTSettingsSectionItem *> *)sectionItems forCategory:(NSInteger)category title:(NSString *)title titleDescription:(NSString *)titleDescription headerHidden:(BOOL)headerHidden {
    if (category == 1) {
        NSUInteger defaultPiPIndex = [sectionItems indexOfObjectPassingTest:^BOOL (YTSettingsSectionItem *item, NSUInteger idx, BOOL *stop) { 
            return item.settingItemId == 366;
        }];
        if (defaultPiPIndex != NSNotFound) {
            YTSettingsSectionItem *activationMethod = [[%c(YTSettingsSectionItem) alloc] initWithTitle:@"Use PiP Button" titleDescription:@"Adds a PiP button over the video control overlay to activate PiP instead of dismissing the app."];
            activationMethod.hasSwitch = activationMethod.switchVisible = YES;
            activationMethod.on = PiPActivationMethod();
            activationMethod.switchBlock = ^BOOL (YTSettingsCell *cell, BOOL enabled) {
                [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:PiPActivationMethodKey];
                return YES;
            };
            [sectionItems insertObject:activationMethod atIndex:defaultPiPIndex + 1];
            if (IS_IOS_BETWEEN_EEX(iOS_14_0, iOS_15_0)) {
                YTSettingsSectionItem *sampleBuffer = [[%c(YTSettingsSectionItem) alloc] initWithTitle:@"PiP Sample Buffer Hack" titleDescription:@"Implements PiP sample buffering based on iOS 15.0b2, which should reduce the chance of getting playback speedup bug. Turn off this option if you face weird issues. App restart is required."];
                sampleBuffer.hasSwitch = sampleBuffer.switchVisible = YES;
                sampleBuffer.on = SampleBufferWork();
                sampleBuffer.switchBlock = ^BOOL (YTSettingsCell *cell, BOOL enabled) {
                    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:SampleBufferWorkKey];
                    return YES;
                };
                [sectionItems insertObject:sampleBuffer atIndex:defaultPiPIndex + 1];
            }
            if ([currentVersion compare:@"15.33.4" options:NSNumericSearch] == NSOrderedDescending) {
                YTSettingsSectionItem *legacyPiP = [[%c(YTSettingsSectionItem) alloc] initWithTitle:@"Legacy PiP" titleDescription:@"Uses AVPlayerLayer where there's no playback speed bug. This also removes UHD video quality options (2K/4K) from any videos and YTUHD tweak cannot fix this. PiP button will be forcefully enabled. App restart is required."];
                legacyPiP.hasSwitch = legacyPiP.switchVisible = YES;
                legacyPiP.on = CompatibilityMode();
                legacyPiP.switchBlock = ^BOOL (YTSettingsCell *cell, BOOL enabled) {
                    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:CompatibilityModeKey];
                    return YES;
                };
                [sectionItems insertObject:legacyPiP atIndex:defaultPiPIndex + 1];
            }
            YTAppSettingsSectionItemActionController *sectionItemActionController = [self valueForKey:@"_sectionItemActionController"];
            YTSettingsSectionItemManager *sectionItemManager = [sectionItemActionController valueForKey:@"_sectionItemManager"];
            YTHotConfig *hotConfig = [sectionItemManager valueForKey:@"_hotConfig"];
            YTIIosMediaHotConfig *iosMediaHotConfig = [[[hotConfig hotConfigGroup] mediaHotConfig] iosMediaHotConfig];
            if ([iosMediaHotConfig respondsToSelector:@selector(setEnablePipForNonBackgroundableContent:)]) {
                YTSettingsSectionItem *nonBackgroundable = [[%c(YTSettingsSectionItem) alloc] initWithTitle:@"Non-backgroundable PiP" titleDescription:@"Enables PiP for non-backgroundable content."];
                nonBackgroundable.hasSwitch = nonBackgroundable.switchVisible = YES;
                nonBackgroundable.on = NonBackgroundable();
                nonBackgroundable.switchBlock = ^BOOL (YTSettingsCell *cell, BOOL enabled) {
                    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:NonBackgroundableKey];
                    return YES;
                };
                [sectionItems insertObject:nonBackgroundable atIndex:defaultPiPIndex + 1];
            }
            // if (IS_IOS_OR_NEWER(iOS_14_0)) {
            //     YTSettingsSectionItem *startPaused = [[%c(YTSettingsSectionItem) alloc] initWithTitle:@"PiP starts paused" titleDescription:@"When PiP is activated, it's paused by default."];
            //     startPaused.hasSwitch = startPaused.switchVisible = YES;
            //     startPaused.on = PiPStartPaused();
            //     startPaused.switchBlock = ^BOOL (YTSettingsCell *cell, BOOL enabled) {
            //         [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:PiPStartPausedKey];
            //         return YES;
            //     };
            //     [sectionItems insertObject:startPaused atIndex:defaultPiPIndex + 1];
            // }
        }
    }
    %orig(sectionItems, category, title, titleDescription, headerHidden);
}

%end

%ctor {
    NSBundle *bundle = [NSBundle mainBundle];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    currentVersion = [bundle infoDictionary][(__bridge NSString *)kCFBundleVersionKey];
    PiPActivationMethods = @[@"On App Dismiss", @"On PiP button tap"];
    if (![defaults boolForKey:YouPiPWarnVersionKey]) {
        if ([currentVersion compare:@(OS_STRINGIFY(MIN_YOUTUBE_VERSION)) options:NSNumericSearch] != NSOrderedAscending) {
            UIAlertController *warning = [UIAlertController alertControllerWithTitle:@"YouPiP" message:[NSString stringWithFormat:@"YouTube version %@ is not tested and may not be supported by YouPiP, please upgrade YouTube to at least version %s", currentVersion, OS_STRINGIFY(MIN_YOUTUBE_VERSION)] preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
            [warning addAction:action];
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:warning animated:YES completion:nil];
            [defaults setBool:YES forKey:YouPiPWarnVersionKey];
        }
    }
    %init;
}