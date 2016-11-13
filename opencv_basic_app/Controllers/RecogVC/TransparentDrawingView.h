//
//  TransparentDrawingView.h
//  opencv_basic_app
//
//  Created by coneits on 8/1/16.
//  Copyright © 2016 star. All rights reserved.
//

#ifndef TransparentDrawingView_h
#define TransparentDrawingView_h

#import <UIKit/UIKit.h>
#import "global.h"

@interface TransparentDrawingView : UIView {
    int isClicked;
    int clicked_index;
    
    CGPoint active_pt;
}
- (void)drawLineFrom:(CGPoint)from to:(CGPoint)to;
@end

#endif /* TransparentDrawingView_h */
