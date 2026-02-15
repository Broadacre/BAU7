//
//  BADirectionUtilities.h
//  BAU7
//
//  Created by Dan Brooker on 2/10/24.
//

#import <Foundation/Foundation.h>


enum BACardinalDirection randomDirection(void);
enum BACardinalDirection randomNESWDirection(void);
enum BACardinalDirection rotateNinetyDegreesClockwise(enum BACardinalDirection fromDirection);
enum BACardinalDirection rotateNinetyDegreesCounterClockwise(enum BACardinalDirection fromDirection);
CGPoint translatePoint(enum BACardinalDirection forDirection,int distance);
