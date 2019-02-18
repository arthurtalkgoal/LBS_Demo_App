//
//  ViewController.m
//  LBSOfflineClient
//
//  Created by HU Siyan on 6/11/2018.
//  Copyright © 2018 HU Siyan. All rights reserved.
//

#import "MapViewController.h"
#import <AVFoundation/AVFoundation.h>

#import <LBSMapComponents/LBSMapComponents.h>
#import <LBSMapComponents/DBHandler.h>

#import <LBSOfflineSDK/LBSOfflineSDK.h>

#import "network/NWHandler.h"

static CGFloat mDefaultMapScale = 23.0f;
static CGFloat mDefaultStartScale = 0.5;

@interface MapViewController () <DBHandlerDelegate, LocationEngineDelegate, NSFileManagerDelegate, AVAudioPlayerDelegate> {
//    UIImageView *mapView;
//    IBOutlet UITableView *levelView;
//    UIButton *locButton, *tapButton;
//    UIImageView *locBack;
//
//    NSArray *paths;
//    CAShapeLayer *routeLine;

//    NSArray *gestures;
//    CGFloat currentScale;
//    CGFloat currentMagnitude;
//    CGFloat totalScale;
//    CGFloat rotationRadian;
//    CGFloat rotationNetRadian;
    
    BOOL loc_on;
    Position *new_pos;
    
    NSFileManager *fileManager;
    NSTimer *background_timer;
}

@property (strong, nonatomic) IBOutlet UIView *newback;
@property (strong, nonatomic) IBOutlet UIButton *locButton;
@property (strong, nonatomic) MCView *backView;

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
    [self.backView hideMapView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
        if (error) {
            NSLog(@"1 Error AVAudio: %@", error.description);
            error = nil;
        }
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
    self.locButton.enabled = NO;
    [DBHandler instance];
    [[DBHandler instance] setDelegate:self];
    [[DBHandler instance] startLoadWithSiteName:@"texaco" andPath: [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]];
}

- (void)postReception:(Position *)point upload:(BOOL)uploadToServer {
    if (point && self.backView.navigating) {
        [self.backView moveto:point.location areaId:point.areaId];
    }

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

#pragma mark - Private Functions
- (void)dbLoaded {
    if (!self.backView) {
        self.backView = [[MCView alloc]initWithFrame:self.newback.bounds];
        [self.newback addSubview:self.backView];
    }
    NSArray *allAreaRefs = [[DBHandler instance] fetchAllObjectsForEntity:@"Areas" orderedBy:NULL ascending:YES];
    if (!allAreaRefs) {
        return;
    }
    NSMutableArray *temp = [NSMutableArray array];
    for (Areas *area in allAreaRefs) {
        Floor *new_floor = [[Floor alloc]init];
        new_floor._id = area.id;
        new_floor.name = area.name;
        new_floor.altitude = area.altitude;
        //MARK: add image path
        new_floor.image_path = [[NSBundle mainBundle] pathForResource:new_floor.name ofType:@"jpg"];
        new_floor.scale = 0.5f;
        [temp addObject:new_floor];
    }
    [self.backView addFloor:temp];
    [self.backView showMapView];
    [self.backView showLevelView];
    
    self.locButton.enabled = YES;
}

- (IBAction)locationClicked:(id)sender {
    self.backView.navigating = YES;
    if (self.locButton.enabled) {
        [self readyToLocate];
    }
}

- (IBAction)backButtonClicked:(nullable id)sender {
    [self readyToEndLocate];
    self.backView.navigating = NO;
    [self.backView deallocMapView];
    [self.backView deallocLevelView];
    [self.backView removeFromSuperview];
    self.backView = nil;
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
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
    [self dbLoaded];
}

//- (void)updateLocation:(CGPoint)point {
//    [self movePin:MVPinLoc toLoc:point isCentre:NO];
//}
//
//- (void)updatePOI:(id)poi_rel {
//
//}

@end
