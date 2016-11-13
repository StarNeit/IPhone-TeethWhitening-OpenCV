//
//  TransparentDrawingView.m
//  opencv_basic_app
//
//  Created by coneits on 8/1/16.
//  Copyright © 2016 star. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TransparentDrawingView.h"

@implementation TransparentDrawingView

- (void)initObject {
    // Initialization code
    [super setBackgroundColor:[UIColor clearColor]];
    
    isClicked = 0;
    clicked_index = -1;

}
- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
        [self initObject];
    }
    return self;
}
- (id)initWithCoder:(NSCoder *)aCoder {
    if (self = [super initWithCoder:aCoder]) {
        // Initialization code
        [self initObject];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    // Drawing code
  
    if (cur_guide_panel == 2)
    {
        //--- Circle ---//
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetLineWidth(context, 2.0);
        CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
        CGRect rectangle = CGRectMake(left_pt.x - 4,left_pt.y - 4, 8, 8);
        CGContextFillEllipseInRect(context, rectangle);
        CGContextStrokeEllipseInRect(context, rectangle);
        CGContextStrokePath(context);
    }else if (cur_guide_panel == 3)
    {
        //--- Circle ---//
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetLineWidth(context, 2.0);
        CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
        CGRect rectangle = CGRectMake(right_pt.x - 4,right_pt.y - 4, 8, 8);
        CGContextFillEllipseInRect(context, rectangle);
        CGContextStrokeEllipseInRect(context, rectangle);
        CGContextStrokePath(context);
    }else if (cur_guide_panel == 4)
    {
        for (int i = 0; i < 6; i ++)
        {
            CGPoint p = [[points objectAtIndex: i] CGPointValue];
            CGPoint next_p = [[points objectAtIndex: (i + 1) % 6] CGPointValue];
        
        //--- Edge ---//
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path setLineWidth:3.0];
            [path setLineCapStyle:kCGLineCapRound];
            [path setLineJoinStyle:kCGLineJoinRound];
        
            [path moveToPoint:p];
            [path addLineToPoint:next_p];
        
            //[path addCurveToPoint:next_p controlPoint1:p controlPoint2:next_p];
            path.lineWidth = 3;
            [[UIColor whiteColor] setStroke];
            [path stroke];
        
        
        //--- Circle ---//
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGContextSetLineWidth(context, 1.0);
            CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
            CGRect rectangle = CGRectMake(p.x - 3, p.y - 3, 6, 6);
            CGContextFillEllipseInRect(context, rectangle);
            CGContextStrokeEllipseInRect(context, rectangle);
            CGContextStrokePath(context);
        }
    }
}

- (void)drawLineFrom:(CGPoint)from to:(CGPoint)to {
    
    // Refresh
    [self setNeedsDisplay];
}


- (void) touchesBegan:(NSSet *) touches withEvent:(UIEvent *) event
{
    // Initialize a new path for the user gesture
    NSLog(@"touchesBegan");
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint fromPoint = [touch locationInView:self];
    
    if (cur_guide_panel == 2)
    {
        left_pt = fromPoint;
        active_pt = fromPoint;
        [self setNeedsDisplay];
    }else if (cur_guide_panel == 3)
    {
        right_pt = fromPoint;
        active_pt = fromPoint;
        [self setNeedsDisplay];
    }else if (cur_guide_panel == 4)
    {
        for (int i = 0; i < 6; i ++)
        {
            CGPoint p = [[points objectAtIndex: i] CGPointValue];
            CGRect rect = CGRectMake(p.x - 10, p.y - 10, 20, 20);
            if (CGRectContainsPoint(rect, fromPoint))
            {
                isClicked = 1;
                clicked_index = i;
                break;
            }
        }
    }
}

- (void) touchesMoved:(NSSet *) touches withEvent:(UIEvent *) event
{
    // Add new points to the path
    NSLog(@"touchesMoved");
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint toPoint = [touch locationInView:self];
    
    if (isClicked == 1 && clicked_index != -1)
    {
        NSValue *newEntry = [NSValue valueWithCGPoint:toPoint];
        [points replaceObjectAtIndex:clicked_index withObject:newEntry];
        
        // Refresh
        [self setNeedsDisplay];
    }else{
        isClicked = 0;
        clicked_index = -1;
    }
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"touchesEnded");
    isClicked = 0;
    clicked_index = -1;
}

/*- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
 {
 NSLog(@"touchesCancelled");
 }*/



@end