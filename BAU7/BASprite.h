//
//  BASprite.h
//  BAU7
//
//  Created by Dan Brooker on 9/28/21.
//

#import <Foundation/Foundation.h>
#import "enums.h"
NS_ASSUME_NONNULL_BEGIN
@class CGPointArray;
@class AIManager;


@interface BASprite : NSObject
{
    @public
    enum BASpriteType spriteType;
    BOOL moved;
    //BAActionManager * actionManager;
    U7ShapeReference * shapeReference;
    //AIManager * aiManager;
    U7Environment * environment;
    U7Map * map;
    CGPoint globalLocation;
    enum BAResourceType resourceType;
    enum BAActorType actorType;
    
    
}

//init
-(void)setActionManager:(BAActionManager*)theActionManager;
-(void)setShapeReference:(U7ShapeReference*)theShapeReference;
-(void)setMap:(U7Map*)theMap;
-(void)setEnvironment:(U7Environment*)theEnvironment;

//location
-(void)setShapeChunkLocation:(CGPoint)chunkLocation;
-(void)setGlobalLocation:(CGPoint)theLocation;
-(CGPoint)getGlobalLocation;


-(void)step;
-(BOOL)isAdjacent:(CGPoint)thePosition;

-(CGPointArray*)shapesOnMapWithID:(int)shapeID forFrame:(int)frameID;
-(CGPoint)nearestShapeWithID:(int)shapeID forFrame:(int)frameID;
+(BASprite*)spriteFromU7Shape:(long)shapeID forFrame:(int)frameID forEnvironment:(U7Environment*) environment;
@end

@interface BASpriteArray : NSObject
{
    NSMutableArray * spriteArray;
}
-(void)clear;
-(void)addSprite:(BASprite*)theSprite;
-(BASprite*)spriteAtIndex:(long)index;
-(void)removeSpriteAtIndex:(long)index;
-(BASprite *)nearestSpriteWithType:(enum BASpriteType)type fromLocation:(CGPoint)location;
-(BAActor *)nearestActorWithType:(enum BAActorType)type fromLocation:(CGPoint)location;
-(long)count;
@end

@interface BAActor : BASprite
{
    @public
    NSMutableArray * inventory;
    AIManager * aiManager;
    CGPointArray * adjacentPoints;
    
    int HP;
    BOOL dead;
}
-(void)dropInventoryObjectAtLocation:(long)inventoryIndex atGlobalLocation:(CGPoint)location;
-(void)updateAdjacentPoints:(int)range;
-(void)addObjectToInventory:(BASprite*)theSprite atLocation:(CGPoint)location;
-(BASprite*)checkCGPointArrayForResource:(CGPointArray*)pointArray forResource:(enum BAResourceType)resourceType;
-(BAActor*)checkCGPointArrayForActor:(CGPointArray*)pointArray forActor:(enum BAActorType)actorType;
-(void)setUserAction:(BASpriteAction*)action;
@end
NS_ASSUME_NONNULL_END
