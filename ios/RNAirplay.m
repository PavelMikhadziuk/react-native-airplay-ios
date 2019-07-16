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

    AVAudioSession *sharedInstance = [AVAudioSession sharedInstance];
    NSLog(@"is setCategory %d", [sharedInstance setCategory:AVAudioSessionCategoryPlayAndRecord error:nil]);
    NSLog(@"is setMode %d", [sharedInstance setMode:AVAudioSessionModeDefault error:nil]);
    NSLog(@"is overrideOutputAudioPort %d", [sharedInstance overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:(nil)]);
    NSLog(@"is setActive %d", [sharedInstance setActive:YES error:nil]);

    for (AVAudioSessionPortDescription *outputDesc in [[sharedInstance currentRoute] outputs]) {
        NSLog(@"sharedInstance: \n outputDesc - %@", outputDesc);
        NSLog(@"portType - %@; portType - %@; uid - %@;", outputDesc.portName, outputDesc.portType, outputDesc.UID);
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
