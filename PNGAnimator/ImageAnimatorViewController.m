//
//  ImageAnimatorViewController.m
//  PNGAnimatorDemo
//
//  Created by Moses DeJong on 2/5/09.
//

#import "ImageAnimatorViewController.h"

#import <QuartzCore/QuartzCore.h>

#import <AVFoundation/AVAudioPlayer.h>

#import "FrameReaderOperation.h"

#define BUFFER_SECONDS 2

@implementation ImageAnimatorViewController

@synthesize animationURLs;
@synthesize animationFrameDuration;
@synthesize animationNumFrames;
@synthesize animationRepeatCount;
@synthesize imageView;
@synthesize animationData;
@synthesize animationTimer;
@synthesize animationStep;
@synthesize animationDuration;
@synthesize animationOrientation;
@synthesize secondLayer;
@synthesize secondLayerURLs;
@synthesize thirdLayer;
@synthesize thirdLayerURLs;
@synthesize animationAudioURL, avAudioPlayer;
@synthesize animationBuffer;

- (id)init {
    self = [super init];
    if (self) {
        self->_queue = [[NSOperationQueue alloc] init];
        assert(self->_queue != nil);
        self.animationBuffer = nil;
    }
    return self;
}

- (void)dealloc {
	// This object can't be deallocated while animating, this could
	// only happen if user code incorrectly dropped the last ref.
    
	NSAssert([self isAnimating] == FALSE, @"dealloc while still animating");

    // TODO Quitar observadores
    [self.animationBuffer release];
    
    self.animationURLs = nil;
    self.imageView = nil;
    self.animationData = nil;
    self.animationTimer = nil;
    
    [super dealloc];
}

+ (ImageAnimatorViewController*) imageAnimatorViewController
{
  return [[[ImageAnimatorViewController alloc] init] autorelease];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  // Return YES for supported orientations
  return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.

- (void)loadView {
	UIView *myView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
	[myView autorelease];
	self.view = myView;

	// FIXME: Additional Supported Orientations

	if (animationOrientation == UIImageOrientationUp) {
		// No-op
	} else if (animationOrientation == UIImageOrientationLeft) {
		// 90 deg CCW
		[self rotateToLandscape];
	} else if (animationOrientation == UIImageOrientationRight) {
		// 90 deg CW
		[self rotateToLandscapeRight];		
	} else {
		NSAssert(FALSE,@"Unsupported animationOrientation");
	}

	// Foreground animation images

	UIImageView *myImageView = [[UIImageView alloc] initWithFrame:self.view.frame];
	[myImageView autorelease];
	self.imageView = myImageView;
    
    UIImageView *secondLayeImageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    [secondLayeImageView autorelease];
    self.secondLayer = secondLayeImageView;

    UIImageView *thirdLayeImageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    [thirdLayeImageView autorelease];
    self.thirdLayer = thirdLayeImageView;
    
	// Animation data should have already been loaded into memory as a result of
	// setting the animationURLs property

	NSAssert(animationURLs, @"animationURLs was not defined");
	NSAssert([animationURLs count] > 1, @"animationURLs must include at least 2 urls");
	NSAssert(animationFrameDuration, @"animationFrameDuration was not defined");

    // Load animationData by reading from animationURLs
    
     //leer los primeros segundos del buffer
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionaryWithCapacity:[animationURLs count]];
        
    NSMutableArray *muArray = [NSMutableArray arrayWithCapacity:[animationURLs count]];
    for (int i = 0; i < BUFFER_SECONDS * 1 / animationFrameDuration ; i++) {
        // first layer
        NSURL* aURL = [animationURLs objectAtIndex:i];
        NSString *urlKey = aURL.path;
        NSData *dataForKey = [dataDict objectForKey:urlKey];
        
        if (dataForKey == nil) {
            dataForKey = [NSData dataWithContentsOfURL:aURL];
            NSAssert(dataForKey, @"dataForKey");
            
            [dataDict setObject:dataForKey forKey:urlKey];
        }
        
        // second layer
        aURL = [secondLayerURLs objectAtIndex:i];
        urlKey = aURL.path;
        NSData *secondDataForKey = [dataDict objectForKey:urlKey];
        if(secondDataForKey == nil) {
            secondDataForKey = [NSData dataWithContentsOfURL:aURL];
            [dataDict setObject:secondDataForKey forKey:urlKey];
        }
        
        // third layer
        aURL = [thirdLayerURLs objectAtIndex:i];
        urlKey = aURL.path;
        NSData *thirdDataForKey = [dataDict objectForKey:urlKey];
        if(thirdDataForKey == nil) {
            thirdDataForKey = [NSData dataWithContentsOfURL:aURL];
            [dataDict setObject:thirdDataForKey forKey:urlKey];
        }
        
        NSArray *frameArray = [[NSArray alloc] initWithObjects:dataForKey, secondDataForKey, thirdDataForKey, nil]; 
        [muArray addObject:frameArray];
        [frameArray release];
    }   
    self.animationData = [NSArray arrayWithArray:muArray];
    framesRead = BUFFER_SECONDS * 1 / animationFrameDuration;
    
	int numFrames = [animationURLs count];
	float duration = animationFrameDuration * numFrames;

	self->animationNumFrames = numFrames;
	self.animationDuration = duration;

	[self.view addSubview:imageView];
    [self.view addSubview:secondLayer];

	// Display first frame of image animation

	self.animationStep = 0;

	[self animationShowFrame: animationStep];

	self.animationStep = animationStep + 1;

	if (animationAudioURL != nil) {
		AVAudioPlayer *avPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:animationAudioURL
																		 error:nil];
    [avPlayer autorelease];
		NSAssert(avPlayer, @"AVAudioPlayer could not be allocated");
		self.avAudioPlayer = avPlayer;

		[avAudioPlayer prepareToPlay];		
	}
}

// Create an array of file/resource names with the given filename prefix,
// the file names will have an integer appended in the range indicated
// by the rangeStart and rangeEnd arguments. The suffixFormat argument
// is a format string like "%02i.png", it must format an integer value
// into a string that is appended to the file/resource string.
//
// For example: [createNumberedNames:@"Image" rangeStart:1 rangeEnd:3 rangeFormat:@"%02i.png"]
//
// returns: {"Image01.png", "Image02.png", "Image03.png"}

+ (NSArray*) arrayWithNumberedNames:(NSString*)filenamePrefix
							  rangeStart:(NSInteger)rangeStart
								rangeEnd:(NSInteger)rangeEnd
							 suffixFormat:(NSString*)suffixFormat
{
	NSMutableArray *numberedNames = [[NSMutableArray alloc] initWithCapacity:40];

	for (int i = rangeStart; i <= rangeEnd; i++) {
		NSString *suffix = [NSString stringWithFormat:suffixFormat, i];
		NSString *filename = [NSString stringWithFormat:@"%@%@", filenamePrefix, suffix];

		[numberedNames addObject:filename];
	}

	NSArray *newArray = [NSArray arrayWithArray:numberedNames];
	[numberedNames release];
	return newArray;
}

// Given an array of resource names (as returned by arrayWithNumberedNames)
// create a new array that contains these resource names prefixed as
// resource paths and wrapped in a NSURL object.

+ (NSArray*) arrayWithResourcePrefixedURLs:(NSArray*)inNumberedNames
{
	NSMutableArray *URLs = [[NSMutableArray alloc] initWithCapacity:[inNumberedNames count]];
	NSBundle* appBundle = [NSBundle mainBundle];

	for ( NSString* path in inNumberedNames ) {
		NSString* resPath = [appBundle pathForResource:path ofType:nil];	
		NSURL* aURL = [NSURL fileURLWithPath:resPath];

		[URLs addObject:aURL];
	}

	NSArray *newArray = [NSArray arrayWithArray:URLs];
	[URLs release];
	return newArray;
}

- (void) rotateToPortrait
{
	float angle = 0;  //rotate 0°
	self.view.layer.transform = CATransform3DMakeRotation(angle, 0, 0.0, 1.0);
}

- (void) rotateToLandscape
{
	float angle = M_PI / 2;  //rotate CCW 90°, or π/2 radians
	self.view.layer.transform = CATransform3DMakeRotation(angle, 0, 0.0, 1.0);
}

- (void) rotateToLandscapeRight
{
	float angle = -1 * (M_PI / 2);  //rotate CW 90°, or -π/2 radians
	self.view.layer.transform = CATransform3DMakeRotation(angle, 0, 0.0, 1.0);
}

- (void)launchFrameBuffering {
    // lanzar carga del buffer
    // comenzar desde framesread
      if (framesRead < self.animationNumFrames) {
        int framesToReadFinalIndex = framesRead + (BUFFER_SECONDS * 1 / animationFrameDuration);
        NSMutableArray *urlsToReadFirstLayer = [[NSMutableArray alloc] init];
        NSMutableArray *urlsToReadSecondLayer = [[NSMutableArray alloc] init];
        NSMutableArray *urlsToReadThirdLayer = [[NSMutableArray alloc] init];
        NSLog(@"Number of frames %d", self.animationNumFrames);
        for (int i = framesRead; i < framesToReadFinalIndex && i < self.animationNumFrames; i++) {
            [urlsToReadFirstLayer addObject:[animationURLs objectAtIndex:i]];
            [urlsToReadSecondLayer addObject:[secondLayerURLs objectAtIndex:i]];
            [urlsToReadThirdLayer addObject:[thirdLayerURLs objectAtIndex:i]];
        }
          
        FrameReaderOperation *operation = [[[FrameReaderOperation alloc] initWithFirstLayerFiles:urlsToReadFirstLayer 
                                                                             andSecondLayerFiles:urlsToReadSecondLayer
                                                                              andThirdLayerFiles:urlsToReadThirdLayer] autorelease];
        [operation addObserver:self forKeyPath:@"isFinished" options:0 context:nil];
        [_queue addOperation:operation];
    }

}
// Invoke this method to start the animation

- (void) startAnimating
{
	self.animationTimer = [NSTimer timerWithTimeInterval: animationFrameDuration
											 target: self
										   selector: @selector(animationTimerCallback:)
										   userInfo: NULL
											repeats: TRUE];

    [[NSRunLoop currentRunLoop] addTimer: animationTimer forMode: NSDefaultRunLoopMode];

	animationStep = 0;
    
    [self launchFrameBuffering];
    
    


	if (avAudioPlayer != nil)
		[avAudioPlayer play];

	// Send notification to object(s) that regestered interest in a start action

	[[NSNotificationCenter defaultCenter]
	 postNotificationName:ImageAnimatorDidStartNotification
	 object:self];	
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    FrameReaderOperation *op = (FrameReaderOperation*)object;
    NSLog(@"Termino de leer el segundo buffer con %d frames", [op.animationData count]);
    framesRead += [op.animationData count];
    self.animationBuffer = op.animationData;
    [op removeObserver:self forKeyPath:@"isFinished"];
}

// Invoke this method to stop the animation, note that this method must not
// invoke other methods and it must cancel any pending callbacks since
// it could be invoked in a low-memory situation or when the object
// is being deallocated. Invoking this method will not generate a
// animation stopped notification, that callback is only invoked when
// the animation reaches the end normally.

- (void) stopAnimating
{
	if (![self isAnimating])
		return;

	[animationTimer invalidate];
	self.animationTimer = nil;

	animationStep = animationNumFrames - 1;
	[self animationShowFrame: animationStep];

	if (avAudioPlayer != nil) {
		[avAudioPlayer stop];
		avAudioPlayer.currentTime = 0.0;
		self->lastReportedTime = 0.0;
	}

	// Send notification to object(s) that regestered interest in a stop action
	
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:ImageAnimatorDidStopNotification
	 object:self];	
}

- (BOOL) isAnimating
{
	return (animationTimer != nil);
}

// Invoked at framerate interval to implement the animation

- (void) animationTimerCallback: (NSTimer *)timer {
	if (![self isAnimating])
		return;

	//NSTimeInterval currentTime;
	NSUInteger frameNow;

    self.animationStep += 1;   
    frameNow = animationStep;

	// Limit the range of frameNow to [0, SIZE-1]
	if (frameNow < 0) {
		frameNow = 0;
	} else if (frameNow >= animationNumFrames) {
		frameNow = animationNumFrames - 1;
	}

	[self animationShowFrame: frameNow];
    
    
    
    // pausa 1
    if (animationStep == 92) {
        [animationTimer invalidate];
        animationTimer = nil;
    }
    
    if (animationStep == 192) {
        [animationTimer invalidate];
        animationTimer = nil;
    }
    
    if (animationStep == 288) {
        [animationTimer invalidate];
        animationTimer = nil;
    }
    
    if (animationStep == 384) {
        [animationTimer invalidate];
        animationTimer = nil;
    }
    
    if (animationStep == 480) {
        [animationTimer invalidate];
        animationTimer = nil;
    }
    
    if (animationStep == 576) {
        [animationTimer invalidate];
        animationTimer = nil;
    }
    
    if (animationStep == 672) {
        [animationTimer invalidate];
        animationTimer = nil;
    }
    
    if (animationStep == 768) {
        [animationTimer invalidate];
        animationTimer = nil;
    }
    
    if (animationStep == 864) {
        [animationTimer invalidate];
        animationTimer = nil;
    }
    
    if (animationStep == 960) {
        [animationTimer invalidate];
        animationTimer = nil;
    }
    
    if (animationStep == 1056) {
        [animationTimer invalidate];
        animationTimer = nil;
    }
    
    
    
    
    
    
    
    
    

	if (animationStep >= animationNumFrames) {
		[self stopAnimating];
        //[timer invalidate];

		// Continue to loop animation until loop counter reaches 0

		if (animationRepeatCount > 0) {
			self.animationRepeatCount = animationRepeatCount - 1;
			[self startAnimating];
		}
	}
}



// Display the given animation frame, in the range [1 to N]
// where N is the largest frame number.

- (void) animationShowFrame: (NSInteger) frame {
	if ((frame >= animationNumFrames) || (frame < 0))
		return;
    
    NSInteger frameToPlay = frame % (int)(BUFFER_SECONDS * 1 / animationFrameDuration);
    if (frameToPlay == 0 && animationBuffer) {
        self.animationData = nil;
        self.animationData = animationBuffer;
        self.animationBuffer = nil;
        [self launchFrameBuffering];
    }
	
    NSData *data = [[animationData objectAtIndex:frameToPlay] objectAtIndex:0];;
	UIImage *img = [UIImage imageWithData:data];
	imageView.image = img;
    
    data = [[animationData objectAtIndex:frameToPlay] objectAtIndex:1];;
	img = [UIImage imageWithData:data];
	secondLayer.image = img;
    
    data = [[animationData objectAtIndex:frameToPlay] objectAtIndex:2];;
	img = [UIImage imageWithData:data];
	thirdLayer.image = img;
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
  self.animationRepeatCount = 0;
  

    
    if ((animationTimer == nil)&(animationStep== 92)) {
        self.animationTimer = [NSTimer timerWithTimeInterval: animationFrameDuration
                                                      target: self
                                                    selector: @selector(animationTimerCallback:)
                                                    userInfo: NULL
                                                     repeats: TRUE];
        [[NSRunLoop currentRunLoop] addTimer: animationTimer forMode: NSDefaultRunLoopMode];
        
        animationStep = 92;
        
    }
    
    if ((animationTimer == nil)&(animationStep== 192)) {
        self.animationTimer = [NSTimer timerWithTimeInterval: animationFrameDuration
                                                      target: self
                                                    selector: @selector(animationTimerCallback:)
                                                    userInfo: NULL
                                                     repeats: TRUE];
        [[NSRunLoop currentRunLoop] addTimer: animationTimer forMode: NSDefaultRunLoopMode];
        
        animationStep = 192;
        
    }
    if ((animationTimer == nil)&(animationStep== 192)) {
        self.animationTimer = [NSTimer timerWithTimeInterval: animationFrameDuration
                                                      target: self
                                                    selector: @selector(animationTimerCallback:)
                                                    userInfo: NULL
                                                     repeats: TRUE];
        [[NSRunLoop currentRunLoop] addTimer: animationTimer forMode: NSDefaultRunLoopMode];
        
        animationStep = 192;
        
    }
    if ((animationTimer == nil)&(animationStep== 288)) {
        self.animationTimer = [NSTimer timerWithTimeInterval: animationFrameDuration
                                                      target: self
                                                    selector: @selector(animationTimerCallback:)
                                                    userInfo: NULL
                                                     repeats: TRUE];
        [[NSRunLoop currentRunLoop] addTimer: animationTimer forMode: NSDefaultRunLoopMode];
        
        animationStep = 288;
        
    }
    if ((animationTimer == nil)&(animationStep== 384)) {
        self.animationTimer = [NSTimer timerWithTimeInterval: animationFrameDuration
                                                      target: self
                                                    selector: @selector(animationTimerCallback:)
                                                    userInfo: NULL
                                                     repeats: TRUE];
        [[NSRunLoop currentRunLoop] addTimer: animationTimer forMode: NSDefaultRunLoopMode];
        
        animationStep = 384;
        
    }
    if ((animationTimer == nil)&(animationStep== 480)) {
        self.animationTimer = [NSTimer timerWithTimeInterval: animationFrameDuration
                                                      target: self
                                                    selector: @selector(animationTimerCallback:)
                                                    userInfo: NULL
                                                     repeats: TRUE];
        [[NSRunLoop currentRunLoop] addTimer: animationTimer forMode: NSDefaultRunLoopMode];
        
        animationStep = 480;
        
    }
    if ((animationTimer == nil)&(animationStep== 576)) {
        self.animationTimer = [NSTimer timerWithTimeInterval: animationFrameDuration
                                                      target: self
                                                    selector: @selector(animationTimerCallback:)
                                                    userInfo: NULL
                                                     repeats: TRUE];
        [[NSRunLoop currentRunLoop] addTimer: animationTimer forMode: NSDefaultRunLoopMode];
        
        animationStep = 576;
        
    }
    if ((animationTimer == nil)&(animationStep== 672)) {
        self.animationTimer = [NSTimer timerWithTimeInterval: animationFrameDuration
                                                      target: self
                                                    selector: @selector(animationTimerCallback:)
                                                    userInfo: NULL
                                                     repeats: TRUE];
        [[NSRunLoop currentRunLoop] addTimer: animationTimer forMode: NSDefaultRunLoopMode];
        
        animationStep = 672;
        
    }
    if ((animationTimer == nil)&(animationStep== 768)) {
        self.animationTimer = [NSTimer timerWithTimeInterval: animationFrameDuration
                                                      target: self
                                                    selector: @selector(animationTimerCallback:)
                                                    userInfo: NULL
                                                     repeats: TRUE];
        [[NSRunLoop currentRunLoop] addTimer: animationTimer forMode: NSDefaultRunLoopMode];
        
        animationStep = 768;
        
    }
    if ((animationTimer == nil)&(animationStep== 864)) {
        self.animationTimer = [NSTimer timerWithTimeInterval: animationFrameDuration
                                                      target: self
                                                    selector: @selector(animationTimerCallback:)
                                                    userInfo: NULL
                                                     repeats: TRUE];
        [[NSRunLoop currentRunLoop] addTimer: animationTimer forMode: NSDefaultRunLoopMode];
        
        animationStep = 864;
        
    }
    if ((animationTimer == nil)&(animationStep== 960)) {
        self.animationTimer = [NSTimer timerWithTimeInterval: animationFrameDuration
                                                      target: self
                                                    selector: @selector(animationTimerCallback:)
                                                    userInfo: NULL
                                                     repeats: TRUE];
        [[NSRunLoop currentRunLoop] addTimer: animationTimer forMode: NSDefaultRunLoopMode];
        
        animationStep = 960;
        
    }
    if ((animationTimer == nil)&(animationStep== 1056)) {
        self.animationTimer = [NSTimer timerWithTimeInterval: animationFrameDuration
                                                      target: self
                                                    selector: @selector(animationTimerCallback:)
                                                    userInfo: NULL
                                                     repeats: TRUE];
        [[NSRunLoop currentRunLoop] addTimer: animationTimer forMode: NSDefaultRunLoopMode];
        
        animationStep = 1056;
        
    }
    
    





}





@end
