//
//  BAProceduralGenerator.h
//  BAU7
//
//  Created by Dan Brooker on 1/30/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class BAIntBitmap;
@interface BAProceduralGenerator : NSObject
{
    @public
    CGSize size;
    enum BATileType baseTileType; //"background" tiltype
    enum BATileType fillTileType; //tiletype to fill with
}
+(BAProceduralGenerator*)createWithSize:(CGSize)theSize;
-(BAIntBitmap*)generate;
-(void)setBaseTileType:(enum BATileType)tileType;
-(void)setFillTileType:(enum BATileType)tileType;
@end

NS_ASSUME_NONNULL_END
