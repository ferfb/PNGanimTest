//
//  PNGAnimatorAppDelegate.m
//  PNGAnimator
//
//  Created by Rodolfo Cartas on 21/09/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PNGAnimatorAppDelegate.h"

#import "PNGAnimatorViewController.h"
#import "ImageAnimatorViewController.h"

@implementation PNGAnimatorAppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;
@synthesize animatorViewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
     
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

- (void) startAnimator
{
	[viewController.view removeFromSuperview];
    
	self.animatorViewController = [ImageAnimatorViewController imageAnimatorViewController];
    
	// Init animator data
    
	NSArray *names = [ImageAnimatorViewController arrayWithNumberedNames:@"fondo_0"
                                                              rangeStart:1
                                                                rangeEnd:1439
                                                            suffixFormat:@"%04i.jpg"];
    
    NSArray *slNames = [ImageAnimatorViewController arrayWithNumberedNames:@"seq_0"
                                                              rangeStart:1
                                                                rangeEnd:191
                                                            suffixFormat:@"%04i.png"];
    
    NSMutableArray *filledNames = [[NSMutableArray alloc] initWithCapacity:[names count]];
    for (int i = 0; i < [names count]; i++) {
        [filledNames addObject:[slNames objectAtIndex:(i % [slNames count])]];
    }
    
	NSArray *URLs = [ImageAnimatorViewController arrayWithResourcePrefixedURLs:names];
    NSArray *slURLs = [ImageAnimatorViewController arrayWithResourcePrefixedURLs:filledNames];
    
	animatorViewController.animationOrientation = UIImageOrientationLeft; // Rotate 90 deg CCW
	animatorViewController.animationFrameDuration = ImageAnimator30FPS;
	animatorViewController.animationURLs = URLs;
    animatorViewController.secondLayerURLs = slURLs;
    animatorViewController.thirdLayerURLs = slURLs;
	animatorViewController.animationRepeatCount = 0;
    animatorViewController.animationAudioURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"musica" ofType:@"mp3"]];
    
    
	// Show animator before starting animation
	[_window addSubview:animatorViewController.view];
    
	// Register callbacks that will be invoked when the animation
	// starts, note that this callback is invoked at the start of
	// each animation loop.
    
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(animationDidStartNotification:) 
												 name:ImageAnimatorDidStartNotification 
											   object:animatorViewController];	
    
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(animationDidStopNotification:) 
												 name:ImageAnimatorDidStopNotification 
											   object:animatorViewController];
    
	// Kick off animation loop
    
	[animatorViewController startAnimating];
    /*[URLs release];
    [slURLs release];
    [filledNames release];
    [slNames release];
    [names release];*/
    
}	

- (void) stopAnimator
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:ImageAnimatorDidStartNotification
												  object:animatorViewController];
    
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:ImageAnimatorDidStopNotification
												  object:animatorViewController];	
    
	[animatorViewController stopAnimating];
    
	[animatorViewController.view removeFromSuperview];
    
	self.animatorViewController = nil;
    
	[_window addSubview:viewController.view];
}


// Invoked when an animation starts, note that this method
// can be invoked multiple times for an animation that loops.

- (void)animationDidStartNotification:(NSNotification*)notification {
	NSLog( @"animationDidStartNotification" );
}

// Invoked when an animation ends, note that this method
// can be invoked multiple times for an animation that loops,
// so explicitly stop only when we know there are no additional
// animation loops left to be done.

- (void)animationDidStopNotification:(NSNotification*)notification {
	NSLog( @"animationDidStopNotification" );
    
    if (self.animatorViewController.animationRepeatCount == 0) {  
        [self stopAnimator];
    }
}

- (void)dealloc
{
    [_window release];
    [_viewController release];
    [super dealloc];
}

@end
