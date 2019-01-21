//
//  DBHandler.m
//  LBSOfflineClient
//
//  Created by HU Siyan on 30/11/2018.
//  Copyright © 2018 HU Siyan. All rights reserved.
//

#import "DBHandler.h"
#import <CoreData/CoreData.h>
#import <sqlite3.h>

#define SITE_NAME @"texaco"
#define kErrorDomainDatabase @"ErrorDomainDatabase"
#define kErrorCodeUnzipDatabase 1000
#define kErrorCodeReadDatabase 1001

@interface DBHandler () <NSFileManagerDelegate> {
    NSString *_dbPath, *_imgPath;
    
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    
    NSFileManager *fManager;
    NSString *sitePath;
}

@end

@implementation DBHandler

static DBHandler *_instance = nil;

+ (DBHandler *)instance {
    if (_instance) {
        return _instance;
    }
    @synchronized ([DBHandler class]) {
        if (!_instance) {
            _instance = [[self alloc]init];
        }
        return _instance;
    }
    return nil;
}

- (void)startLoad {
    [_instance initiate];
}

- (void)initiate {
    
    fManager = [NSFileManager defaultManager];
    
    if (![self createFolder:SITE_NAME underParentPath:[self getDocumentFolder]]) {
        sitePath = [self getDocumentFolder];
    } else
        sitePath = [NSString stringWithFormat:@"%@/%@", [self getDocumentFolder], SITE_NAME];
    
    _dbPath = [NSString stringWithFormat:@"%@/%@.db", sitePath, SITE_NAME];
    [self setDataModel:SITE_NAME];
    
    [self deleteAllObjectsForEntity:@"Areas"];
    [self deleteAllObjectsForEntity:@"Beacons"];
    [self deleteAllObjectsForEntity:@"Pois"];
    //[self deleteAllObjectsForEntity:@"Connectors"];
    //[self deleteAllObjectsForEntity:@"Facilities"];
    //[self deleteAllObjectsForEntity:@"Regions"];
    [self loadDatabase];
}

#pragma mark - CoreData
- (void)setDataModel:(NSString *)dbName {
    NSError *error;
    NSString *dbStr = [NSString stringWithFormat:@"%@.sqlite", dbName];
    NSPersistentStore *store = [[persistentStoreCoordinator persistentStores] lastObject];
    if (store) {
        [persistentStoreCoordinator removePersistentStore:store error:&error];
        [[self getManager] removeItemAtURL:[store URL] error:&error];
    }
    
    managedObjectContext = nil;
    persistentStoreCoordinator = nil;
    managedObjectModel = nil;
    
    NSString *modelName = @"texaco";
    
    //managed object context
    NSURL *modelUrl = [[NSBundle mainBundle] URLForResource:modelName withExtension:@"momd"];
    managedObjectModel = [[NSManagedObjectModel alloc]initWithContentsOfURL:modelUrl];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]initWithManagedObjectModel:managedObjectModel];
    
    NSString *sqliteStr = sitePath;
    sqliteStr = [sqliteStr stringByAppendingString:[NSString stringWithFormat:@"/%@",dbStr]];
    NSURL *sqliteUrl = [NSURL fileURLWithPath:sqliteStr];
    [persistentStoreCoordinator  addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:sqliteUrl options:nil error:&error];
    if (persistentStoreCoordinator) {
        managedObjectContext = [[NSManagedObjectContext alloc]initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [managedObjectContext setPersistentStoreCoordinator:persistentStoreCoordinator];
    }
}

- (void)saveContext {
    NSError *error = nil;
    if (managedObjectContext) {
        if ([managedObjectContext hasChanges] && [managedObjectContext save:&error]) {
            //add error handler
        }
    }
}

- (BOOL)dataExisted {
    
    NSArray *testing = [self fetchAllObjectsForEntity:@"Areas" orderedBy:nil ascending:YES];
    if (!testing || ![testing count]) {
        return NO;
    }
    return YES;
}

- (void)reset:(NSString *)dbName {
    managedObjectContext = nil;
    persistentStoreCoordinator = nil;
    managedObjectModel = nil;
}

#pragma mark - Saving
- (NSError *)saveData {
    NSError *error = nil;
    if (![managedObjectContext save:&error]) {
        NSLog(@"Data Save Error: %@", error.description);
        return error;
    }
    return nil;
}

#pragma mark - Enquiry
- (NSArray *)fetchAllObjectsForEntity:(NSString *)entityName orderedBy:(nullable NSString *)orderProperty ascending:(BOOL)ascending {
    
    NSFetchRequest *request = [[NSFetchRequest alloc]init];
    NSEntityDescription *description = [NSEntityDescription entityForName:entityName inManagedObjectContext:managedObjectContext];
    [request setEntity:description];
    
    if (orderProperty) {
        [request setSortDescriptors:@[
                                      [NSSortDescriptor sortDescriptorWithKey:orderProperty ascending:ascending]
                                      ]];
    }
    
    NSError *error = nil;
    NSArray *fetchedObjs = [managedObjectContext executeFetchRequest:request error:&error];
    if (error)
        return nil;
    else
        return fetchedObjs;
}

- (NSArray *)fetchObjectsForEntity:(NSString *)entityName AtKey:(NSString *)key withValue:(NSString *)value orderedBy:(nullable NSString *)orderProperty ascending:(BOOL)ascending {
    NSFetchRequest *request = [[NSFetchRequest alloc]init];
    NSEntityDescription *description = [NSEntityDescription entityForName:entityName inManagedObjectContext:managedObjectContext];
    [request setEntity:description];
    if (orderProperty) {
        [request setSortDescriptors:@[
                                      [NSSortDescriptor sortDescriptorWithKey:orderProperty ascending:ascending]
                                      ]];
    }
    NSError *error = nil;
    [request setPredicate:[NSPredicate predicateWithFormat:@" %K == %@ ", key, value]];
    NSArray *fetchedObjs = [managedObjectContext executeFetchRequest:request error:&error];
    return fetchedObjs;
}

- (NSArray *)fetchObjectsForEntity:(NSString *)entityName AtKey:(NSString *)key containsValue:(NSString *)value orderedBy:(nullable NSString *)orderProperty ascending:(BOOL)ascending {
    NSFetchRequest *request = [[NSFetchRequest alloc]init];
    NSEntityDescription *description = [NSEntityDescription entityForName:entityName inManagedObjectContext:managedObjectContext];
    [request setEntity:description];
    if (orderProperty) {
        [request setSortDescriptors:@[
                                      [NSSortDescriptor sortDescriptorWithKey:orderProperty ascending:ascending]
                                      ]];
    }
    NSError *error = nil;
    [request setPredicate:[NSPredicate predicateWithFormat:@" %K CONTAINS[cd] %@ ", key, value]];
    NSArray *fetchedObjs = [managedObjectContext executeFetchRequest:request error:&error];
    return fetchedObjs;
}

- (id)fetchObjectForEntity:(NSString *)entityName ForId:(NSString *)idStr {
    NSArray *fetchedObjs = [self fetchObjectsForEntity:entityName AtKey:@"id" withValue:idStr orderedBy:@"id" ascending:YES];
    if (fetchedObjs && [fetchedObjs count] == 1) {
        return [fetchedObjs objectAtIndex:0];
    }
    return nil;
}

- (NSArray *)fetchObjectsForEntity:(NSString *)entityName ForIds:(NSArray *)idsStr {
    NSFetchRequest *request = [[NSFetchRequest alloc]init];
    NSEntityDescription *description = [NSEntityDescription entityForName:entityName inManagedObjectContext:managedObjectContext];
    [request setEntity:description];
    NSError *error = nil;
    NSSet *test = [NSSet setWithArray:idsStr];
    [request setPredicate:[NSPredicate predicateWithFormat:@" %K IN (%@)", @"id", [test allObjects]]];
    NSArray *fetchedObjs = [managedObjectContext executeFetchRequest:request error:&error];
    return fetchedObjs;
}

- (NSArray *)fetchObjectsForEntity:(NSString *)entityName ForIds:(NSArray *)idsStr orderedBy:(nullable NSString *)orderProperty ascending:(BOOL)ascending {
    NSFetchRequest *request = [[NSFetchRequest alloc]init];
    NSEntityDescription *description = [NSEntityDescription entityForName:entityName inManagedObjectContext:managedObjectContext];
    [request setEntity:description];
    if (orderProperty) {
        [request setSortDescriptors:@[
                                      [NSSortDescriptor sortDescriptorWithKey:orderProperty ascending:ascending]
                                      ]];
    }
    NSError *error = nil;
    NSSet *test = [NSSet setWithArray:idsStr];
    [request setPredicate:[NSPredicate predicateWithFormat:@" %K IN (%@)", @"id", [test allObjects]]];
    NSArray *fetchedObjs = [managedObjectContext executeFetchRequest:request error:&error];
    return fetchedObjs;
}

- (NSArray *)fetchValuesForKeys:(NSArray *)keys fromEntity:(NSString *)entityName {
    NSEntityDescription *description = [NSEntityDescription entityForName:entityName inManagedObjectContext:managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc]init];
    [request setEntity:description];
    [request setResultType:NSDictionaryResultType];
    [request setReturnsDistinctResults:YES];
    [request setPropertiesToFetch:keys];
    
    NSError *error = nil;
    id  rslt = [managedObjectContext executeFetchRequest:request error:&error];
    return rslt;
}

- (id)fetchAttribute:(NSArray *)keys AllValuesForEntitry:(NSString *)entityName {
    
    NSEntityDescription *description = [NSEntityDescription entityForName:entityName inManagedObjectContext:managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc]init];
    [request setEntity:description];
    [request setResultType:NSDictionaryResultType];
    [request setReturnsDistinctResults:YES];
    [request setPropertiesToFetch:keys];
    
    NSError *error = nil;
    id  rslt = [managedObjectContext executeFetchRequest:request error:&error];
    return rslt;
}

#pragma mark - Delete
- (void)deleteAllObjectsForEntity:(NSString *)entityName {
    NSArray *allObjs = [self fetchAllObjectsForEntity:entityName orderedBy:nil ascending:YES];
    if (allObjs) {
        for (NSManagedObject *obj in allObjs)
            [managedObjectContext deleteObject:obj];
    }
}

- (void)deleteObjectForEntiry:(NSString *)entityName ForId:(NSString *)idx {
    NSManagedObject *obj = [self fetchObjectForEntity:entityName ForId:idx];
    if (obj) {
        [managedObjectContext deleteObject:obj];
    }
}

#pragma mark - FileManager
- (NSFileManager *)getManager {
    return fManager;
}

- (BOOL)createFolder:(NSString *)folderName underParentPath:(NSString *)parentPath {
    NSString *folderPath = [NSString stringWithFormat:@"%@/%@", parentPath, folderName];
    BOOL isDirectory = YES;
    NSError *error = nil;
    
    if (![fManager fileExistsAtPath:folderPath isDirectory:&isDirectory]) {
        BOOL status = [fManager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:&error];
        NSLog(@"File Create success: %d", status);
        if (error) {
            NSLog(@"Create Site Folder Error!");
            return NO;
        }
    }
    return YES;
}

- (BOOL)exist:(NSString *)filePath asDirectory:(BOOL)isDirectory {
    BOOL ifDirectory = isDirectory;
    return [fManager fileExistsAtPath:filePath isDirectory:&ifDirectory];
}

- (BOOL)moveFile:(NSString *)filePath toPath:(NSString *)toPath {
    NSError *error;
    if (![fManager copyItemAtPath:filePath toPath:toPath error:&error]) {
        NSLog(@"Copy File Error: %@", error.description);
    }
    return YES;
}

- (NSString *)getDocumentFolder {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
//    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
}

- (NSString *)getTempFolder {
    return NSTemporaryDirectory();
}

#pragma mark - Data Operations
- (void)loadDatabase {
    NSString *dbFilePath = [[NSBundle mainBundle] pathForResource:SITE_NAME ofType:@"db"];
    sqlite3 *database;
    if (sqlite3_open([dbFilePath UTF8String], &database)) {
        NSError *error = [NSError errorWithDomain:kErrorDomainDatabase code:kErrorCodeReadDatabase userInfo:@{NSLocalizedDescriptionKey:@"Error in opening .db file!"}];
        NSLog(@"DB Error: %@", error.description);
    } else {
        //areas
        NSString *nsquery = [[NSString alloc] initWithFormat:@"SELECT * FROM AREAS"];
        sqlite3_stmt *statement;
        int prepareCode = (sqlite3_prepare_v2( database, [nsquery UTF8String], -1, &statement, NULL));
        if (prepareCode == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                int i = 0;
                NSString *_id = [NSString stringWithCString:(char *)sqlite3_column_text(statement, i++) encoding:NSUTF8StringEncoding];
                NSString *name = [NSString stringWithCString:(char *)sqlite3_column_text(statement, i++) encoding:NSUTF8StringEncoding];
                NSNumber *altitude = [NSNumber numberWithInt:(float)sqlite3_column_int(statement, i++)];
                NSManagedObject *obj = [NSEntityDescription insertNewObjectForEntityForName:@"Areas" inManagedObjectContext:managedObjectContext];
                [obj setValue:_id forKey:@"id"];
                [obj setValue:name forKey:@"name"];
                [obj setValue:altitude forKey:@"altitude"];
            }
        }
        sqlite3_finalize(statement);
        
        //POIs
        nsquery = [[NSString alloc] initWithFormat:@"SELECT * FROM POIS"];
        prepareCode = (sqlite3_prepare_v2( database, [nsquery UTF8String], -1, &statement, NULL));
        if (prepareCode == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                int i = 0;
                NSString *_id = [NSString stringWithCString:(char *)sqlite3_column_text(statement, i++) encoding:NSUTF8StringEncoding];
                NSString *areaId = [NSString stringWithCString:(char *)sqlite3_column_text(statement, i++) encoding:NSUTF8StringEncoding];
                NSString *name = [NSString stringWithCString:(char *)sqlite3_column_text(statement, i++) encoding:NSUTF8StringEncoding];
                NSString *svg_name = [NSString stringWithCString:(char *)sqlite3_column_text(statement, i++) encoding:NSUTF8StringEncoding];
                NSString *vertex = [NSString stringWithCString:(char *)sqlite3_column_text(statement, i++) encoding:NSUTF8StringEncoding];
                NSManagedObject *obj = [NSEntityDescription insertNewObjectForEntityForName:@"Pois" inManagedObjectContext:managedObjectContext];
                [obj setValue:_id forKey:@"id"];
                [obj setValue:name forKey:@"name"];
                [obj setValue:svg_name forKey:@"svg_name"];
                [obj setValue:areaId forKey:@"areaId"];
                [obj setValue:vertex forKey:@"vertex"];
            }
        }
        sqlite3_finalize(statement);
        
        //Beacons
        nsquery = [[NSString alloc] initWithFormat:@"SELECT * FROM BEACONS"];
        prepareCode = (sqlite3_prepare_v2( database, [nsquery UTF8String], -1, &statement, NULL));
        if (prepareCode == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                int i = 0;
                NSString *_id = [NSString stringWithCString:(char *)sqlite3_column_text(statement, i++) encoding:NSUTF8StringEncoding];
                NSNumber *enabled = [NSNumber numberWithInt:(bool)sqlite3_column_int(statement, i++)];
                NSString *areaId = [NSString stringWithCString:(char *)sqlite3_column_text(statement, i++) encoding:NSUTF8StringEncoding];
                NSString *uuid = [NSString stringWithCString:(char *)sqlite3_column_text(statement, i++) encoding:NSUTF8StringEncoding];
                NSString *major = [NSString stringWithCString:(char *)sqlite3_column_text(statement, i++) encoding:NSUTF8StringEncoding];
                NSString *minor = [NSString stringWithCString:(char *)sqlite3_column_text(statement, i++) encoding:NSUTF8StringEncoding];
                NSString *mac = [NSString stringWithCString:(char *)sqlite3_column_text(statement, i++) encoding:NSUTF8StringEncoding];
                NSString *xlocation = [NSString stringWithCString:(char *)sqlite3_column_text(statement, i++) encoding:NSUTF8StringEncoding];
                NSString *ylocation = [NSString stringWithCString:(char *)sqlite3_column_text(statement, i++) encoding:NSUTF8StringEncoding];
                NSString *enterThres = [NSString stringWithCString:(char *)sqlite3_column_text(statement, i++) encoding:NSUTF8StringEncoding];
                NSString *relatedRegion = [NSString stringWithCString:(char *)sqlite3_column_text(statement, i++) encoding:NSUTF8StringEncoding];
                
                
                NSManagedObject *obj = [NSEntityDescription insertNewObjectForEntityForName:@"Beacons" inManagedObjectContext:managedObjectContext];
                
                [obj setValue:_id forKey:@"id"];
                [obj setValue:enabled forKey:@"enabled"];
                [obj setValue:areaId forKey:@"areaId"];
                
                [obj setValue:uuid forKey:@"uuid"];
                [obj setValue:major forKey:@"major"];
                [obj setValue:minor forKey:@"minor"];
                [obj setValue:mac forKey:@"mac"];
                
                NSString *location = [NSString stringWithFormat:@"[%@, %@]", xlocation, ylocation];
                [obj setValue:location forKey:@"location"];
                
                [obj setValue:enterThres forKey:@"enterThres"];
                [obj setValue:relatedRegion forKey:@"relatedRegion"];
                
                
            }
        }
        sqlite3_finalize(statement);
/*
        //Connectors
        nsquery = [[NSString alloc] initWithFormat:@"SELECT * FROM CONNECTORS"];
        prepareCode = (sqlite3_prepare_v2( database, [nsquery UTF8String], -1, &statement, NULL));
        if (prepareCode == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                int i = 0;
                NSString *_id = [NSString stringWithCString:(char *)sqlite3_column_text(statement, i++) encoding:NSUTF8StringEncoding];
                NSString *regions = [NSString stringWithCString:(char *)sqlite3_column_text(statement, i++) encoding:NSUTF8StringEncoding];
                NSString *areaId = [NSString stringWithCString:(char *)sqlite3_column_text(statement, i++) encoding:NSUTF8StringEncoding];
                NSString *points = [NSString stringWithCString:(char *)sqlite3_column_text(statement, i++) encoding:NSUTF8StringEncoding];
                
                NSManagedObject *obj = [NSEntityDescription insertNewObjectForEntityForName:@"Connectors" inManagedObjectContext:managedObjectContext];
                [obj setValue:_id forKey:@"id"];
                [obj setValue:points forKey:@"points"];
                [obj setValue:regions forKey:@"regions"];
                [obj setValue:areaId forKey:@"areaId"];
            }
        }
        sqlite3_finalize(statement);
        
        //Facilities
        nsquery = [[NSString alloc] initWithFormat:@"SELECT * FROM FACILITIES"];
        prepareCode = (sqlite3_prepare_v2( database, [nsquery UTF8String], -1, &statement, NULL));
        if (prepareCode == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                int i = 0;
                NSString *_id = [NSString stringWithCString:(char *)sqlite3_column_text(statement, i++) encoding:NSUTF8StringEncoding];
                NSString *name = [NSString stringWithCString:(char *)sqlite3_column_text(statement, i++) encoding:NSUTF8StringEncoding];
                NSString *entryPts = [NSString stringWithCString:(char *)sqlite3_column_text(statement, i++) encoding:NSUTF8StringEncoding];
                NSString *vertex = [NSString stringWithCString:(char *)sqlite3_column_text(statement, i++) encoding:NSUTF8StringEncoding];
                NSString *areaId = [NSString stringWithCString:(char *)sqlite3_column_text(statement, i++) encoding:NSUTF8StringEncoding];
                
                NSManagedObject *obj = [NSEntityDescription insertNewObjectForEntityForName:@"Facilities" inManagedObjectContext:managedObjectContext];
                [obj setValue:_id forKey:@"id"];
                [obj setValue:name forKey:@"name"];
                [obj setValue:entryPts forKey:@"entryPts"];
                [obj setValue:vertex forKey:@"vertex"];
                [obj setValue:areaId forKey:@"areaId"];
            }
        }
        sqlite3_finalize(statement);
        
        //Regions
        nsquery = [[NSString alloc] initWithFormat:@"SELECT * FROM REGIONS"];
        prepareCode = (sqlite3_prepare_v2( database, [nsquery UTF8String], -1, &statement, NULL));
        if (prepareCode == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                int i = 0;
                NSString *_id = [NSString stringWithCString:(char *)sqlite3_column_text(statement, i++) encoding:NSUTF8StringEncoding];
                NSString *vertex = [NSString stringWithCString:(char *)sqlite3_column_text(statement, i++) encoding:NSUTF8StringEncoding];
                NSString *areaId = [NSString stringWithCString:(char *)sqlite3_column_text(statement, i++) encoding:NSUTF8StringEncoding];
                
                NSManagedObject *obj = [NSEntityDescription insertNewObjectForEntityForName:@"Regions" inManagedObjectContext:managedObjectContext];
                [obj setValue:_id forKey:@"id"];
                [obj setValue:vertex forKey:@"vertex"];
                [obj setValue:areaId forKey:@"areaId"];
            }
        }
        sqlite3_finalize(statement);
 */
    }
    sqlite3_close(database);
    if ([self.delegate respondsToSelector:@selector(LoadingCompleted:)]) {
        [self.delegate LoadingCompleted:YES];
    }
    
}


@end
