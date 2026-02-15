//
//  BASprite.m
//  BAU7
//
//  Created by Dan Brooker on 9/28/21.
//
#import "Includes.h"
#import "BASprite.h"
@implementation BASprite
-(id)init
{
    self=[super init];
    spriteType=NoBASpriteType;
    moved=NO;
    //aiManager=[[AIManager alloc]init];
    
    //actionManager=[[BAActionManager alloc]init];
    //[aiManager setActor:self];
    globalLocation=CGPointMake(0, 0);
    return self;
}
-(void)step
{
   // NSLog(@"BASprite Step");
    //if(aiManager)
    //    [aiManager step];
   // if(actionManager)
    //   [actionManager step];
   // else
    {
        //NSLog(@"Bad action manager");
    }
        
}
/*
-(void)setActionManager:(BAActionManager*)theActionManager
{
    if(theActionManager)
        actionManager=theActionManager;

}
*/

-(void)setShapeReference:(U7ShapeReference*)theShapeReference
{
    if(theShapeReference)
    {
        shapeReference=theShapeReference;
    }

}


-(void)setEnvironment:(U7Environment*)theEnvironment
{
    if(theEnvironment)
    {
        environment=theEnvironment;
    }

}

-(void)setMap:(U7Map*)theMap
{
    if(theMap)
    {
        map=theMap;
    }

}

-(void)setGlobalLocation:(CGPoint)theLocation
{
    globalLocation=theLocation;
}

-(CGPoint)getGlobalLocation
{
    //CGPoint theLocation=CGPointMake(shapeReference->chunkXCoord, shapeReference->chunkYCoord);
    return globalLocation;
}


-(void)setShapeChunkLocation:(CGPoint)chunkLocation
{
    shapeReference->parentChunkXCoord=chunkLocation.x;
    shapeReference->parentChunkYCoord=chunkLocation.y;
}

-(BOOL)isAdjacent:(CGPoint)thePosition
{
    //NSLog(@"Adjacent: %i,%i",abs(position.x-thePosition.x),abs(position.y-thePosition.y));
    //if(abs(position.x-thePosition.x)==1||abs(position.y-thePosition.y)==1)
    //int value=abs(thePosition.x - position.x) + abs(thePosition.y - position.y);
    float value=simpleDistance(thePosition,globalLocation);
    //NSLog(@"isAdjacent: %f",value);
    if(value<=2.1)
        return YES;
    return NO;
}

-(CGPointArray*)shapesOnMapWithID:(int)shapeID forFrame:(int)frameID
{
    NSArray * shapes=[map findShapesWithID:shapeID forFrame:frameID];
    if(shapes)
    {
        CGPointArray * pointArray=[[CGPointArray alloc]init];
        for(long index=0;index<[shapes count];index++)
        {
            U7ShapeReference * shape=[shapes objectAtIndex:index];
            [pointArray addPoint:[shape globalCoordinate]];
            
        }
        return pointArray;
    }
    return NULL;
}


-(CGPoint)nearestShapeWithID:(int)shapeID forFrame:(int)frameID
{
    CGPointArray * array=[self shapesOnMapWithID:shapeID forFrame:frameID];
    if(array)
    {
        return [array nearestToCGPoint:[self getGlobalLocation]];
    }
    return invalidLocation();
}

+(BASprite*)spriteFromU7Shape:(long)shapeID forFrame:(int)frameID forEnvironment:(U7Environment*) environment
{
    BASprite * sprite=[[BASprite alloc]init];
    U7Shape * shape=[environment->U7Shapes objectAtIndex:shapeID];
    U7ShapeReference * newReference=[[U7ShapeReference alloc]init];
    shape->animated=NO;
    newReference->shapeID=shapeID;
    newReference->parentChunkXCoord=0;
    newReference->parentChunkYCoord=0;
    newReference->lift=1;
    newReference->frameNumber=frameID;
    newReference->currentFrame=frameID;
    newReference->numberOfFrames=[shape numberOfFrames];
    newReference->animates=NO;
    newReference->parentChunkID=-1;
    [sprite setEnvironment:environment];
    [sprite setShapeReference:newReference];
    
    return sprite;
}

@end

@implementation BASpriteArray
-(id)init
{
    self=[super init];
    spriteArray=[[NSMutableArray alloc]init];
    return self;
}
-(void)clear
{
    [spriteArray removeAllObjects];
}

-(void)addSprite:(BASprite*)theSprite
{
    [spriteArray addObject:theSprite];
}

-(BASprite*)spriteAtIndex:(long)index
{
    BASprite * theSprite=[spriteArray objectAtIndex:index];
    return theSprite;
}
-(void)removeSpriteAtIndex:(long)index
{
    [spriteArray removeObjectAtIndex:index];
}

-(BASprite *)nearestSpriteWithType:(enum BASpriteType)type fromLocation:(CGPoint)location
{
 
    float distance=10000000000;
    BASprite * closestSprite=NULL;
    if([spriteArray count])
    {
        //NSLog(@"%li points",[points count]);
        //logPoint(originPoint, @"startPoint");
        for(long index=0;index<[spriteArray count];index++)
        {
            BASprite * sprite=[spriteArray objectAtIndex:index];
            if(!(sprite->spriteType==type))
                continue;
            float newDistance=simpleDistance(location, sprite->globalLocation);
            //NSLog(@"newDistance: %f",newDistance);
            if(newDistance<distance)
            {
                distance=newDistance;;
                //NSLog(@"distance: %f",distance);
                closestSprite=sprite;
                //logPoint(thePoint, @"point");
            }
            
        }
    }
    //logPoint(thePoint, @"result");
    return closestSprite;
}

-(BAActor *)nearestActorWithType:(enum BAActorType)type fromLocation:(CGPoint)location
{
    float distance=10000000000;
    BAActor * closestActor=NULL;
    if([spriteArray count])
    {
        //NSLog(@"%li points",[points count]);
        //logPoint(originPoint, @"startPoint");
        for(long index=0;index<[spriteArray count];index++)
        {
            BAActor * actor=[spriteArray objectAtIndex:index];
            if(!(actor->actorType==type))
                continue;
            float newDistance=simpleDistance(location, actor->globalLocation);
            //NSLog(@"newDistance: %f",newDistance);
            if(newDistance<distance)
            {
                distance=newDistance;;
                //NSLog(@"distance: %f",distance);
                closestActor=actor;
                //logPoint(thePoint, @"point");
            }
            
        }
    }
    //logPoint(thePoint, @"result");
    return closestActor;
}

-(long)count
{
    return [spriteArray count];
}

@end


@implementation BAActor

-(id)init
{
    self=[super init];
    aiManager=[[AIManager alloc]init];
    [aiManager setActor:self];
    inventory=[[NSMutableArray alloc]init];
    adjacentPoints=[[CGPointArray alloc]init];
    spriteType=ActorBASpriteType;
    actorType=NoActorBAActorType;
    HP=randomInSpan(10, 30);
    dead=NO;
    return self;
}

-(void)step
{
    [super step];
   // NSLog(@"BASprite Step");
    if(aiManager)
        [aiManager step];
   // if(actionManager)
    //   [actionManager step];
    else
    {
        //NSLog(@"Bad action manager");
    }
    //logPoint(globalLocation, @"global Location");
[self updateAdjacentPoints:3];
}

-(void)updateAdjacentPoints:(int)range
{
    adjacentPoints=NULL;
    adjacentPoints=pointsSurroundingCGPoint(globalLocation, range,NO);
    
}


-(void)setShapeReference:(U7ShapeReference*)theShapeReference
{
    if(theShapeReference)
    {
        [super setShapeReference:theShapeReference];
        BAActionManager * manager=aiManager->actionManager;
        [manager setShapeReference:theShapeReference];
    }

}


-(void)setEnvironment:(U7Environment*)theEnvironment
{
    if(theEnvironment)
    {
        [super setEnvironment:theEnvironment];
        BAActionManager * manager=aiManager->actionManager;
        [manager setEnvironment:theEnvironment];
    }

}

-(void)setMap:(U7Map*)theMap
{
    if(theMap)
    {
        [super setMap:theMap];
        BAActionManager * manager=aiManager->actionManager;
        [manager setMap:theMap];
    }

}
-(void)dropInventoryObjectAtLocation:(long)inventoryIndex atGlobalLocation:(CGPoint)location
{
    if(inventoryIndex>=[inventory count])
    {
        return;
    }
    BASprite * sprite=[inventory objectAtIndex:inventoryIndex];
    U7MapChunkCoordinate * coordinate=[map MapChunkCoordinateForGlobalTilePosition:location];
    //[coordinate dump];
    U7MapChunk * mapChunk=[map mapChunkForLocation:[coordinate mapChunkCoordinate]];
    [mapChunk addSprite:sprite atLocation:[coordinate getChunkTilePosition]];
    [inventory removeObjectAtIndex:inventoryIndex];
}

-(void)addObjectToInventory:(BASprite*)theSprite atLocation:(CGPoint)location
{
    [inventory addObject:theSprite];
    U7MapChunkCoordinate * coordinate=[map MapChunkCoordinateForGlobalTilePosition:location];
    U7MapChunk * mapChunk=[map mapChunkForLocation:[coordinate mapChunkCoordinate]];
   
    [mapChunk removeSprite:theSprite];
    
    //theSprite->globalLocation=invalidLocation();
}



-(BASprite*)checkCGPointArrayForResource:(CGPointArray*)pointArray forResource:(enum BAResourceType)resourceType
{
    BASprite * theSprite=NULL;
    CGPointArray * theArray=[[CGPointArray alloc]init];
    for(long index=0;index<[pointArray count];index++)
    {
        CGPoint thePoint=[pointArray pointAtIndex:index];
        BASprite * tempSprite=[map spriteAtLocation:thePoint ofResourceType:resourceType];
        if(tempSprite)
        {
            [theArray addPoint:thePoint];
            //logPoint(thePoint, @"found");
            //logPoint(globalLocation, @"My Location");
            theSprite=tempSprite;
            //break;
        }
    }
    if([theArray count])
    {
        CGPoint resultPoint=[theArray nearestToCGPoint:globalLocation];
        BASprite * tempSprite=[map spriteAtLocation:resultPoint ofResourceType:resourceType];
        if(tempSprite)
            return  tempSprite;
    }
    return NULL;
}

-(BAActor*)checkCGPointArrayForActor:(CGPointArray*)pointArray forActor:(enum BAActorType)actorType
{
    BAActor * theActor=NULL;
    CGPointArray * theArray=[[CGPointArray alloc]init];
    for(long index=0;index<[pointArray count];index++)
    {
        CGPoint thePoint=[pointArray pointAtIndex:index];
        BAActor * tempActor=[map actorAtLocation:thePoint ofActorType:actorType];
        if(tempActor)
        {
            [theArray addPoint:thePoint];
            //logPoint(thePoint, @"found");
            //logPoint(globalLocation, @"My Location");
            theActor=tempActor;
            //break;
        }
    }
    if([theArray count])
    {
        CGPoint resultPoint=[theArray nearestToCGPoint:globalLocation];
        BAActor * tempActor=[map actorAtLocation:resultPoint ofActorType:actorType];
        if(tempActor)
            return  tempActor;
    }
    return NULL;
}


-(void)setUserAction:(BASpriteAction*)action
    {
    if(!action)
        return;
    else if(!aiManager->actionManager)
        return;
    else
        aiManager->userAction=action;
    }

@end
