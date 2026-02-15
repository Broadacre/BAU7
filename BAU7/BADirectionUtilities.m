//
//  BADirectionUtilities.m
//  BAU7
//
//  Created by Dan Brooker on 2/10/24.
//
#import "Includes.h"
#import "enums.h"
#import "BADirectionUtilities.h"

enum BACardinalDirection randomDirection(void)
{
    int result=randomInSpan(0, 7);
    return result;
}

enum BACardinalDirection randomNESWDirection(void)
{
    int result=randomInSpan(0, 3);
    switch (result) {
        case 0:
            return NorthCardinalDirection;
            break;
        case 1:
            return EastCardinalDirection;
            break;
        case 2:
            return SouthCardinalDirection;
            break;
        case 3:
            return WestCardinalDirection;
            break;
        default:
            break;
    }
    return result;
}

enum BACardinalDirection rotateNinetyDegreesClockwise(enum BACardinalDirection fromDirection)
{
    switch (fromDirection) {
        case NorthCardinalDirection:
            return EastCardinalDirection;
            break;
        case NorthEastCardinalDirection:
            return SouthEastCardinalDirection;
            break;
        case EastCardinalDirection:
            return SouthCardinalDirection;
            break;
        case SouthEastCardinalDirection:
            return SouthWestCardinalDirection;
            break;
        case SouthCardinalDirection:
            return WestCardinalDirection;
            break;
        case SouthWestCardinalDirection:
            return NorthWestCardinalDirection;
            break;
        case WestCardinalDirection:
            return NorthCardinalDirection;
            break;
        case NorthWestCardinalDirection:
            return NorthEastCardinalDirection;
            break;
        default:
            break;
    }
}

enum BACardinalDirection rotateNinetyDegreesCounterClockwise(enum BACardinalDirection fromDirection)
{
    switch (fromDirection) {
        case NorthCardinalDirection:
            return WestCardinalDirection;
            break;
        case NorthEastCardinalDirection:
            return NorthWestCardinalDirection;
            break;
        case EastCardinalDirection:
            return NorthCardinalDirection;
            break;
        case SouthEastCardinalDirection:
            return NorthEastCardinalDirection;
            break;
        case SouthCardinalDirection:
            return EastCardinalDirection;
            break;
        case SouthWestCardinalDirection:
            return SouthEastCardinalDirection;
            break;
        case WestCardinalDirection:
            return SouthCardinalDirection;
            break;
        case NorthWestCardinalDirection:
            return SouthWestCardinalDirection;
            break;
        default:
            break;
    }
}

CGPoint translatePoint(enum BACardinalDirection forDirection,int distance)
{
    switch (forDirection) {
        case NorthCardinalDirection:
            return CGPointMake(0, -distance);
            break;
        case NorthEastCardinalDirection:
            return CGPointMake(distance, -distance);
            break;
        case EastCardinalDirection:
            return CGPointMake(distance, 0);
            break;
        case SouthEastCardinalDirection:
            return CGPointMake(distance, distance);
            break;
        case SouthCardinalDirection:
            return CGPointMake(0, distance);
            break;
        case SouthWestCardinalDirection:
            return CGPointMake(-distance, distance);
            break;
        case WestCardinalDirection:
            return CGPointMake(-distance, 0);
            break;
        case NorthWestCardinalDirection:
            return CGPointMake(-distance, -distance);
            break;
        default:
            break;
    }
}
