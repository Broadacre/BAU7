//
//  AppDelegate.m
//  BAU7
//
//  Created by Dan Brooker on 8/6/21.
//

#import <GameController/GameController.h>
#import "BAU7Objects.h"
#import "BABitmap.h"
#import "Globals.h"
#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
        [center addObserverForName: GCControllerDidConnectNotification
                            object: nil
                             queue: nil
                        usingBlock: ^(NSNotification * note) {
                            GCController * controller = note.object;
                            printf( "ATTACHED: %s\n", controller.vendorName.UTF8String );
                        }
         ];
   
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
