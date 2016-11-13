//
//  AboutVC.m
//  DaRumble
//
//  Created by Phan Minh Tam on 4/2/15.
//  Copyright (c) 2015 DaRumble. All rights reserved.
//

#import "RecogVC.h"
#import <UIKit/UIKit.h>

#import "opencv2/highgui/ios.h"
#import "opencv2/highgui/highgui.hpp"

#import "TransparentDrawingView.h"
#import "MBProgressHUD.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKShareKit/FBSDKShareKit.h>

@interface RecogVC ()<UIScrollViewDelegate, UIGestureRecognizerDelegate, UIActionSheetDelegate>
{
    BOOL PORTRAIT_ORIENTATION;
    CGPoint velocityF;
    CGPoint velocityL;
    
    
    IBOutlet UIImageView *originalImage;
    IBOutlet UIView *view_mode;
    IBOutlet UIScrollView *scrollview;
    
    IBOutlet TransparentDrawingView *drawingView;
    
    int view_width;
    int view_height;
    cv::Mat cvImage;
    cv::vector<cv::vector<cv::Point> > contours;
    cv::CascadeClassifier faceDetector;
    cv::CascadeClassifier mouthDetector;
    
    
    IBOutlet UIView *view_guide_panel;
    IBOutlet UIButton *btn_guide;
    IBOutlet UILabel *label_guide;
    IBOutlet UIView *view_control_slider;
    IBOutlet UIView *view_save_send_panel;
    IBOutlet UIView *view_organize_panel;
    IBOutlet UIView *view_compare_buton;
    
    
    FBSDKShareButton *shareButton;
    
    
    int auto_pos_x;
    int auto_pos_y;
    cv::Mat tImage;
}
@property (strong, nonatomic) IBOutlet UISlider *mySlider;
@end

@implementation RecogVC


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [originalImage setImage:self.selected_image];
    UIImageToMat(self.selected_image, cvImage);
        
    scrollview.delegate=self;
    scrollview.maximumZoomScale = 2.5;
    scrollview.minimumZoomScale = 1;
    
    TransparentDrawingView *view = [[TransparentDrawingView alloc] init];
    [self.view addSubview:view];
    
    view_control_slider.hidden = YES;
    self.mySlider.continuous = YES;
    
    [self.mySlider setThumbImage:[UIImage imageNamed:@"slide_thumb.png"] forState:UIControlStateNormal];
    UIImage *sliderLeftTrackImage = [[UIImage imageNamed: @"slider_back.png"] stretchableImageWithLeftCapWidth: 9 topCapHeight: 0];
    UIImage *sliderRightTrackImage = [[UIImage imageNamed: @"slider_back.png"] stretchableImageWithLeftCapWidth: 9 topCapHeight: 0];
    [self.mySlider setMinimumTrackImage: sliderLeftTrackImage forState: UIControlStateNormal];
    [self.mySlider setMaximumTrackImage: sliderRightTrackImage forState: UIControlStateNormal];
    
    [self.mySlider addTarget:self
                      action:@selector(valueChanged:)
            forControlEvents:UIControlEventValueChanged];
    
    
    btn_guide.tag = 1000;//zoom
    
    left_pt.x = -10; left_pt.y = -10;
    right_pt.x = -10; right_pt.y = -10;
    
    
    view_organize_panel.hidden = YES;
    
    detect_mode = 0;//1: auto, 2: manual
}


//---Memory Warning---
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//---Device Orientation---
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    PORTRAIT_ORIENTATION = UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]);
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    PORTRAIT_ORIENTATION = UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
    NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
}

//---scrollview delegate---//
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
//    NSLog([NSString stringWithFormat:@"%d", scrollView.zoomScale]);
    return originalImage;
}


//**********************//
//******    UI    ******//
//**********************//
- (IBAction)onClickCancelBtn:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
- (IBAction)onClickAutoDetect:(id)sender {
    detect_mode = 1;//auto mode
    view_mode.hidden = YES;
    
    [self getMouthRange_After_FaceDetect];
}
- (IBAction)onClickManualDetect:(id)sender {
    detect_mode = 2;//manual mode
    view_mode.hidden = YES;
    
    view_guide_panel.hidden = NO;
    cur_guide_panel = 1;
}

- (IBAction)onClickZoomNext:(id)sender {
    
    if (btn_guide.tag == 1000)//zoom
    {
        drawingView.hidden = NO;
        label_guide.text = @"Touch the left corner of your mouth on the screen";
        btn_guide.tag = 1001;
        cur_guide_panel = 2;
        [drawingView setNeedsDisplay];
    }else if (btn_guide.tag == 1001)//left corner
    {
        if (left_pt.x == -10 && left_pt.y == -10)
            return;
        [drawingView setNeedsDisplay];
        drawingView.hidden = NO;
        label_guide.text = @"Touch the right corner of your mouth on the screen";
        btn_guide.tag = 1002;
        cur_guide_panel = 3;
    }else if (btn_guide.tag == 1002)//right corner
    {
        if (right_pt.x == -10 && right_pt.y == -10)
            return;
        //---deciding the 6 vertexes---//        
        points = [NSMutableArray arrayWithObjects:
                  [NSValue valueWithCGPoint:left_pt],
                  [NSValue valueWithCGPoint:CGPointMake(left_pt.x + (right_pt.x - left_pt.x) / 3, left_pt.y - (right_pt.x - left_pt.x) / 7)],
                  [NSValue valueWithCGPoint:CGPointMake(left_pt.x + (right_pt.x - left_pt.x) / 3 * 2, left_pt.y - (right_pt.x - left_pt.x) / 7)],
                  [NSValue valueWithCGPoint:right_pt],
                  [NSValue valueWithCGPoint:CGPointMake(left_pt.x + (right_pt.x - left_pt.x) / 3 * 2, left_pt.y + (right_pt.x - left_pt.x) / 7)],
                  [NSValue valueWithCGPoint:CGPointMake(left_pt.x + (right_pt.x - left_pt.x) / 3, left_pt.y + (right_pt.x - left_pt.x) / 7)], nil];
        
        //---//
        drawingView.hidden = NO;
        label_guide.text = @"Drag the points so the area covers your teeth.";
        btn_guide.tag = 1003;
        cur_guide_panel = 4;
        [drawingView setNeedsDisplay];
    }else if (btn_guide.tag == 1003)//move vertexes.
    {
        [drawingView setNeedsDisplay];
        view_guide_panel.hidden = YES;
        drawingView.hidden = YES;
        
        //---Get Visible Rect---//
        float scale = 1.0f/scrollview.zoomScale;
        CGRect visibleRect;
        visibleRect.origin.x = scrollview.contentOffset.x * scale;
        visibleRect.origin.y = scrollview.contentOffset.y * scale;
        visibleRect.size.width = scrollview.bounds.size.width * scale;
        visibleRect.size.height = scrollview.bounds.size.height * scale;
        
        view_width = drawingView.frame.size.width;
        view_height = drawingView.frame.size.height;
        
        float image_width = cvImage.cols;
        float image_height= cvImage.rows;
        
        
        CGPoint pt1, pt1_dash;
        CGFloat vis_image_width, vis_image_height;
        pt1.x = visibleRect.origin.x;
        pt1.y = visibleRect.origin.y;
        
        pt1_dash.x = image_width * pt1.x / view_width;
        pt1_dash.y = image_height * pt1.y / view_height;
        
        vis_image_width = image_width * visibleRect.size.width / view_width;
        vis_image_height = image_height * visibleRect.size.height / view_height;
        
        
        //---Find Contours---//
        cv::Mat src = cv::Mat::zeros( cv::Size( image_width, image_height ), CV_8UC1 );
        cv::vector<cv::Point2f> vert(6);
        for (int i = 0; i < 6; i ++)
        {
            float posx = pt1_dash.x + vis_image_width * [[points objectAtIndex: i] CGPointValue].x / view_width;
            float posy = pt1_dash.y + vis_image_height * [[points objectAtIndex: i] CGPointValue].y / view_height;
            
            //        float posx = image_width * [[points objectAtIndex: i] CGPointValue].x / view_width;
            //        float posy = image_height * [[points objectAtIndex: i] CGPointValue].y / view_height;
            
            vert[i] = cv::Point2f(posx, posy);
        }
        for (int i = 0; i < 6; i ++)
        {
            cv::line(src, vert[i], vert[(i + 1) % 6], cv::Scalar(255), 3, 8);
        }
        
        /// Get the contours
        cv::vector<cv::Vec4i> hierarchy;
        cv::Mat src_copy_for_contours = src.clone();
        findContours( src_copy_for_contours, contours, hierarchy, cv::RETR_TREE, cv::CHAIN_APPROX_SIMPLE);
        
        
        //---Showing ROI & Trackbar---//
        //    drawingView.hidden = YES;
        
        view_control_slider.hidden = NO;
        [self.mySlider setValue:20 animated:NO];        
        [self changeTeethColor:20];
        
        //---Save/send, Compare Buttons Panel---//
        view_organize_panel.hidden = NO;
    }
}


- (IBAction)onClickOriginalColor:(id)sender {    
    view_control_slider.hidden = NO;
    [self.mySlider setValue:20 animated:NO];
    
    [self changeTeethColor:20];
}

- (IBAction)onClickSaveSend:(id)sender {
    view_save_send_panel.hidden = NO;
}
- (IBAction)onClickCancelSaveSend:(id)sender {
    view_save_send_panel.hidden = YES;
}

- (IBAction)onClickCompare:(id)sender {
    //---concatenation---//
    cv::Mat m2, m3;
    UIImageToMat(originalImage.image, m2);
    cv::hconcat(cvImage, m2 , m3);
    
    //---Rotate---//
    cv::Mat dst;
    rotate_90n(m3, dst, -90);
    
    originalImage.image = MatToUIImage(dst);
    
    
    //---hidden compare button---//
    view_compare_buton.hidden = YES;
}
void rotate_90n(cv::Mat &src, cv::Mat &dst, int angle)
{
    dst.create(src.size(), src.type());
    if(angle == 270 || angle == -90){
        // Rotate clockwise 270 degrees
        cv::transpose(src, dst);
        cv::flip(dst, dst, 0);
    }else if(angle == 180 || angle == -180){
        // Rotate clockwise 180 degrees
        cv::flip(src, dst, -1);
    }else if(angle == 90 || angle == -270){
        // Rotate clockwise 90 degrees
        cv::transpose(src, dst);
        cv::flip(dst, dst, 1);
    }else if(angle == 360 || angle == 0){
        if(src.data != dst.data){
            src.copyTo(dst);
        }
    }
}

- (IBAction)onClickSaveImage:(id)sender {
    view_save_send_panel.hidden = YES;
    
    
    [MBProgressHUD showHUDAddedTo:self.view WithTitle:@"Saving..." animated:YES];
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0),
                   ^{
                       UIImageWriteToSavedPhotosAlbum( originalImage.image, nil, nil, nil);
                       [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                   });
}

- (IBAction)onClickFBShareIt:(id)sender {
    view_save_send_panel.hidden = YES;
    
//    FBSDKSharePhoto *photo = [[FBSDKSharePhoto alloc] init];
//    photo.image = originalImage.image;// you can edit it by your choice
//    photo.userGenerated = YES;
//    FBSDKSharePhotoContent *content = [[FBSDKSharePhotoContent alloc] init];
//    content.photos = @[photo];
    
    
    FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
    content.contentURL = [NSURL URLWithString:@"https://developers.facebook.com"];
    
    shareButton = [[FBSDKShareButton alloc] init];
    shareButton.shareContent = content;
    shareButton.center = self.view.center;
    shareButton.hidden = YES;
    [self.view addSubview:shareButton];
    
    [shareButton sendActionsForControlEvents:UIControlEventTouchUpInside];
}
- (IBAction)onClickVisit:(id)sender {
    view_save_send_panel.hidden = YES;
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://smileymiley.co"]];
}
- (IBAction)onClickBuy:(id)sender {
    view_save_send_panel.hidden = YES;
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://smileymiley.co"]];
}




//***************************//
//******    Process    ******//
//***************************//

- (void)changeTeethColor:(int) brightness
{
    //---show compare button---//
    view_compare_buton.hidden = NO;
    
    if (detect_mode == 2)//manual
    {
        //--- Brightness/Contrast ---//
        double alpha = 1.0; /**< Simple contrast control [1.0-3.0]*/
        int beta;/**< Simple brightness control [0-100]*/
        
        if (brightness < 20)
        {
            beta = brightness - 40;
        }else if (brightness == 20)
        {
            beta = brightness - 20;
        }else if (brightness > 20)
        {
            beta = brightness - 10;
        }
        
        cv::Mat src_copy = cvImage.clone();
        
        cv::Rect boundRect = cv::boundingRect(contours[0]);
        cv::Mat raw_dist( cv::Size( boundRect.width, boundRect.height), CV_32FC1 );
        
        for( int j = 0; j < boundRect.height; j++ )
        {
            for( int i = 0; i < boundRect.width; i++ )
            {
                raw_dist.at<float>(j,i) = pointPolygonTest( contours[0], cv::Point2f(i + boundRect.x, j + boundRect.y), false );
            }
        }
        
        for( int j = 0; j < boundRect.height; j++ )
        {
            for( int i = 0; i < boundRect.width; i++ )
            {
                if( raw_dist.at<float>(j,i) > 0 )
                {
                    for( int c = 0; c < 3; c++ )
                    {
                        src_copy.at<cv::Vec4b>(j + boundRect.y, i + boundRect.x)[c]
                        = cv::saturate_cast<uchar>( alpha*( src_copy.at<cv::Vec4b>(j + boundRect.y, i + boundRect.x)[c] ) + beta );
                    }
                }
            }
        }
        
        originalImage.image = MatToUIImage(src_copy);
    }else if (detect_mode == 1)//auto
    {
        cv::Mat src_copy = cvImage.clone();
        
         for (int i = 0 ; i < tImage.cols ; i ++)
         for (int j = 0 ; j < tImage.rows; j ++)
         {
             int bright = tImage.at<uchar>(j, i) / 4 - (100 - brightness);
             
             if (bright < 0)
                 bright = 0;
             
             for( int c = 0; c < 3; c++ )
             {
                 src_copy.at<cv::Vec4b>(auto_pos_y + j, auto_pos_x + i)[c]
                        = cv::saturate_cast<uchar>( 1.0 * ( src_copy.at<cv::Vec4b>(auto_pos_y + j, auto_pos_x + i)[c] ) + bright);
             }
         }
        originalImage.image = MatToUIImage(src_copy);
    }

}


- (void) valueChanged:(id)sender
{
    [self.mySlider setValue:((int)((self.mySlider.value + 5) / 10) * 10) animated:NO];
    [self changeTeethColor:((int)((self.mySlider.value + 5) / 10) * 10)];
}

//**************************************//
//*      Auto Recognition Process      *//
//**************************************//
- (void)getFaceRange
{
    // Load cascade classifier from the XML file
    NSString* cascadePath2 = [[NSBundle mainBundle]
                              pathForResource:@"haarcascade_frontalface_alt"
                              ofType:@"xml"];
    faceDetector.load([cascadePath2 UTF8String]);
    
    cv::Mat faceImage, gray;
    UIImageToMat(originalImage.image, faceImage);
    cvtColor(faceImage, gray, CV_BGR2GRAY);
    
    
    // Detect faces
    std::vector<cv::Rect> face_ranges;
    faceDetector.detectMultiScale(gray, face_ranges, 1.1,
                                  2, 0|CV_HAAR_SCALE_IMAGE, cv::Size(50, 50));
    
    // Draw all detected mouths
    for(unsigned int i = 0; i < face_ranges.size(); i++)
    {
        const cv::Rect& facei = face_ranges[i];
        
        // Get top-left and bottom-right corner points
        cv::Point tl = cv::Point(facei.x, facei.y);
        cv::Point br = tl + cv::Point(facei.width, facei.height);
        
        // Draw rectangle around the face
        cv::Scalar magenta = cv::Scalar(255, 0, 255);
        
        cv::rectangle(faceImage, tl, br, magenta, 4, 8, 0);
        
        
    }
    
    // Show resulting image
    originalImage.image = MatToUIImage(faceImage);
}
- (void)getMouthRange
{
    // Load cascade classifier from the XML file
    NSString* cascadePath2 = [[NSBundle mainBundle]
                              pathForResource:@"Mouth"
                              ofType:@"xml"];
    mouthDetector.load([cascadePath2 UTF8String]);
    
    cv::Mat faceImage, gray;
    UIImageToMat(originalImage.image, faceImage);
    cvtColor(faceImage, gray, CV_BGR2GRAY);
    
    
    // Detect faces
    std::vector<cv::Rect> mouth_ranges;
    mouthDetector.detectMultiScale(gray, mouth_ranges, 1.1,
                                   2, 0|CV_HAAR_SCALE_IMAGE, cv::Size(50, 50));
    
    // Draw all detected mouths
    for(unsigned int i = 0; i < mouth_ranges.size(); i++)
    {
        const cv::Rect& mouthi = mouth_ranges[i];
        
        // Get top-left and bottom-right corner points
        cv::Point tl = cv::Point(mouthi.x, mouthi.y);
        cv::Point br = tl + cv::Point(mouthi.width, mouthi.height);
        
        // Draw rectangle around the face
        cv::Scalar magenta = cv::Scalar(255, 0, 255);
        
        cv::rectangle(faceImage, tl, br, magenta, 4, 8, 0);
    }
    
    // Show resulting image
    originalImage.image = MatToUIImage(faceImage);
}
- (void)getMouthRange_After_FaceDetect
{
    // Load cascade classifier from the XML file
    NSString* cascadePath = [[NSBundle mainBundle]
                             pathForResource:@"haarcascade_frontalface_alt"
                             ofType:@"xml"];
    NSString* cascadePath2 = [[NSBundle mainBundle]
                              pathForResource:@"Mouth"
                              ofType:@"xml"];
    faceDetector.load([cascadePath UTF8String]);
    mouthDetector.load([cascadePath2 UTF8String]);
    
    
    //Load image with face
    cv::Mat faceImage, gray;
    UIImageToMat(originalImage.image, faceImage);
    cvtColor(faceImage, gray, CV_BGR2GRAY);
    
    
    // Detect faces
    std::vector<cv::Rect> faces, mouth_ranges;
    faceDetector.detectMultiScale(gray, faces, 1.1,
                                  2, 0|CV_HAAR_SCALE_IMAGE, cv::Size(50, 50));
    
    
    if (faces.size() > 0)
    {
        //select the face area that has got max square
        int max_area = 0;
        cv::Rect& face = faces[0];
        for (unsigned int i = 0; i < faces.size(); i ++)
        {
            int area = faces[i].width * faces[i].height;
            if (max_area < area)
            {
                max_area = area;
                face = faces[i];
            }
        }
        
        cv::Mat gray2;
        cvtColor(faceImage(face).clone(), gray2, CV_BGR2GRAY);
        mouthDetector.detectMultiScale(gray2, mouth_ranges, 1.1,
                                       2, 0|CV_HAAR_SCALE_IMAGE, cv::Size(50, 50));
       /*
        //--- Draw all face ranges ---//
        for (int j = 0; j < faces.size(); j ++)
        {
            // Get top-left and bottom-right corner points
            cv::Point tl = cv::Point(faces[j].x, faces[j].y);
            cv::Point br = tl + cv::Point(faces[j].width, faces[j].height);
            // Draw rectangle around the face
            cv::Scalar green = cv::Scalar(0, 255, 0);
            cv::rectangle(faceImage, tl, br, green, 4, 8, 0);
        }*/
        
        if (mouth_ranges.size() > 0)
        {
            cv::Point first_tl(face.x, face.y);
            
            int max = 0, maxindex = -1, max2 = 0, maxindex2 = -1;
            for (unsigned int j = 0; j < mouth_ranges.size(); j++)
            {
                if (mouth_ranges[j].y + mouth_ranges[j].height > max )
                {
                    max = mouth_ranges[j].y + mouth_ranges[j].height;
                    maxindex = j;
                }else{
                    if (mouth_ranges[j].y + mouth_ranges[j].height > max2 )
                    {
                        max2 = mouth_ranges[j].y + mouth_ranges[j].height;
                        maxindex2 = j;
                    }
                }
            }
            
            
            cv::Point tl1, br1, tl2, br2;
            if (maxindex != -1)
            {
                cv::Rect& mouthi = mouth_ranges[maxindex];
                
                // Get top-left and bottom-right corner points
                tl1 = first_tl + cv::Point(mouthi.x, mouthi.y);
                br1 = tl1 + cv::Point(mouthi.width, mouthi.height);
                
//                if (tl1.y < cvImage.rows / 3 * 2)
//                {
//                    [self autoMouthDetectFailed];
//                    return;
//                }
                
                // Draw rectangle around the face
//                cv::rectangle(faceImage, tl1, br1, cv::Scalar(255, 0, 255), 4, 8, 0);
                
                
                mouthi.x += first_tl.x;
                mouthi.x += mouthi.width / 10;
                mouthi.width = mouthi.width - mouthi.width / 5;
                
                mouthi.y += first_tl.y;
                mouthi.y += mouthi.height / 4;
                mouthi.height /= 2;
                
                tl2.x = mouthi.x; tl2.y = mouthi.y;
                br2 = tl2 + cv::Point(mouthi.width, mouthi.height);
                cv::rectangle(faceImage, tl2, br2, cv::Scalar(0, 0, 255), 4, 8, 0);
                
                cv::Mat gray_mouth_rng;
                cvtColor(faceImage(mouthi).clone(), gray_mouth_rng, CV_BGR2GRAY);
                [self detectTeethArea:gray_mouth_rng posX:mouthi.x posY:mouthi.y faceImage:faceImage];
            }else{
                [self autoMouthDetectFailed];
            }
            
            /*if (maxindex2 != -1)
            {
                const cv::Rect& mouthi = mouth_ranges[maxindex2];
                
                // Get top-left and bottom-right corner points
                tl2 = first_tl + cv::Point(mouthi.x, mouthi.y);
                br2 = tl2 + cv::Point(mouthi.width, mouthi.height);
                
                // Draw rectangle around the face
                cv::rectangle(faceImage, tl2, br2, cv::Scalar(255, 0, 255), 4, 8, 0);
            }
            /*
             if (maxindex != -1 && maxindex2 != -1 && abs((tl1.x + br1.x) / 2 - faceImage.cols/2) > abs((tl2.x + br2.x) / 2 - faceImage.cols/2))
             {
             maxindex = maxindex2;
             maxindex2 = -1;
             tl1 = tl2;
             br1 = br2;
             }
             
             if (maxindex != -1 && ((br1.x - tl1.x) * (br1.y - tl1.y) < (face.width * face.height) / 4))
             {
             // Draw rectangle around the face
             cv::rectangle(faceImage, tl1, br1, cv::Scalar(255, 0, 0), 4, 8, 0);
             }
             */
        }else{
            [self autoMouthDetectFailed];
        }
    }else{
        [self autoMouthDetectFailed];
    }
}

- (void)detectTeethArea:(cv::Mat) sImage posX:(int)posX posY:(int)posY faceImage:(cv::Mat)faceImage
{
    //---Load template image---//
    UIImage* image = [UIImage imageNamed:@"template.png"];
    cv::Mat templateImage;
    UIImageToMat(image, templateImage);//templateImage: gray
    
    //---Scaling TemplateImage based on Mouth Area Width---//
    int s_width = sImage.cols, s_height = sImage.rows;
    int t_width = templateImage.cols, t_height = templateImage.rows;
    t_height = s_height / 5 * 4;
    t_width = s_width;
    
    cv::resize(templateImage, tImage, cv::Size(t_width, t_height));
    
    int minSAD = 999999;
    int bestY = -1, bestSAD = -1;
    
    for (int y = 0; y < s_height - t_height; y ++)
    {
        int x = 0, SAD = 0;
        
        for (int i = 0; i < t_width; i ++)
            for (int j = 0 ; j < t_height; j ++)
            {
                SAD += abs(sImage.at<uchar>(y + j, x + i) - tImage.at<uchar>(j, i));
            }
        if (SAD < minSAD)
        {
            minSAD = SAD;
            bestY = y;
            bestSAD = SAD;
        }
    }
    
    if (bestSAD == -1)
    {
        [self autoMouthDetectFailed];
        return;
    }
    
    NSLog([NSString stringWithFormat:@"%d", bestSAD]);
    
    auto_pos_x = posX;
    auto_pos_y = posY + bestY;
    detect_mode = 1;
    
    //---Show Slider Bar---//
    view_control_slider.hidden = NO;
    [self.mySlider setValue:20 animated:NO];
    [self changeTeethColor:20];
    
    //---Save/send, Compare Buttons Panel---//
    view_organize_panel.hidden = NO;
    /*
    cv::Mat src_copy = faceImage.clone();
    int bestX = 0;
    for (int i = 0 ; i < t_width ; i ++)
        for (int j = 0 ; j < t_height; j ++)
        {
                for( int c = 0; c < 3; c++ )
                {
                    int k = tImage.at<uchar>(j, i);
                    src_copy.at<cv::Vec4b>(posY + bestY + j, posX + bestX + i)[c]
                    = cv::saturate_cast<uchar>( 1.0 * ( src_copy.at<cv::Vec4b>(posY + bestY + j, posX + bestX + i)[c] ) + tImage.at<uchar>(j, i) / 4);
                }
        }
    originalImage.image = MatToUIImage(src_copy);*/
}

- (void)autoMouthDetectFailed
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Unable to detect smile"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Manually detect", nil];
    actionSheet.tag = 101;
    [actionSheet showInView:self.view];
}


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == 101)
    {
        if (buttonIndex == 0) {
            view_mode.hidden = YES;
            view_guide_panel.hidden = NO;
            cur_guide_panel = 1;
        }
    }
}

- (void)showAlert:(NSString *)message//-----
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Smileymiley Teeth" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification* notification){
        [alert dismissWithClickedButtonIndex:0 animated:NO];
    }];
}
@end
