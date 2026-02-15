//
//  BADungeonGenerationView.m
//  BAU7
//
//  Created by Dan Brooker on 7/14/22.
//
#import <UIKit/UIKit.h>

#import <Foundation/Foundation.h>
#include <CoreGraphics/CGGeometry.h>
#import "CGPointUtilities.h"
#import "Includes.h"  //I really don't want to have to include this!
#import "BABitmap.h"
#import "BADungeonGenerationView.h"




@implementation BAPassage
-(id)init
{
    self=[super init];
    
    edgeOne=NULL;
    edgeTwo=NULL;
    connectPoint=invalidLocation();
    return self;
}



+(BAPassage*)passageFromPoints:(CGPoint)pointOne andPoint:(CGPoint)pointTwo
{
    BAPassage* passage=[[BAPassage alloc]init];
    if(CGPointEqualToPoint(pointOne, pointTwo))
    {
        //same point
        return NULL;
    }
    
    //first see which is highest & lowest
    CGPoint highestPoint;
    CGPoint lowestPoint;
    
    if(pointOne.y<pointTwo.y)
    {
        highestPoint=pointOne;
        lowestPoint=pointTwo;
    }
    else
    {
        highestPoint=pointTwo;
        //ignoring for now if they are equal height
        lowestPoint=pointOne;
    }
    
    passage->connectPoint.y=lowestPoint.y;
    passage->connectPoint.x=highestPoint.x;
    
    passage->edgeOne=[BAEdge edgeFromPoints:pointOne andPoint:passage->connectPoint];
    passage->edgeTwo=[BAEdge edgeFromPoints:passage->connectPoint andPoint:pointTwo];
    
    return passage;
}

@end


@implementation BADungeonGenerationView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

#define NUMBER_OF_RECTS 50
#define TILE_SIZE 1
#define STRENGTH TILE_SIZE
#define MIN_ROOM_SIZE 10
#define START_POINT 300
#define SCALE 1

#define MAX_ROOM_SIZE 40

-(id)init
{
    
    //dg=[BARandomDungeonGeneratorDeux createWithSize:CGSizeMake(1000, 1000)];
    dg=[BARandomDungeonGeneratorDeux createWithSize:CGSizeMake(TOTALMAPSIZE*TILESIZE, TOTALMAPSIZE*TILESIZE)];
    
    
    [dg setBaseTileType:GrassTileType];
    [dg setFillTileType:WaterTileType];
    self=[super init];
   
    drawMidPoints=NO;
    drawDiscards=YES;
    drawEdges=NO;
    drawOrigin=NO;
    drawPassages=NO;
    drawCoords=NO;
    drawPassageRects=YES;
    
    live=YES;
    
    [self generate];
    
    return self;
}



-(void)generate
{
    if(live)
        [dg generateStepped];
    else
        [dg generate];
}





-(void)drawRectWithColor:(CGRect)rect forColor:(UIColor*)color shouldDrawCenter:(BOOL)drawCenter shouldDrawCoords:(BOOL)drawCoordinates
{
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    
    
    if(drawCenter)
    {
        CGContextSetRGBFillColor(context, 1, 1.0, 0.0, 1);
        CGContextSetRGBStrokeColor(context, 0.0, 1.0, 0.0, 1);
        CGRect midpoint=CGRectMake(CGRectGetMidX(rect) , CGRectGetMidY(rect), 4, 4);
        CGContextFillEllipseInRect(context, midpoint);
    }
    CGContextSetRGBFillColor(context, components[0], components[1], components[2], .25);
    CGContextSetRGBStrokeColor(context,components[0], components[1], components[2],1);
    
    CGContextFillRect(context, rect);
    CGContextStrokeRect(context, rect);
    
    if(drawCoordinates)
    {
        
        
        NSString * string=[NSString stringWithFormat:@"%.1f,%.1f",rect.origin.x,rect.origin.y];
        //U7Chunk * chunk=[environment->U7Chunks objectAtIndex:mapChunk->masterChunkID];
        
        NSMutableParagraphStyle* textStyle = NSMutableParagraphStyle.defaultParagraphStyle.mutableCopy;
            textStyle.alignment = NSTextAlignmentCenter;

        NSDictionary* textFontAttributes = @{NSFontAttributeName: [UIFont fontWithName: @"Helvetica" size: 12], NSForegroundColorAttributeName: UIColor.redColor, NSParagraphStyleAttributeName: textStyle};

        [string drawInRect: rect withAttributes: textFontAttributes];
    }
}

-(void)draw
{
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    NSMutableArray * rectArray=dg->rectArray;
    //NSMutableArray * fixedRectArray=dg->fixedRectArray;
    NSMutableArray * borderRectArray=dg->borderRectArray;
    NSMutableArray *passageArray=dg->passageArray;
    
    NSMutableArray * passageRectArray=dg->passageRectArray;
    BAEdgeArray * nearestNeighborEdgeArray=dg->nearestNeighborEdgeArray;
    float meanArea=dg->averageArea;
    float roomThreshold=dg->discardThreshold;
    
    for(int count=0;count<[rectArray count];count++)
    {
        CGRect rawRect=[[rectArray objectAtIndex:count]CGRectValue];
        //logRect(rawRect, @"rawRect");
        CGRect theRect=CGRectMake((rawRect.origin.x*SCALE)+START_POINT, (rawRect.origin.y*SCALE)+START_POINT, rawRect.size.width*SCALE, rawRect.size.height*SCALE);
        float area=rawRect.size.width*rawRect.size.height;
        if(area>(meanArea*roomThreshold))
         {
             [self drawRectWithColor:theRect forColor:[UIColor blueColor]  shouldDrawCenter:drawMidPoints shouldDrawCoords:drawCoords];
        }
        /*
        else if(arrayContainsRect(fixedRectArray, rawRect))
        {
            
            NSLog(@"YES");
            [self drawRectWithColor:theRect forColor:[UIColor purpleColor]  shouldDrawCenter:drawMidPoints shouldDrawCoords:drawCoords];
        }
         */
        
        else if(drawDiscards)
        {
            
            [self drawRectWithColor:theRect forColor:[UIColor redColor]  shouldDrawCenter:drawMidPoints shouldDrawCoords:drawCoords];
        }
       
    }
    //if(drawBorders)
    {
        for(int count=0;count<[borderRectArray count];count++)
        {
            CGRect rawRect=[[borderRectArray objectAtIndex:count]CGRectValue];
            CGRect theRect=CGRectMake((rawRect.origin.x*SCALE)+START_POINT, (rawRect.origin.y*SCALE)+START_POINT, rawRect.size.width*SCALE, rawRect.size.height*SCALE);
            [self drawRectWithColor:theRect forColor:[UIColor purpleColor]  shouldDrawCenter:drawMidPoints shouldDrawCoords:drawCoords];
        }
    }
    if(drawEdges)
    {
        /*
        for(long index=0;index<[edgeArray count];index++)
        {
            CGContextSetRGBFillColor(context, 1.0, 1.0, 0.0, .05);
            CGContextSetRGBStrokeColor(context, 1.0, 1.0, 0.0, 1);
            BAEdge * edge=[edgeArray objectAtIndex:index];
            CGContextMoveToPoint(context, edge->pointOne.x, edge->pointOne.y);
            CGContextAddLineToPoint(context, edge->pointTwo.x, edge->pointTwo.y);
            CGContextStrokePath(context);
            //NSLog(@"draw");
        }
         */
        for(long index=0;index<[nearestNeighborEdgeArray count];index++)
        {
            CGContextSetRGBFillColor(context, 1.0, 0.5, 0.0, .05);
            CGContextSetRGBStrokeColor(context, 1.0, 0.5, 0.0, 1);
            BAEdge * edge=[nearestNeighborEdgeArray edgeAtIndex:index];
            CGContextMoveToPoint(context, edge->pointOne.x, edge->pointOne.y);
            CGContextAddLineToPoint(context, edge->pointTwo.x, edge->pointTwo.y);
            CGContextStrokePath(context);
        }
    }
    if(drawPassages)
    {
        for(long index=0;index<[passageArray count];index++)
        {
            CGContextSetRGBFillColor(context, 1.0, 0.5, 0.0, .05);
            CGContextSetRGBStrokeColor(context, 1.0, 0.5, 0.0, 1);
            BAPassage * passage=[passageArray objectAtIndex:index];
            CGContextMoveToPoint(context, (passage->edgeOne->pointOne.x*SCALE)+START_POINT, (passage->edgeOne->pointOne.y*SCALE)+START_POINT);
            CGContextAddLineToPoint(context, (passage->edgeOne->pointTwo.x*SCALE)+START_POINT, (passage->edgeOne->pointTwo.y*SCALE)+START_POINT);
            CGContextMoveToPoint(context, (passage->edgeTwo->pointOne.x*SCALE)+START_POINT, (passage->edgeTwo->pointOne.y*SCALE)+START_POINT);
            CGContextAddLineToPoint(context, (passage->edgeTwo->pointTwo.x*SCALE)+START_POINT, (passage->edgeTwo->pointTwo.y*SCALE)+START_POINT);
            CGContextStrokePath(context);
            //NSLog(@"draw");
        }
    }
    if(drawPassageRects)
    {
        for(int count=0;count<[passageRectArray count];count++)
        {
            CGRect rawRect=[[passageRectArray objectAtIndex:count]CGRectValue];
            //logRect(rawRect, @"rawRect");
            CGRect theRect=CGRectMake((rawRect.origin.x*SCALE)+START_POINT, (rawRect.origin.y*SCALE)+START_POINT, rawRect.size.width*SCALE, rawRect.size.height*SCALE);
            [self drawRectWithColor:theRect forColor:[UIColor orangeColor]  shouldDrawCenter:drawMidPoints shouldDrawCoords:drawCoords];
            
        }
    }
       
}
- (void)drawRect:(CGRect)rect {
 
    if(live)
    {
        [dg update];
    }
    [self draw];
    
}


@end
