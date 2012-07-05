#import <string.h>
#import <sqlite3.h>
#import <CommonCrypto/CommonDigest.h>
#import "purchaseChecker.h"

#define PrefFilePath @"/var/mobile/Documents/PhotosWeibo/PhotosWeibo.plist" 

id preferences;

//////
//Declaration
//////
@interface PSListController{
    NSArray *_specifiers;
}
- (id)loadSpecifiersFromPlistName:(id)arg1 target:(id)arg2;
- (void)removeSpecifierAtIndex:(int)arg1 animated:(BOOL)arg2;
- (void)removeSpecifierAtIndex:(int)arg1;
- (void)removeSpecifierID:(id)arg1 animated:(BOOL)arg2;
- (void)beginUpdates;
- (void)endUpdates;
- (void)reloadSpecifiers;
- (void)reloadSpecifierAtIndex:(int)arg1 animated:(BOOL)arg2;
- (void)reloadSpecifierID:(id)arg1 animated:(BOOL)arg2;
- (int)indexOfSpecifierID:(id)arg1;
- (id)specifierAtIndex:(int)arg1;

@end


@interface CPDistributedMessagingCenter
+ (id)centerNamed:(id)arg1;
- (BOOL)sendMessageName:(id)arg1 userInfo:(id)arg2;
- (void)runServerOnCurrentThread;
- (void)registerForMessageName:(id)arg1 target:(id)arg2 selector:(SEL)arg3;
@end

@interface PSSpecifier
@property(retain) NSArray* specifiers;
@property(retain, nonatomic) NSDictionary *shortTitleDictionary; // @synthesize shortTitleDictionary=_shortTitleDict;
@property(retain, nonatomic) NSString *identifier;
@property(retain, nonatomic) NSString *name; // @synthesize name=_name;
@property(retain, nonatomic) NSArray *values; // @synthesize values=_values;
@property(retain, nonatomic) NSDictionary *titleDictionary; // @synthesize titleDictionary=_titleDict;
@property(retain, nonatomic) id userInfo; // @synthesize userInfo=_userInfo;
- (id)properties;
@end

//////
//Declaration
//////

PSSpecifier* state;
PSSpecifier* code;
PSSpecifier* line1;
PSSpecifier* deem;
PSSpecifier* line2;
PSSpecifier* line3;
PSSpecifier* store;
PSSpecifier* detail;
PSSpecifier* buy;

NSString *udid;

sqlite3 *_database;

static NSString* MD5String (NSString* str){
	const char *cstr = [str UTF8String];
	unsigned char result[16];
	CC_MD5(cstr, strlen(cstr), result);
	
	return [NSString stringWithFormat:
			@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
			result[0], result[1], result[2], result[3], 
			result[4], result[5], result[6], result[7],
			result[8], result[9], result[10], result[11],
			result[12], result[13], result[14], result[15]
			];  
}

static BOOL createAuthTable(){
	char *sql = "create table if not exists authTable(authID text PRIMARY KEY)";
    sqlite3_stmt *statement;
    NSInteger sqlReturn = sqlite3_prepare_v2(_database, sql, -1, &statement, nil);
	
    if(sqlReturn != SQLITE_OK) {
		NSLog(@"Error: failed to prepare statement:create auth table");
		return NO;
	}
	
    int success = sqlite3_step(statement);
	
    sqlite3_finalize(statement);
		
	//执行SQL语句失败
	if ( success != SQLITE_DONE) {
		NSLog(@"Error: failed to dehydrate:create table test");
		return NO;
	}
    //NSLog(@"Create table 'UsersTable' successed.");
	return YES;
}

static BOOL openDB(){
	//获取数据库路径
	NSString *path = @"/var/mobile/Documents/PhotosWeibo/weibodbv2.3.sql";
        
	//文件管理器
	NSFileManager *fileManager = [NSFileManager defaultManager];
	//判断数据库是否存在
	BOOL find = [fileManager fileExistsAtPath:path];
	
	//如果数据库存在，则用sqlite3_open直接打开（不要担心，如果数据库不存在sqlite3_open会自动创建）
	if (find) {
				
		//打开数据库，这里的[path UTF8String]是将NSString转换为C字符串，因为SQLite3是采用可移植的C(而不是
		//Objective-C)编写的，它不知道什么是NSString.
		if(sqlite3_open([path UTF8String], &_database) != SQLITE_OK) {			
			//如果打开数据库失败则关闭数据库
			sqlite3_close(_database);
			NSLog(@"Error: open database file.");
			return NO;
		}
		
		//创建一个新表
		createAuthTable();
		return YES;
	}
	return NO;
}

static id getDBCode(){
	
	if(!openDB())
		return NULL;
	
	sqlite3_stmt *statement = nil;

	char * sql = "select authID from authTable";
	if(_database){
		NSLog(@"db done!");
	}
	if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) != SQLITE_OK) {
		NSLog(@"Error: failed to prepare statement with message:get authlist.");
		sqlite3_finalize(statement);
		sqlite3_close(_database);
		return NULL;
	}else{
		NSString *authID = nil;
		while(sqlite3_step(statement) == SQLITE_ROW){
			if(sqlite3_column_text(statement, 0))
				authID =[[NSString alloc] initWithFormat:@"%s", sqlite3_column_text(statement, 0)];
		}
		sqlite3_finalize(statement);
		sqlite3_close(_database);
		return authID;
	}
	
}

static void setDBCode(){
	
	preferences = [[NSMutableDictionary alloc] init];
	
	NSDate *today = [NSDate date];
	
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyy:mm:dd:SS："];
	
	//Optionally for time zone converstions
	[formatter setTimeZone:[NSTimeZone timeZoneWithName:@"Alaska"]];
	
	NSString *stringFromDate = [formatter stringFromDate: today];
	
	[formatter release];
		
	id md5string = MD5String(stringFromDate);
	
	//set md5string in plist
		
	[preferences setValue:md5string forKey:@"sql"];
	[preferences writeToFile: PrefFilePath atomically:YES];
	[preferences release];
		
	//set md5string in db
	if(!openDB())
		return;
	
	sqlite3_stmt *statement = nil;
	//drop
	char* sql0 = "DROP TABLE IF EXISTS authTable";
		
	if(sqlite3_prepare_v2(_database, sql0, -1, &statement,NULL) == SQLITE_OK){
		NSLog(@"--Drop the table--");
		sqlite3_finalize(statement);
	}
		
	//create
	char * sql1;
	if(createAuthTable()){
		sql1 = "INSERT INTO authTable (authID) VALUES(?)";
	}else{
		sql1 = "update authTable set authID = ?";
	}
	
	if(sqlite3_prepare_v2(_database, sql1, -1, &statement, NULL) == SQLITE_OK){
		NSLog(@"insert done");
	}
	
	sqlite3_bind_text(statement, 1, [md5string UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_step(statement);
	sqlite3_finalize(statement);
	sqlite3_close(_database);
	
}

@interface photopluginauthorizeListController: PSListController {
}
@end

@implementation photopluginauthorizeListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"photopluginauthorize" target:self] retain];
	}
	udid = [[UIDevice currentDevice] uniqueIdentifier];
	NSMutableArray *specs = [_specifiers mutableCopy];
	
	state = [specs objectAtIndex: 4];
	code = [specs objectAtIndex: 0];
	line1 = [specs objectAtIndex: 1];
	deem = [specs objectAtIndex: 2];
	line2 = [specs objectAtIndex: 3];
	line3 = [specs objectAtIndex: 5];
	store = [specs objectAtIndex: 6];
	detail = [specs objectAtIndex: 7];
	buy = [specs objectAtIndex: 8];
	
	//Read /var/mobile/Documents/PhotosWeibo to check if authorized
		
	preferences = [[NSDictionary alloc] initWithContentsOfFile: PrefFilePath];
	
	id code = [preferences objectForKey:@"sql"];
		
	id dbCode = getDBCode();
			
	if ([code isEqualToString: dbCode]){		
		[state setName: @"激活成功"];
		[specs removeObjectAtIndex: 0];
		[specs removeObjectAtIndex: 0];
		[specs removeObjectAtIndex: 0];
		[specs removeObjectAtIndex: 0];
		[specs removeObjectAtIndex: 1];
		[specs removeObjectAtIndex: 1];
		[specs removeObjectAtIndex: 1];
		[specs removeObjectAtIndex: 1];
	}else{
		[specs removeObjectAtIndex: 4];
	}
	
	_specifiers = [specs copy];
    [specs release];	
	
	return _specifiers;
}

-(void) redeem:(PSSpecifier*)spec{
	id checker = [[purchaseChecker alloc] init];
	if([checker purchase]){
		setDBCode();
	}
	[self reloadSpecifiers];
}

-(void) restore:(PSSpecifier*)spec{
	id checker = [[purchaseChecker alloc] init];
	if([checker isPurchased]){
		setDBCode();
	}
	[self reloadSpecifiers];
}

-(void) purchase:(PSSpecifier*)spec{
	NSURL *url = [[NSURL alloc] initWithString: @"http://59igou.taobao.com/"];
    [[UIApplication sharedApplication] openURL:url];
}

@end

// vim:ft=objc
