#import <tweet2weibo/TWTweetComposeViewController.h>
#import <tweet2weibo/TWUserRecord.h>
#import <tweet2weibo/TWMentionTableViewCell.h>
#import <tweet2weibo/TWTweetSheetLocationAssembly.h>
#import <tweet2weibo/TWTweetComposeViewController-TWTweetComposeViewControllerMentionAdditions.h>

BOOL sharePhoto = NO;
BOOL pwflag = NO;
id fullPath = nil;
int numberOfPhotos = 0;

static id viewController = nil;

//IPC Declaration
@interface CPDistributedMessagingCenter
+ (id)centerNamed:(id)arg1;
- (BOOL)sendMessageName:(id)arg1 userInfo:(id)arg2;
- (void)runServerOnCurrentThread;
- (void)registerForMessageName:(id)arg1 target:(id)arg2 selector:(SEL)arg3;
- (id)sendMessageAndReceiveReplyName:(id)arg1 userInfo:(id)arg2;
- (void)stopServer;
- (BOOL)doesServerExist;
@end

@interface CPActionSheet
- (id)addButton:(id)arg1;
- (void)dismiss;
@end

//////////////////////////
/////// IPC LOGIN////////
//////////////////////////
BOOL getStatus(){
	CPDistributedMessagingCenter *center;
	center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
	NSDictionary* reply = [center sendMessageAndReceiveReplyName:@"com.icenuts.photo2weibo.login" userInfo: nil];
	if([[reply valueForKey: @"msg"] isEqualToString: @"1"]){
		return YES;
	}else{
		return NO;
	}
}

//////////////////////////
/////// IPC LOGIN////////
//////////////////////////


//////////////////////////
/////// Twitter UI////////
//////////////////////////

//Hook for twitter UI
id cell;
id searchBarText = [[NSString alloc] init];
BOOL isCancelTapped = NO;
@class LightboxPhoto;

%hook UIButton
- (void)setEnabled:(BOOL)arg1{
	if(pwflag){
		%orig(YES);
		return;
	}
	%orig(arg1);
}
%end

%hook LightboxPhoto
- (void)save{
	%log;
	%orig;
}
%end

%hook TWTweetComposeViewController

+ (BOOL)canSendTweet{
	if(pwflag){
		return true;
	}
	return %orig;
}
+ (BOOL)canSendTweetViaTwitterd{
	if(pwflag){
		return true;
	}
	return %orig;
}
- (void)send:(id)arg1{
	if(pwflag){
		NSLog(@"-----NUM %i----", numberOfPhotos);
		if(numberOfPhotos){
			if(numberOfPhotos > 1){
				
			}else{
				NSLog(@"---fullPath: %@----", fullPath);
				
				NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys: [self enteredText], @"text", fullPath, @"imgPath",nil ];
				CPDistributedMessagingCenter *center;
				center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
				[center sendMessageName:@"com.icenuts.share2weibo.send" userInfo: dictionary];
				
			}
		}
		pwflag = false;
		[viewController dismissViewControllerAnimated:YES completion:^{}];
		[self complete: 0];
	}else{
		%orig;
	}
}
- (void)sendButtonTapped:(id)arg1{
	isCancelTapped = NO;
	if(pwflag){
		[self send: arg1];
		return;
	}
	%orig;
}

- (void)cancelButtonTapped:(id)arg1{
	isCancelTapped = YES;
	%orig;
}

-(void) viewWillDisappear:(BOOL)arg1{
	if(arg1 && pwflag && isCancelTapped){
		CPDistributedMessagingCenter *center;
		center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
		[center sendMessageName:@"com.icenuts.photo2weibo.cleardb" userInfo: nil];
		pwflag = false;
		isCancelTapped = NO;
	}
	%orig;
}

- (void)textViewDidChange:(id)arg1{
	//B: IPC For Renew Content
	if(pwflag){
		NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys: [self enteredText], @"text", nil ];
		CPDistributedMessagingCenter *center;
		center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
		[center sendMessageName:@"com.icenuts.photo2weibo.renew" userInfo: dictionary];
	}
	//E: IPC For Renew Content
	%orig;
}

//hook to grab the superclass's variable
- (void)viewDidAppear:(BOOL)arg1{
	if(pwflag){
		Ivar var;
		const char *name = "_tweetTitleLabel";
		var = class_getInstanceVariable([self class], name);
		id label = object_getIvar(self, var);
		if([[label text] isEqualToString:@"Tweet"] || [[label text] isEqualToString:@"Weibo"]){
			[label setText: @"Weibo"];
		}else{
			[label setText: @"新浪微博"];
		}
		var = class_getInstanceVariable([self class], "_locationAssembly");
		id assembly = object_getIvar(self, var);
		var = class_getInstanceVariable([TWTweetSheetLocationAssembly self], "_assemblyView");
		id geo = object_getIvar(assembly, var);
		[geo setHidden: YES];
		var = class_getInstanceVariable([self class], "_sendButton");
		id sendButton = object_getIvar(self, var);
		[sendButton setEnabled: YES];
	}
	%orig;
}

/////////////////////////
//Avoid multiple accounts
/////////////////////////

- (BOOL)showAccountFieldForOrientation:(int)arg1{
	return NO;
}

/////////////////////////
//Avoid multiple accounts
/////////////////////////

- (void)appWillMoveToBackground:(id)arg1{
	pwflag = false;
	%orig;
}
- (void)presentNoAccountsDialog{
	if(!pwflag){
		%orig;
	}
}
- (int)characterCountForEnteredText:(id)arg1 attachments:(id)arg2 allImagesDownsampled:(char *)arg3{
	if(pwflag){
		arg2 = nil;
	}
	return %orig;
}
- (void)tableView:(id)arg1 didSelectRowAtIndexPath:(id)arg2{
	cell = [arg1 cellForRowAtIndexPath:arg2];
	%orig;
}
- (void)searchBar:(id)arg1 textDidChange:(id)arg2{
	searchBarText = [arg2 copy];
	if(pwflag){
		[self noteMentionsResultsChanged];
	}
	%orig;
}
- (void)searchBarWillClear:(id)arg1{
	%orig;
}
- (id)currentResults{
	if(pwflag){
		//Use weibodb
		
		NSMutableArray *specs = [NSMutableArray array];
		
		if([searchBarText isEqualToString: @""]){
			NSLog(@"------CLEAR------");
			return nil;
		}
						
		CPDistributedMessagingCenter *center;
		center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
		NSDictionary *Result = [center sendMessageAndReceiveReplyName:@"com.icenuts.photo2weibo.query" userInfo: [NSDictionary dictionaryWithObjectsAndKeys: searchBarText, @"msg",nil ]];
		
		TWUserRecord *item1 = [TWUserRecord userRecordWithScreenName: searchBarText];
		
		[specs addObject: item1];
		int number = [Result count];
		
		NSString *object;
		NSRange myRange;
		NSString *screenName = nil;
		NSString *alias = nil;
		NSString *sqlAliasdelete1;
		NSString *screenAliasTemp;
		
		for(int i = 0; i < number; i++){
			object = [Result valueForKey:[NSString stringWithFormat:@"%i",i]];
			myRange = [object rangeOfString:@"("];
			if(myRange.length > 0){
				screenName = [object substringToIndex: myRange.location];
				screenAliasTemp = [object substringFromIndex:myRange.location];
				sqlAliasdelete1 = [screenAliasTemp stringByReplacingOccurrencesOfString:@"("  withString:@""];
				alias = [sqlAliasdelete1 stringByReplacingOccurrencesOfString:@")"  withString:@""];
			}else{
				screenName = [object copy];
			}
			TWUserRecord *item = [TWUserRecord userRecordWithScreenName: screenName];
			[item setName: alias];
			[specs addObject: item];
		}
		
		return specs;
	}else{
		return %orig;
	}
}
- (struct _NSRange)applyMention:(id)arg1{
	if(pwflag && [[cell userRecord] screen_name] != nil){
		arg1 = [[[cell userRecord] screen_name] stringByAppendingString: @" "];
	}else if(arg1 == nil){
		Ivar var;
		const char *name = "_searchField";
		var = class_getInstanceVariable([self class], name);
		id searchBar = object_getIvar(self, var);
		arg1 = [searchBar text];
	}
	return %orig;
}
%end

//////////////////////////
/////// Twitter UI////////
//////////////////////////

int sp = 0;
BOOL isZoom = NO;


%hook CPActionSheet

%new(@@:@)
- (IBAction) sharePhotos:(id)sender {
	if(getStatus()){
		pwflag = YES;
		if(isZoom)
		{
			NSLog(@"ZOOOOOOOOM!!!!!!");
			CPDistributedMessagingCenter *
			center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.cameraplusZoom"];
			[center sendMessageName: @"com.icenuts.photo2weibo.cameraplusZoom.tweet" userInfo: nil];
		}else{
			NSLog(@"INNNNNNNNN!!!!!!");
			CPDistributedMessagingCenter *
			center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.cameraplus"];
			[center sendMessageName: @"com.icenuts.photo2weibo.cameraplus.tweet" userInfo: nil];
		}
	}else{
		pwflag = NO;
		//redirect
		CPDistributedMessagingCenter *center;
		center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
		[center sendMessageName:@"com.icenuts.photo2weibo.redirect" userInfo: nil];
	}
	[self dismiss];
}

- (void)showInView:(id)arg1{
	if(sharePhoto && (sp == 1 || isZoom)){
		id subview = [self subviews];
		id cancel = [subview lastObject];
		//Copy From Mail
		NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject: [subview objectAtIndex: 0]];
		UIButton *buttonCopy = [NSKeyedUnarchiver unarchiveObjectWithData: archivedData];
		[buttonCopy setTitle: @"Weibo" forState: UIControlStateNormal];
		[buttonCopy setTitle: @"Weibo" forState: UIControlStateSelected];
		[buttonCopy setTag: (101 + [subview count])];
		int y = [[subview objectAtIndex: [subview count] - 2] frame].origin.y + 56;
		[buttonCopy setFrame: CGRectMake(21, y,278,46)];
		[self insertSubview: buttonCopy atIndex: [subview count] - 2];
		[buttonCopy addTarget: self action:@selector(sharePhotos:) forControlEvents:UIControlEventTouchUpInside];
		//Get more space
		id pButton = [self addButton: @""];
		[pButton removeFromSuperview];
		//Move down Cancel
		[cancel setFrame: CGRectMake(21, y+73, 278, 46)];
		sharePhoto = NO;
	}
	%orig;
}
%end

BOOL started = NO;

@interface LightboxViewController
@property(readonly, nonatomic) LightboxPhoto *selectedPhoto;
- (unsigned int)numberOfSelectedPhotos;
@property(nonatomic) NSArray *selectedPhotos;
@property(readonly, nonatomic) LightboxPhoto *latestPhoto;
@end

%hook LightboxViewController
- (id)init{
	if(started){
		return %orig;
	}
	started = YES;
	CPDistributedMessagingCenter *
		center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.cameraplus"];

	[center runServerOnCurrentThread];
	[center registerForMessageName:@"com.icenuts.photo2weibo.cameraplus.tweet" target:self selector:@selector(handleMessageNamed:userInfo:)];
	return %orig;
}

- (void)willEnterForeground{
	if(started){
		%orig;
		return;
	}
	started = YES;
	CPDistributedMessagingCenter *
		center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.cameraplus"];

	[center runServerOnCurrentThread];
	[center registerForMessageName:@"com.icenuts.photo2weibo.cameraplus.tweet" target:self selector:@selector(handleMessageNamed:userInfo:)];
	%orig;
}

%new(v@:@@)
- (void) handleMessageNamed:(NSString *)name userInfo:(NSDictionary *)userInfo{
	if([name isEqualToString:@"com.icenuts.photo2weibo.cameraplus.tweet"]){
		//fetch photos data
		Class $TWTweetComposeViewController = objc_getClass("TWTweetComposeViewController");	
		id sendView = [[$TWTweetComposeViewController alloc] init];
		//B: IPC For Remnant
		CPDistributedMessagingCenter *center;
		center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
		NSDictionary* reply = [center sendMessageAndReceiveReplyName:@"com.icenuts.photo2weibo.remnant" userInfo: nil];
		//Grab a path for image
		NSString* imgPath;
		NSString* full = [[[NSBundle mainBundle] bundlePath] copy];
		NSArray* component = [full componentsSeparatedByString:  @"/"];
		NSString *tmp = [full substringToIndex: [full length] - [[component lastObject] length]];
		NSString *xtmp = [tmp copy];
		tmp = [tmp stringByAppendingString: @"Library/Caches/imagesx/"];
		imgPath = [tmp stringByAppendingString: [[[self selectedPhoto] imageName] stringByAppendingString: @"/"]];
		
		NSArray *effectArray = [[[self selectedPhoto] recipe] componentsSeparatedByString:@","];
		NSFileManager *fm = [NSFileManager defaultManager];
		NSArray *dirContents = [fm contentsOfDirectoryAtPath:imgPath error:nil];
		NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self contains[cd] %@",@"_trans_"];
		NSArray *rr = [dirContents filteredArrayUsingPredicate:fltr];
		NSMutableArray *result = [rr mutableCopy];
		
		for(int i = 0; i < [effectArray count]; i++){
			//Get Code
			NSString* object = [effectArray objectAtIndex: i];
			if([object rangeOfString: @"code"].location != NSNotFound){
				NSArray* tm = [object componentsSeparatedByString: @"\""];
				NSLog(@"----tm: %@----", tm);
				NSString* code = [tm objectAtIndex: [tm count] - 2];
				//if contains
				for(int j = 0; j < [result count]; j++){
					id item = [result objectAtIndex: j];
					NSLog(@"----CODE: %@----", code);
					NSLog(@"----item: %@----", item);
					if([item rangeOfString: code].location == NSNotFound){
						[result removeObject: item];
					}
				}
			}
		}
			
		NSLog(@"----%@---", result);
		
		if([result count]){
			fullPath = [[imgPath stringByAppendingString: [result objectAtIndex: 0]] copy];
			NSLog(@"----PATH: %@----", fullPath);
		}else{
			fullPath = [[xtmp stringByAppendingString: [@"Documents/" stringByAppendingString: [[self selectedPhoto] imageName]]] copy];
		}	
		numberOfPhotos = 1;		
		viewController = self;			
		[sendView _setText: [reply valueForKey: @"msg"]];
		//E: IPC For Remnant
		[self presentViewController: sendView animated: NO completion: NULL];
		[sendView release];
	}
}

- (void)sharePhotos:(id)arg1 inViewController:(id)arg2{
	sp = [arg1 count];
	sharePhoto = YES;
	%orig;
}
%end

BOOL isStartedZoom = NO;
CPDistributedMessagingCenter *
	centerZoom = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.cameraplusZoom"];

%hook LightboxZoomViewController

- (void)dealloc{
	%log;
	%orig;
}

- (void)viewDidAppear:(BOOL)arg1{
	%log;
	isZoom = YES;
	if([centerZoom doesServerExist]){
		%orig;
		return;
	}
	isStartedZoom = YES;
	[centerZoom runServerOnCurrentThread];
	[centerZoom registerForMessageName:@"com.icenuts.photo2weibo.cameraplusZoom.tweet" target:self selector:@selector(handleMessageNamedZoom:userInfo:)];
	%orig;
}

%new(v@:@@)
- (void) handleMessageNamedZoom:(NSString *)name userInfo:(NSDictionary *)userInfo{
	Ivar var;
	const char *propertyName = "objects";
	var = class_getInstanceVariable([self class], propertyName);
	id objects = object_getIvar(self, var);
	int myIndex = (int)[self index];
	
	NSLog(@"-----%@----", self);
	
	if([name isEqualToString:@"com.icenuts.photo2weibo.cameraplusZoom.tweet"]){
		//fetch photos data
		Class $TWTweetComposeViewController = objc_getClass("TWTweetComposeViewController");
		id sendViewZoom = [[$TWTweetComposeViewController alloc] init];
		//B: IPC For Remnant
		CPDistributedMessagingCenter *center;
		center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
		NSDictionary* reply = [center sendMessageAndReceiveReplyName:@"com.icenuts.photo2weibo.remnant" userInfo: nil];
		//Grab a path for image
		NSString* imgPath;
		NSString* full = [[[NSBundle mainBundle] bundlePath] copy];
		NSArray* component = [full componentsSeparatedByString:  @"/"];
		NSString *tmp = [full substringToIndex: [full length] - [[component lastObject] length]];
		NSString *xtmp = [tmp copy];
		tmp = [tmp stringByAppendingString: @"Library/Caches/imagesx/"];
		imgPath = [tmp stringByAppendingString: [[[objects objectAtIndex: myIndex] imageName] stringByAppendingString: @"/"]];
		
		NSArray *effectArray = [[[objects objectAtIndex: myIndex] recipe] componentsSeparatedByString:@","];
		NSFileManager *fm = [NSFileManager defaultManager];
		NSArray *dirContents = [fm contentsOfDirectoryAtPath:imgPath error:nil];
		NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self contains[cd] %@",@"_trans_"];
		NSArray *rr = [dirContents filteredArrayUsingPredicate:fltr];
		NSMutableArray *result = [rr mutableCopy];
		
		for(int i = 0; i < [effectArray count]; i++){
			//Get Code
			NSString* object = [effectArray objectAtIndex: i];
			if([object rangeOfString: @"code"].location != NSNotFound){
				NSArray* tm = [object componentsSeparatedByString: @"\""];
				NSLog(@"----tm: %@----", tm);
				NSString* code = [tm objectAtIndex: [tm count] - 2];
				//if contains
				for(int j = 0; j < [result count]; j++){
					id item = [result objectAtIndex: j];
					NSLog(@"----CODE: %@----", code);
					NSLog(@"----item: %@----", item);
					if([item rangeOfString: code].location == NSNotFound){
						[result removeObject: item];
					}
				}
			}
		}
			
		NSLog(@"----%@---", result);
		
		if([result count]){
			fullPath = [[imgPath stringByAppendingString: [result objectAtIndex: 0]] copy];
			NSLog(@"----PATH: %@----", fullPath);
		}else{
			fullPath = [[xtmp stringByAppendingString: [@"Documents/" stringByAppendingString: [[objects objectAtIndex: myIndex] imageName]]] copy];
		}	
		numberOfPhotos = 1;					
		[sendViewZoom _setText: [reply valueForKey: @"msg"]];
		//E: IPC For Remnant
		viewController = self;
		if(viewController && sendViewZoom){
			NSLog(@"-----IMGOOD----");
		}
		[viewController presentViewController: sendViewZoom animated: NO completion: NULL];
		[sendViewZoom release];
	}
	
}
- (void)dismiss{
	isZoom = NO;
	[centerZoom stopServer];
	%orig;
}
%end






