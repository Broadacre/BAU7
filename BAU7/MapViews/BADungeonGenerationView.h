//
//  BADungeonGenerationView.h
//  BAU7
//
//  Created by Dan Brooker on 7/14/22.
//

#import <UIKit/UIKit.h>
#import "Includes.h"
#import "BARandomDungeonGeneratorDeux.h"
#import "BABitmap.h"

NS_ASSUME_NONNULL_BEGIN


@interface BADungeonGenerationView : UIView
{
    @public
    
    
    //Draw Flags
    BOOL drawDiscards;
    BOOL drawEdges;
    BOOL drawOrigin;
    BOOL drawPassages;
    BOOL drawCoords;
    BOOL drawMidPoints;
    BOOL drawPassageRects;
    
    BOOL live;
    
    BAIntBitmap * startingBitmap;
    
    BARandomDungeonGeneratorDeux * dg;
    
    
}

-(void)generate;
-(void)generateEdges;
-(BAIntBitmap*)createBitmap;
-(void)setStartingBitmap:(BAIntBitmap*)theBitmap;
@end

NS_ASSUME_NONNULL_END
