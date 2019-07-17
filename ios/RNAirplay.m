#import "RNAirplay.h"
#import "RNAirplayManager.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>


@implementation RNAirplay
@synthesize bridge = _bridge;

- (dispatch_queue_t)methodQueue {
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(startScan)
{
    // Add observer which will call "deviceChanged" method when audio outpout changes
    // e.g. headphones connect / disconnect
    [[NSNotificationCenter defaultCenter]
    addObserver:self
    selector: @selector(deviceChanged:)
    name:AVAudioSessionRouteChangeNotification
    object:[AVAudioSession sharedInstance]];

    // Also call sendEventAboutConnectedDevice method immediately to send currently connected device
    // at the time of startScan
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self sendEventAboutConnectedDevice];
    });
}

RCT_EXPORT_METHOD(disconnect)
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

RCT_EXPORT_METHOD(disconnect)
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

RCT_REMAP_METHOD(changeRouteFromAirplay, changeRouteFromAirplayWithResolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    AVAudioSession *sharedInstance = [AVAudioSession sharedInstance];

    for (AVAudioSessionPortDescription *inputSource in [sharedInstance availableInputs]) {
        RCTLogInfo(@"inputSource = %@", inputSource);
    }
    BOOL isSetCategory = [sharedInstance setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    RCTLogInfo(@"is setCategory %d", isSetCategory);
    BOOL isSetMode = [sharedInstance setMode:AVAudioSessionModeDefault error:nil];
    RCTLogInfo(@"is setMode %d", isSetMode);
    BOOL isOverrideOutputAudioPort = [sharedInstance overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:(nil)];
    RCTLogInfo(@"is overrideOutputAudioPort %d", isOverrideOutputAudioPort);
    BOOL isSetActive = [sharedInstance setActive:YES error:nil];
    RCTLogInfo(@"is setActive %d", isSetActive);

    for (AVAudioSessionPortDescription *outputDesc in [[sharedInstance currentRoute] outputs]) {
        RCTLogInfo(@"sharedInstance: \n outputDesc - %@", outputDesc);
        RCTLogInfo(@"portType - %@; portType - %@; uid - %@;", outputDesc.portName, outputDesc.portType, outputDesc.UID);
    }
    NSDictionary *details = @{@"isSetCategory": @(isSetCategory), @"isSetMode": @(isSetMode), @"isOverrideOutputAudioPort": @(isOverrideOutputAudioPort), @"isSetActive": @(isSetActive)};
    if (isSetCategory && isSetMode && isOverrideOutputAudioPort && isSetActive) {
        resolve(details);
    } else {
        NSError *error = [NSError errorWithDomain:@"com.brainfm" code:14 userInfo:[NSDictionary dictionaryWithObject:@"Couldn't change route" forKey:NSLocalizedDescriptionKey]];
        reject(@"no_events", [NSString stringWithFormat:@"Details is %@", details], error);
    }
}


- (void)deviceChanged:(NSNotification *)sender {
    // Get current audio output
    [self sendEventAboutConnectedDevice];
}

// Gets current devices and sends an event to React Native with information about it
- (void) sendEventAboutConnectedDevice;
{
    AVAudioSessionRouteDescription *currentRoute = [[AVAudioSession sharedInstance] currentRoute];
    NSString *deviceName;
    NSString *portType;
    NSMutableArray *devices = [NSMutableArray array];
    for (AVAudioSessionPortDescription * output in currentRoute.outputs) {
        deviceName = output.portName;
        portType = output.portType;
        NSDictionary *device = @{ @"deviceName" : deviceName, @"portType" : portType};
        [devices addObject: device];
    }
    [self sendEventWithName:@"deviceConnected" body:@{@"devices": devices}];
}

- (NSArray<NSString *> *)supportedEvents {
    return @[@"deviceConnected"];
}

@end
