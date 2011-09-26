//
//  PNGAnimatorAppDelegate.h
//  PNGAnimator
//
//  Created by Rodolfo Cartas on 21/09/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PNGAnimatorViewController;
@class ImageAnimatorViewController;

@interface PNGAnimatorAppDelegate : NSObject <UIApplicationDelegate> {
    PNGAnimatorViewController *viewController;
    ImageAnimatorViewController *animatorViewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet PNGAnimatorViewController *viewController;

@property (nonatomic, retain) ImageAnimatorViewController *animatorViewController;

- (void) startAnimator;

- (void) stopAnimator;

@end
