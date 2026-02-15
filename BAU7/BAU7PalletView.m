//
//  BAU7PalletView.m
//  BAU7
//
//  Created by Dan Brooker on 1/8/23.
//
#import "BAU7Objects.h"
#import "BAU7PalletView.h"

#define PALLETRECTSIZE 100

@implementation BAU7PalletView

/**/
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    NSLog(@"drawRect");
    U7Color * color=[environment->pallet->colors objectAtIndex:palletID];
    CGContextRef context = UIGraphicsGetCurrentContext();
    
        //U7ShapeReference * reference=[selectedShapes objectAtIndex:index];
    CGContextSetRGBFillColor(context,[color redValue], [color greenValue], [color blueValue], [color alphaValue]);
    CGContextSetRGBStrokeColor(context,[color redValue], [color greenValue], [color blueValue], [color alphaValue]);
    CGContextFillRect(context, palletRect);
    CGContextStrokeRect(context, palletRect);
    
}


-(id)init
{
    self=[super init];
    environment=NULL;
    palletRect=CGRectMake(200, 200, PALLETRECTSIZE, PALLETRECTSIZE);
    self.backgroundColor=[UIColor clearColor];
    return self;
}

-(void)setPalletID:(int)thePalletID
{
    palletID=thePalletID;
    
}

-(void)setEnvironment:(U7Environment*)theEnvironment
{
    if(theEnvironment)
        environment=theEnvironment;
}

@end
