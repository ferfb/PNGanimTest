//
//  FrameReaderOperator.m
//  PNGAnimator
//
//  Created by Rodolfo Cartas on 22/09/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FrameReaderOperation.h"

@implementation FrameReaderOperation

@synthesize animationData = _animationData;

- (id)initWithFirstLayerFiles:(NSArray *)filesFirstLayer andSecondLayerFiles:(NSArray*)filesSecondLayer andThirdLayerFiles:(NSArray*)filesThirdLayer {
    self = [super init];
    if (self) {
        _filesFirstLayer = [[NSArray alloc] initWithArray:filesFirstLayer];
        _filesSecondLayer = [[NSArray alloc] initWithArray:filesSecondLayer];
        _filesThirdLayer = [[NSArray alloc] initWithArray:filesThirdLayer];
    }
    
    return self;
}

- (void)dealloc {
    [_filesFirstLayer release];
    [_filesSecondLayer release];
    [_filesThirdLayer release];
    [_animationData release];
    [super dealloc];
}

- (void)main
{
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionaryWithCapacity:[_filesFirstLayer count]*2];
    
    NSMutableArray *muArray = [NSMutableArray arrayWithCapacity:[_filesFirstLayer count]];
    for (int i = 0; i < [_filesFirstLayer count]; i++) {
        NSURL *aURL = [_filesFirstLayer objectAtIndex:i];
        NSString *urlKey = aURL.path;
        NSData *dataForKey = [dataDict objectForKey:urlKey];
        
        if (dataForKey == nil) {
            dataForKey = [NSData dataWithContentsOfURL:aURL];
            NSAssert(dataForKey, @"dataForKey");
            
            [dataDict setObject:dataForKey forKey:urlKey];
        }
        
        // second layer
        aURL = [_filesSecondLayer objectAtIndex:i];
        urlKey = aURL.path;
        NSData *secondDataForKey = [dataDict objectForKey:urlKey];
        if(secondDataForKey == nil) {
            secondDataForKey = [NSData dataWithContentsOfURL:aURL];
            [dataDict setObject:secondDataForKey forKey:urlKey];
        }
        
        aURL = [_filesThirdLayer objectAtIndex:i];
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
}




@end
