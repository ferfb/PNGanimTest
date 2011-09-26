//
//  FrameReaderOperator.h
//  PNGAnimator
//
//  Created by Rodolfo Cartas on 22/09/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FrameReaderOperation : NSOperation {
    NSArray *_filesFirstLayer;
    NSArray *_filesSecondLayer;
    NSArray *_filesThirdLayer;
    
    NSArray *_animationData;
}

@property (nonatomic, retain) NSArray* animationData;

- (id)initWithFirstLayerFiles:(NSArray *)filesFirstLayer andSecondLayerFiles:(NSArray*)filesSecondLayer andThirdLayerFiles:(NSArray*)filesThirdLayer;


@end
