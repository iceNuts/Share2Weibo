#define PrefFilePath @"/var/mobile/Library/Preferences/com.icenuts.photoplugin.authorize.plist" 
#define PrefChangeNotification "com.icenuts.photoplugin.prefs"

static NSDictionary *Preferences = nil;

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


@interface photopluginauthorizeCodeListController: PSListController {
}
@end

@implementation photopluginauthorizeCodeListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"photopluginredeemcode" target:self] retain];
	}
	
	//Read /var/mobile/Documents/PhotosWeibo to check if authorized
	
	return _specifiers;
}

@end

//Initialize for Callback

static void PrefChangeCallBack(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo){
	[Preferences release];
	NSLog(@"Darwin : I am working, bro");
	Preferences = [[NSDictionary alloc] initWithContentsOfFile: PrefFilePath];
}


__attribute__((constructor)) static void __init__() {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	Preferences = [[NSDictionary alloc] initWithContentsOfFile: PrefFilePath];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PrefChangeCallBack, CFSTR(PrefChangeNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
	
	[pool release];
}




// vim:ft=objc
