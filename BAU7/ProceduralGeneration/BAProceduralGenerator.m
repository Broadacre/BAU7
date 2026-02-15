//
//  BAProceduralGenerator.m
//  BAU7
//
//  Created by Dan Brooker on 1/30/24.
//
#import "Includes.h"
#import "BAProceduralGenerator.h"

@implementation BAProceduralGenerator

+(BAProceduralGenerator*)createWithSize:(CGSize)theSize
{
    BAProceduralGenerator *generator=[[BAProceduralGenerator alloc]init];
    generator->size=theSize;
    return generator;
}
-(BAIntBitmap*)generate
{
    
    return NULL;
}

-(void)setBaseTileType:(enum BATileType)tileType
{
    if(tileType>0)
        baseTileType=tileType;
    else
        baseTileType=NoTileType;
}


-(void)setFillTileType:(enum BATileType)tileType
{
    if(tileType>0)
        fillTileType=tileType;
    else
        fillTileType=NoTileType;
}

@end
