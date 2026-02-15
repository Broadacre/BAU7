//
//  BARandomDungeonGeneratorDeaux.h
//  BAU7
//
//  Created by Dan Brooker on 2/15/24.
//
#import "Includes.h"
#import "BAProceduralGenerator.h"

NS_ASSUME_NONNULL_BEGIN

@interface BAEdge: NSObject
{
    @public
    CGPoint pointOne;
    CGPoint pointTwo;
    
}
+(BAEdge*)edgeFromPoints:(CGPoint)firstPoint andPoint:(CGPoint)secondPoint;
-(void)dump;
-(BOOL)isEqualTo:(BAEdge*)comparisonEdge;
-(BOOL)containsPoint:(CGPoint)thePoint;
-(void)removeEdge:(BAEdge*)theEdge;
@end

@interface BAEdgeArray:NSObject
{
    @public
    NSMutableArray * edges;
}
-(void)clear;
-(void)addEdge:(BAEdge*)theEdge;
-(BOOL)containsEdge:(BAEdge*) theEdge;
-(BOOL)containsPoint:(CGPoint)thePoint;
-(BAEdge*)edgeAtIndex:(long)index;
-(long)count;
-(BAEdgeArray*)copy;
@end;

@interface BAPassage : NSObject
{
    @public
    BAEdge * edgeOne;
    BAEdge * edgeTwo;
    
    CGPoint connectPoint;
}
+(BAPassage*)passageFromPoints:(CGPoint)pointOne andPoint:(CGPoint)pointTwo;
@end


@interface BARandomDungeonGeneratorDeux : BAProceduralGenerator
{
    @public
    NSMutableArray * rectArray;  // for dungeon generation
    //NSMutableArray * fixedRectArray;  // for dungeon generation
    NSMutableArray * borderRectArray;
    NSMutableArray * finalRectArray;  // rects that become rooms
    NSMutableArray * passageArray;
    NSMutableArray * passageRectArray;
    BAEdgeArray * edgeArray;
    BAEdgeArray * nearestNeighborEdgeArray;
    int numberOfRects;
    int averageArea;
    float discardThreshold;
    BOOL rectsHaveDirection;
    BOOL shouldGeneratePassages;
    BOOL nudgeComplete;
    BOOL separationComplete;
    BOOL edgeComplete;
    BOOL passageComplete;
    //live generation
    BOOL updateInSteps;
    BOOL updateComplete;
    BOOL rectGenComplete;
    
    enum BATileType passageTileType;
    
    
    BAIntBitmap * startingBitmap;
    
}
+(BARandomDungeonGeneratorDeux*)createWithSize:(CGSize)theSize;
-(void)setShouldGeneratePassages:(BOOL)shouldGenerate;
-(void)calculateMeanArea;
-(void)prepareToGenerate;
-(BAIntBitmap*)generateStepped;
-(void)generateEdges;
-(BAIntBitmap*)createBitmap;
-(void)setStartingBitmap:(BAIntBitmap*)theBitmap;
-(void)update;
-(void)setDiscardThreshold:(CGFloat) threshold;
-(void)setPassageTileType:(enum BATileType)tileType;
-(NSMutableArray*)rects;
@end

NS_ASSUME_NONNULL_END
