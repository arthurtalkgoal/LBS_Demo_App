//
//  ViewController.m
//  LBSOfflineClient
//
//  Created by HU Siyan on 6/11/2018.
//  Copyright © 2018 HU Siyan. All rights reserved.
//

#import "MapViewController.h"
#import <AVFoundation/AVFoundation.h>

#import "DBHandler.h"
#import "Beacons+CoreDataProperties.h"
#import "Pois+CoreDataProperties.h"

#import <LBSOfflineSDK/LBSOfflineSDK.h>
//#import <LBSOfflineSDK/LBSOfflineSDK.h>

#import "network/NWHandler.h"

static CGFloat mDefaultMapScale = 23.0f;
static CGFloat mDefaultStartScale = 0.5;

typedef enum MVPinType : NSUInteger {
    MVPinFrom,
    MVPinTo,
    MVPinLoc,
    MVPinTap,
} MVPinType;

@interface MapViewController () <DBHandlerDelegate, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, LocationEngineDelegate, NSFileManagerDelegate, AVAudioPlayerDelegate> {
    UIImageView *mapView;
    IBOutlet UITableView *levelView;
    UIButton *locButton, *tapButton;
    UIImageView *locBack;
    
    NSArray *paths;
    CAShapeLayer *routeLine;
    
    NSArray *areas;
    NSString *shown_area;
    
    NSArray *gestures;
    CGFloat currentScale;
    CGFloat currentMagnitude;
    CGFloat totalScale;
    CGFloat rotationRadian;
    CGFloat rotationNetRadian;
    
    BOOL loc_on;
    Position *new_pos;
    
    NSFileManager *fileManager;
    NSTimer *background_timer;
}

@property (strong, nonatomic) IBOutlet UIView *backView;

@property (strong, nonatomic) AVAudioPlayer *background_player;
@property (strong, nonatomic) AVAudioSession *background_session;

@end

@implementation MapViewController
@synthesize background_player;
@synthesize background_session;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    loc_on = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self postLogin];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self hideMapView];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Map Initation
- (void)showMapView {
    if (!mapView) {
        
        if (currentScale == 0) {
            currentScale = mDefaultStartScale;
            currentMagnitude = 1 / currentScale;
        }
        
        NSString *modelUrl = [[NSBundle mainBundle] pathForResource:@"4F" ofType:@"jpg"];
        UIImage *newImage = [UIImage imageWithContentsOfFile:modelUrl];
        
        if (!newImage) {
            return;
        }
        
        mapView = [[UIImageView alloc]initWithFrame:CGRectMake(self.backView.bounds.origin.x, self.backView.bounds.origin.y, newImage.size.width, newImage.size.height)];
        [mapView setUserInteractionEnabled:YES];
        
        [self.backView addSubview:mapView];
        [self.backView bringSubviewToFront:mapView];
        [mapView setImage:newImage];
    }
    
    NSLog(@"Current Scale: %f", currentScale);
    CGAffineTransform scaleTransform = CGAffineTransformMakeScale(currentScale, currentScale);
    CGAffineTransform rotateTransform = CGAffineTransformMakeRotation(rotationRadian);
    CGAffineTransform transform = CGAffineTransformConcat(rotateTransform, scaleTransform);
    mapView.transform = transform;
    
    [self sendToCenter:CGPointMake(758, 824)];
}

- (void)hideMapView {
    [mapView removeFromSuperview];
    NSArray *subs  = [mapView subviews];
    for (UIView *sub in subs)
        [sub removeFromSuperview];
    mapView = nil;
}

- (void)showLevelView {
    [levelView reloadData];
}

- (IBAction)backButtonClicked:(nullable id)sender {
    [self readyToEndLocate];
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

#pragma mark - Map Transformations
- (void)sendToCenter:(CGPoint)pnt {
    if (mapView) {
        [UIView animateWithDuration:0.5 animations:^{
            CGPoint newCenter = [self.backView convertPoint:pnt fromView:self->mapView];
            
            CGPoint backCenter = CGPointMake(CGRectGetMidX(self.backView.bounds), CGRectGetMidY(self.backView.bounds));
            CGPoint disp = CGPointMake(backCenter.x - newCenter.x, backCenter.y - newCenter.y);
            [self translateWithDisplacement:disp];
        }];
        
    }
}

- (void)translateWithDisplacement:(CGPoint)translation {
    mapView.center = CGPointMake(mapView.center.x + translation.x, mapView.center.y + translation.y);
}

- (void)adjustTranslationToAnchor:(CGPoint)anchor {
    CGFloat svgWidthThresh = mapView.frame.size.width;
    CGFloat svgHeightThresh = mapView.frame.size.height;
    
    CGFloat svgCenterX = CGRectGetMidX(mapView.frame);
    CGFloat svgCenterY = CGRectGetMidY(mapView.frame);
    CGFloat viewCenterX =anchor.x;
    CGFloat viewCenterY =anchor.y;
    
    CGPoint offset = CGPointZero;
    
    if((svgCenterX - viewCenterX) > svgWidthThresh/2) {
        offset = CGPointMake(offset.x - (svgCenterX - viewCenterX - svgWidthThresh/2), offset.y);
    }
    if((viewCenterX - svgCenterX) > svgWidthThresh/2) {
        offset = CGPointMake(offset.x + viewCenterX - svgCenterX - svgWidthThresh/2, offset.y);
    }
    if((svgCenterY - viewCenterY) > svgHeightThresh/2) {
        offset = CGPointMake(offset.x, offset.y - (svgCenterY - viewCenterY - svgHeightThresh/2));
    }
    if((viewCenterY - svgCenterY) > svgHeightThresh/2) {
        offset = CGPointMake(offset.x, offset.y + viewCenterY - svgCenterY - svgHeightThresh/2);
    }
    if(!CGPointEqualToPoint(CGPointZero, offset)) {
        [UIView animateWithDuration:0.5 animations:^{
            [self translateWithDisplacement:offset];
        }];
    }
}

- (void)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        UIView *piece = mapView;
        CGPoint locationInView = [gestureRecognizer locationInView:piece];
        CGPoint locationInSuperview = [gestureRecognizer locationInView:piece.superview];
        piece.layer.anchorPoint = CGPointMake(locationInView.x / piece.bounds.size.width, locationInView.y / piece.bounds.size.height);
        piece.center = locationInSuperview;
    }
}

- (void)rotateWithRadius:(CGFloat)radius {
    mapView.transform = CGAffineTransformRotate(mapView.transform, radius);
}

- (void)annotationRotation {
    
    if (!locButton.hidden) {
        tapButton.transform = CGAffineTransformRotate(locButton.transform, - rotationNetRadian);
    }
    
}

- (void)scaleWithScale:(CGFloat)scale {
    
    mapView.transform = CGAffineTransformScale(mapView.transform, scale, scale);
    totalScale *= scale;
    currentMagnitude = currentMagnitude / scale;
    
    [self annotationScale:scale];
}

- (void)annotationScale:(CGFloat)nowScale {
    
    currentScale = currentScale * nowScale;
    NSLog(@"Range: %f", currentMagnitude);
    
    if (!locButton.hidden) {
        locButton.transform = CGAffineTransformScale(locButton.transform, 1/nowScale, 1/nowScale);
        locBack.transform = CGAffineTransformScale(locBack.transform, 1/nowScale, 1/nowScale);
    }
}

- (void)adjustScaleToSize:(CGSize)size {
    [UIView animateWithDuration:0.2 animations:^{
        while (currentMagnitude <= 0.8 || currentMagnitude >= 7) {
            if (currentMagnitude <= 0.8) {
                NSLog(@"少於1");
                [self scaleWithScale:0.9];
            }
            else if (currentMagnitude >= 7) {
                NSLog(@"大於70");
                [self scaleWithScale:1.1];
            }
        }
    }];
}

- (void)movePin:(MVPinType)pinType toLoc:(CGPoint)loc isCentre:(BOOL)centre {
    
    [self removePin:pinType];
    CGPoint locCenter = CGPointMake(loc.x, loc.y);
    switch (pinType) {
        case MVPinLoc: {
            locButton.hidden = NO;
            [locButton setUserInteractionEnabled:YES];
            [locButton setCenter:locCenter];
            [mapView addSubview:locButton];
            [mapView bringSubviewToFront:locButton];
            //MARK transformation
            
            CGPoint test = loc;
            CGRect visibleRect = mapView.bounds;
            
            if (centre && !CGRectContainsPoint(visibleRect, test)) {
                [self sendToCenter:test];
            }
            
            if (locBack) {
                [locBack setHidden:YES];
                [locBack removeFromSuperview];
                [locBack setImage:nil];
                locBack = nil;
            }
            
            locBack = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, locButton.frame.size.width * 2.5, locButton.frame.size.height * 2.5)];
            [locBack setCenter:locButton.center];
            locBack.transform = locButton.transform;
            [locBack setContentMode:UIViewContentModeScaleAspectFit];
            [locBack setImage:[UIImage imageNamed:@"bg_ad_count_background"]];
            [mapView insertSubview:locBack belowSubview:locButton];
        }
            break;
        default: {
            tapButton.hidden = NO;
            [tapButton setUserInteractionEnabled:YES];
            [mapView addSubview:tapButton];
            [tapButton setCenter:locCenter];
            [mapView addSubview:tapButton];
            [mapView bringSubviewToFront:tapButton];
            //tapButton.transform = randomAnno.view.transform;
            
            CGPoint test = loc;
            CGRect visibleRect = mapView.bounds;
            
            if (centre && !CGRectContainsPoint(visibleRect, test)) {
                [self sendToCenter:test];
            }
        }
            break;
    }
}

- (void)removePin:(MVPinType)pinType {
    switch (pinType) {
        case MVPinLoc:
            [locButton setHidden:YES];
            [locButton setUserInteractionEnabled:NO];
            [locButton removeFromSuperview];
            break;
        default:
            [tapButton setHidden:YES];
            [tapButton setUserInteractionEnabled:NO];
            [tapButton removeFromSuperview];
            break;
    }
}

#pragma mark - UITableView Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [areas count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"LVLCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (areas) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        
        if (indexPath.row >= [areas count]) {
            return cell;
        }
        NSString *areaId = [areas objectAtIndex:indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"%ld", [areaId integerValue] + 5];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        [cell.textLabel setAdjustsFontSizeToFitWidth:YES];
        
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        if ([areaId isEqualToString:shown_area]) {
            UIColor *globalTint = self.view.tintColor;
            [cell.textLabel setTextColor:[UIColor whiteColor]];
            [cell setBackgroundColor:globalTint];
        } else {
            [cell.textLabel setTextColor:[UIColor darkGrayColor]];
            [cell setBackgroundColor:[UIColor clearColor]];
        }
        
        [cell setSeparatorInset:UIEdgeInsetsZero];
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

#pragma mark - UIGestureRecognizer Delegate
- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    UIGestureRecognizerState state = [recognizer state];
    if (state == UIGestureRecognizerStateBegan || state == UIGestureRecognizerStateChanged) {
        
        CGPoint translation = [recognizer translationInView:self.backView];
        [self translateWithDisplacement:translation];
        
        [recognizer setTranslation:CGPointMake(0, 0) inView:self.backView];
    } else if (state==UIGestureRecognizerStateEnded) {
        [self adjustTranslationToAnchor:recognizer.view.center];
    }
}

- (void)handleRotate:(UIRotationGestureRecognizer *)recognizer {
    if ([recognizer state] == UIGestureRecognizerStateBegan) {
        [self adjustAnchorPointForGestureRecognizer:recognizer];
        rotationNetRadian = 0.0f;
    }
    
    if ([recognizer state] == UIGestureRecognizerStateChanged) {
        [self rotateWithRadius:recognizer.rotation];
        
        rotationNetRadian = recognizer.rotation;
        rotationRadian += recognizer.rotation;
        [self annotationRotation];
        recognizer.rotation = 0;
    }
    
    if ([recognizer state] == UIGestureRecognizerStateEnded) {
        
    }
}

- (void)handleTap:(UITapGestureRecognizer *)recorgnizer {
    
}

- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer {
    
    UIGestureRecognizerState state = [recognizer state];
    
    if (state == UIGestureRecognizerStateBegan) {
        [self adjustAnchorPointForGestureRecognizer:recognizer];
        totalScale = 1.0f;
    }
    
    if (state == UIGestureRecognizerStateChanged) {
        [self scaleWithScale:recognizer.scale];
        recognizer.scale = 1;
    }
    
    if(state==UIGestureRecognizerStateEnded) {
        [UIView animateWithDuration:0.2 animations:^{
            [self adjustScaleToSize:recognizer.view.frame.size];
        }];
    }
}

- (void)handleLongpress:(UILongPressGestureRecognizer *)recognizer {
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    if ([gestures containsObject:gestureRecognizer]) {
        return YES;
    }
    return NO;
}

#pragma mark - File Operations
- (void)write:(Position *)model intoFile:(NSString *)fileName {
    if (fileName) {
        NSString *filePath = [self composeFileName:fileName];
        NSLog(@"File Name: %@", filePath);
        
        NSFileHandle *fileHandler = [NSFileHandle fileHandleForWritingAtPath:filePath];
        if (!fileHandler) {
            [fileManager createFileAtPath:filePath contents:nil attributes:nil];
            fileHandler = [NSFileHandle fileHandleForWritingAtPath:filePath];
        }
        [fileHandler seekToEndOfFile];
        
        if (model) {
            NSError *error = nil;
            NSString *str = [model model2String];
            NSLog(@"Write to File: %@", str);
            NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
            if (data) {
                [fileHandler writeData:data];
            }
        }
        [fileHandler closeFile];
    }
}

- (BOOL)fileExisted:(NSString *)filePath isDirectory:(BOOL)isDirectory {
    BOOL ifDirectory = isDirectory;
    return [fileManager fileExistsAtPath:filePath isDirectory:&ifDirectory];
}

- (NSString *)composeFileName:(NSString *)name {
    name = @"default.txt";
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:name];
    NSLog(@"File Path: %@", filePath);
    return filePath;
}


#pragma mark - Background
- (void)backgroundTrick { 
    NSError *error = nil;
    if (!background_player) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"lullaby" ofType:@"mp3"];
        NSURL *url = [NSURL fileURLWithPath:path];
        background_player =[[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
        if (error) {
            NSLog(@"-1 Error AVAudio: %@", error.description);
            error = nil;
        }
        background_player.delegate = self;
        background_player.numberOfLoops = -1;
    }
    [background_player setVolume:0.0];
    [background_player prepareToPlay];
    [background_player play];

    if (!self.background_session) {
        self.background_session = [AVAudioSession sharedInstance];
        BOOL success = NO;
        
        success = [self.background_session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
        if (error) {
            NSLog(@"0 Error AVAudio: %@", error.description);
            error = nil;
        }
//        success = [self.background_session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
        if (error) {
            NSLog(@"1 Error AVAudio: %@", error.description);
            error = nil;
        }
//        success = [self.background_session setPreferredOutputNumberOfChannels:0 error:&error];
        success = [self.background_session setActive:YES error:&error];
        if (error) {
            NSLog(@"2 Error AVAudio: %@", error.description);
            error = nil;
        }
    }
}

- (void)backgroundTrickStop {
    if (self.background_player) {
        [self.background_player stop];
    }
    [self.background_session setActive:NO error:nil];
}


#pragma mark - Network Handler
- (void)postLogin {
    UIPanGestureRecognizer  *panning = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePan:)];
    UIRotationGestureRecognizer  *rotation = [[UIRotationGestureRecognizer alloc]initWithTarget:self action:@selector(handleRotate:)];
    UIPinchGestureRecognizer  *zooming = [[UIPinchGestureRecognizer alloc]initWithTarget:self action:@selector(handlePinch:)];
    UITapGestureRecognizer *tapping = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTap:)];
    UILongPressGestureRecognizer *longpressing = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(handleLongpress:)];
    gestures = [NSArray arrayWithObjects:panning, rotation, zooming, tapping, nil];
    
    panning.delegate = self;
    rotation.delegate = self;
    zooming.delegate = self;
    tapping.delegate = self;
    longpressing.delegate = self;
    
    [self.backView addGestureRecognizer:panning];
    [self.backView addGestureRecognizer:rotation];
    [self.backView addGestureRecognizer:zooming];
    [self.backView addGestureRecognizer:longpressing];
    [self.backView addGestureRecognizer:tapping];
    
    locButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 50, 50)];
    [locButton setContentMode:UIViewContentModeScaleAspectFit];
    [locButton setBackgroundImage:[UIImage imageNamed:@"bg_ad_count"] forState:UIControlStateNormal];
    [locButton setBackgroundColor:[UIColor clearColor]];
    [locButton setHidden:YES];
    
    [levelView setDelegate:self];
    [levelView setDataSource:self];
    areas = [NSArray arrayWithObjects:@"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7", nil];
    shown_area = @"0";
    [self showMapView];
    [self showLevelView];
}

- (void)postReception:(Position *)point upload:(BOOL)uploadToServer {
    if (![shown_area isEqualToString:point.areaId]) {
        shown_area = point.areaId;
        [self showLevelView];
    }
    [self movePin:MVPinLoc toLoc:point.location isCentre:NO];
    
    if (uploadToServer) {
        
        NSString *area_code = [NSString stringWithFormat:@"texaco-road-m-%ldf", [point.areaId integerValue] + 5];
        NSString *xy_code = [NSString stringWithFormat:@"%.2f|%.2f", point.location.x, point.location.y];
        NSDictionary *upload_dict = @{
                                      //@"location_code":@"STAIR2",
                                      @"xy":xy_code,
                                      @"tracked_at":[NSNumber numberWithLongLong: [[NSDate date] timeIntervalSince1970]]};
        NSLog(@"time %d", (int)[[NSDate date] timeIntervalSince1970]);
        [[NWHandler instance] upload:upload_dict atLevel:area_code success:^(id  _Nonnull responseObject) {
            NSLog(@"Success upload: %f", [[NSDate date] timeIntervalSince1970]);
        } failure:^(NSError * _Nonnull error) {
            NSLog(@"Upload Location Error: %@", error.description);
            if (error.code == 401) {
                [self refreshIfCannotLogin];
                return;
            }
        }];
    }
    if (!fileManager) {
        fileManager = [NSFileManager defaultManager];
        fileManager.delegate = self;
    }
    [self write:point intoFile:@"test"];
}

- (void)refreshIfCannotLogin {
    [[NWHandler instance] serverAccessRefresh:^(id  _Nonnull responseObject) {
        [self recordCookies];
    } failure:^(NSError * _Nonnull error) {
        
    }];
    
}

- (void)recordCookies {
    [[NWHandler instance] serverAccessUserID:^(id  _Nonnull responseObject) {
        
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"Grant User Error: %@", error);
        [self backButtonClicked:nil];
    }];
}

#pragma mark - LBSOfflineSDK
- (IBAction)locationClicked:(id)sender {
    [[DBHandler instance] setDelegate:self];
    [[DBHandler instance] startLoad];
}

- (void)readyToLocate {
    if (!loc_on) {
        [[LocationEngine sharedinstance] setDelegate:self];
        [[LocationEngine sharedinstance] accessChecking:self];
        [[LocationEngine sharedinstance] positioningTurnedOn:YES For:default_wifi_gps];
        [[LocationEngine sharedinstance] positioningTurnedOn:YES For:BLE_beacon];
        
        NSArray *allBeaconRefs = [[DBHandler instance] fetchAllObjectsForEntity:@"Beacons" orderedBy:NULL ascending:YES];
        NSMutableArray *temp = [NSMutableArray array];
        for (Beacons *beacon in allBeaconRefs) {
            BeaconData *bref = [[BeaconData alloc]init];
            bref.beacon_uuid = beacon.uuid;
            bref.beacon_mac = beacon.mac;
            bref.major = [beacon.major integerValue];
            bref.minor = [beacon.minor integerValue];
            
            NSArray *pnt_arr_0 = [beacon.location componentsSeparatedByString:@"["];
            if ([pnt_arr_0 count] <= 1) {
                continue;
            }
            NSArray *pnt_arr_1 = [[pnt_arr_0 objectAtIndex:1] componentsSeparatedByString:@"]"];
            if ([pnt_arr_1 count] <= 1) {
                continue;
            }
            NSArray *pnt_arr_2 = [[pnt_arr_1 objectAtIndex:0] componentsSeparatedByString:@","];
            if ([pnt_arr_2 count] <= 1) {
                continue;
            }
            CGPoint bref_loc = CGPointMake([[pnt_arr_2 objectAtIndex:0] floatValue], [[pnt_arr_2 objectAtIndex:1] floatValue]);
            bref.location = [[Position alloc]initWithAreaId:beacon.areaId location:bref_loc];
            bref.entreThreshold = beacon.enterThres.integerValue;
            bref.farThreshold = beacon.farThres.integerValue;
            
            if (bref) {
                [temp addObject:bref];
            }
        }
        if (temp) {
            [[LocationEngine sharedinstance] addRefData_Beacons:temp];
        }
        
        NSArray *allPOIRefs = [[DBHandler instance] fetchAllObjectsForEntity:@"Pois" orderedBy:NULL ascending:YES];
        NSMutableArray *temp0 = [NSMutableArray array];
        for (Pois *poi in allPOIRefs) {
            POI *poi_data = [[POI alloc]init];
            poi_data._id = poi.id;
            poi_data.areaId = poi.areaId;
            poi_data.name = poi.name;
            
            NSMutableArray *temp_s = [NSMutableArray array];
            NSMutableCharacterSet *sepChars = [NSMutableCharacterSet characterSetWithCharactersInString:@"[], "];
            NSCharacterSet *nullChars = [NSCharacterSet characterSetWithCharactersInString:@""];
            [sepChars formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [sepChars formUnionWithCharacterSet:nullChars];
            
            NSString *temp_vertex = [poi.vertex stringByTrimmingCharactersInSet:sepChars];
            NSMutableArray *subs = [NSMutableArray arrayWithArray:[poi.vertex componentsSeparatedByCharactersInSet:sepChars]];
            NSMutableArray *to_delete = [NSMutableArray array];
            for (NSString *subtest  in subs) {
                if (subtest.length == 0) {
                    [to_delete addObject:subtest];
                }
            }
            [subs removeObjectsInArray:to_delete];
            
            if (!subs) {
                continue;
            }
            if ([subs count] < 2) {
                continue;
            }
            int i = 0;
            while (i < subs.count - 1) {
                double x = [[subs objectAtIndex:i] doubleValue];
                double y = [[subs objectAtIndex:i+1] doubleValue];
                if (x && y) {
                    CGPoint pnt = CGPointMake(x, y);
                    [temp_s addObject:NSStringFromCGPoint(pnt)];
                }
                i+=2;
            }
            if ([temp_s count]) {
                poi_data.vertex = [NSArray arrayWithArray:temp_s];
                poi_data.rect = CGRectNull;
            }
            [temp0 addObject:poi_data];
        }
        if (temp0) {
            [[LocationEngine sharedinstance] addRefData_POIs:temp0];
        }
        
        [[LocationEngine sharedinstance] start];
        loc_on = YES;
        
        background_timer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:NO block:^(NSTimer * _Nonnull timer) {
            [self backgroundTrick];
        }];
    } else {
        [self readyToEndLocate];
    }
}

- (void)readyToEndLocate {
    [background_timer invalidate];
    [self backgroundTrickStop];
    loc_on = NO;
    [[LocationEngine sharedinstance] end];
}

#pragma mark - LBSOfflineClientSDK
- (void)updateLocation:(Position *)point {
    if (!new_pos) {
        new_pos = [[Position alloc]init];
    }
    new_pos = point;
    [self postReception:new_pos upload:YES];
}

- (void)updatePOI:(NSArray<POI *> *)poi_rels {
    for (int i = 0; i < poi_rels.count; i++) {
        POI *poi = [poi_rels objectAtIndex:i];
        NSString *demo_str = [NSString stringWithFormat:@"Room: %@", poi.name];
        NSLog(@"%@", demo_str);
    }
    
}

#pragma mark - DBHandler Delegate
- (void)LoadingCompleted:(BOOL)now {
    NSLog(@"enter...");
    [self readyToLocate];
}

//- (void)updateLocation:(CGPoint)point {
//    [self movePin:MVPinLoc toLoc:point isCentre:NO];
//}
//
//- (void)updatePOI:(id)poi_rel {
//
//}

@end
