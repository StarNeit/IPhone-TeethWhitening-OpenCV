//
//  main.m
//  opencv_basic_app
//
//  Created by coneits on 7/25/16.
//  Copyright © 2016 star. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

NSMutableArray *points;
int cur_guide_panel;
CGPoint left_pt;
CGPoint right_pt;

int detect_mode;

int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
