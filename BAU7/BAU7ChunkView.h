//
//  BAU7ChunkView.h
//  BAU7ChunkView
//
//  Created by Dan Brooker on 8/31/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


enum BAU7ChunkDrawStyle {
    drawRawChunkStyle=0,
    drawMapChunkStyle=1
};

@interface BAU7ChunkView : UIView
    {
    @public
    enum BAU7ChunkDrawStyle drawStyle;
    
    int chunkID;
    CGPoint mapLocation;
    U7Environment * environment;
    U7MapChunk * mapChunk;
    U7Chunk * rawChunk;
    }
-(void)setMapLocation:(CGPoint)thePoint;
-(void)setChunkID:(int)theID;
-(void)setDrawStyle:(enum BAU7ChunkDrawStyle)theStyle;
@end

NS_ASSUME_NONNULL_END
