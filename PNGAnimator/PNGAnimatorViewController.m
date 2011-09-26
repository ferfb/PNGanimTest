//
//  PNGAnimatorViewController.m
//  PNGAnimator
//
//  Created by Rodolfo Cartas on 21/09/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PNGAnimatorViewController.h"
#import "PNGAnimatorAppDelegate.h"


@implementation PNGAnimatorViewController

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return NO;
}

- (IBAction) startButtonPress:(id)sender
{
	PNGAnimatorAppDelegate *appDelagate = [[UIApplication sharedApplication] delegate];
	
	[appDelagate startAnimator];
}


@end
