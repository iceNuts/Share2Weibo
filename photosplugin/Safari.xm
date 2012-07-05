#import <tweet2weibo/TWTweetComposeViewController.h>
#import <tweet2weibo/TWUserRecord.h>
#import <tweet2weibo/TWMentionTableViewCell.h>
#import <tweet2weibo/TWTweetSheetLocationAssembly.h>
#import <tweet2weibo/TWTweetComposeViewController-TWTweetComposeViewControllerMentionAdditions.h>
#import <tweet2weibo/UIActionSheet-Private.h>


BOOL pwflagSafari = NO;
id fullPathSafari = nil;
static id safariURL = nil;

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

//////////////////////////
/////// IPC LOGIN////////
//////////////////////////
BOOL getStatusSafari(){
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
id cellSafari;
id searchBarTextSafari = [[NSString alloc] init];
BOOL isCancelTappedSafari = NO;

%hook UIButton
- (void)setEnabled:(BOOL)arg1{
	if(pwflagSafari){
		%orig(YES);
		return;
	}
	%orig(arg1);
}
%end

%hook TWTweetComposeViewController

+ (BOOL)canSendTweet{
	if(pwflagSafari){
		return true;
	}
	return %orig;
}
+ (BOOL)canSendTweetViaTwitterd{
	if(pwflagSafari){
		return true;
	}
	return %orig;
}
- (void)send:(id)arg1{
	if(pwflagSafari){
		
		NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys: [[self enteredText] stringByAppendingString: safariURL], @"text", nil, @"imgPath",nil ];
		CPDistributedMessagingCenter *center;
		center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
		[center sendMessageName:@"com.icenuts.share2weibo.send" userInfo: dictionary];
		
		pwflagSafari = false;
		[self complete: 0];
	}else{
		%orig;
	}
}
- (void)sendButtonTapped:(id)arg1{
	isCancelTappedSafari = NO;
	if(pwflagSafari){
		[self send: arg1];
		return;
	}
	%orig;
}

- (void)cancelButtonTapped:(id)arg1{
	isCancelTappedSafari = YES;
	%orig;
}

-(void) viewWillDisappear:(BOOL)arg1{
	if(arg1 && pwflagSafari && isCancelTappedSafari){
		CPDistributedMessagingCenter *center;
		center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
		[center sendMessageName:@"com.icenuts.photo2weibo.cleardb" userInfo: nil];
		pwflagSafari = false;
		isCancelTappedSafari = NO;
	}
	%orig;
}

- (void)textViewDidChange:(id)arg1{
	//B: IPC For Renew Content
	if(pwflagSafari){
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
	if(pwflagSafari){
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
		
		var = class_getInstanceVariable([self class], "_countLabel");
		id countLabel = object_getIvar(self, var);
		[countLabel setText: [NSString stringWithFormat:@"i", (140 - [safariURL length])]];
		[countLabel setHidden: NO];
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
	pwflagSafari = false;
	%orig;
}
- (void)presentNoAccountsDialog{
	if(!pwflagSafari){
		%orig;
	}
}
- (int)characterCountForEnteredText:(id)arg1 attachments:(id)arg2 allImagesDownsampled:(char *)arg3{
	if(pwflagSafari){
		arg2 = nil;
	}
	return %orig;
}
- (void)tableView:(id)arg1 didSelectRowAtIndexPath:(id)arg2{
	cellSafari = [arg1 cellForRowAtIndexPath:arg2];
	%orig;
}
- (void)searchBar:(id)arg1 textDidChange:(id)arg2{
	searchBarTextSafari = [arg2 copy];
	if(pwflagSafari){
		[self noteMentionsResultsChanged];
	}
	%orig;
}
- (void)searchBarWillClear:(id)arg1{
	%orig;
}
- (id)currentResults{
	if(pwflagSafari){
		//Use weibodb
		
		NSMutableArray *specs = [NSMutableArray array];
		
		if([searchBarTextSafari isEqualToString: @""]){
			NSLog(@"------CLEAR------");
			return nil;
		}
						
		CPDistributedMessagingCenter *center;
		center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
		NSDictionary *Result = [center sendMessageAndReceiveReplyName:@"com.icenuts.photo2weibo.query" userInfo: [NSDictionary dictionaryWithObjectsAndKeys: searchBarTextSafari, @"msg",nil ]];
		
		TWUserRecord *item1 = [TWUserRecord userRecordWithScreenName: searchBarTextSafari];
		
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
	if(pwflagSafari && [[cellSafari userRecord] screen_name] != nil){
		arg1 = [[[cellSafari userRecord] screen_name] stringByAppendingString: @" "];
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

id mySheet = nil;
id viewController = nil;
id sendViewSafari = nil;
id address = nil;
id safariBrowser = nil;

//Basic hook for adding button in ActionSheet
%hook UIActionSheet

- (void)presentSheetInView:(id)arg1{
	
	NSString *bundleId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
	BOOL iPad = [[[UIDevice currentDevice] model] isEqualToString: @"iPad"];
	
	if ([bundleId isEqualToString:@"com.apple.mobilesafari"] && !iPad);
		
		id button = [self buttons];
		BOOL x1 = [[[button objectAtIndex:0] title] isEqualToString: @"Add Bookmark"];
		BOOL x2 = [[[button objectAtIndex:0] title] isEqualToString: @"添加书签"];
		BOOL x3 = [[[button objectAtIndex:0] title] isEqualToString: @"新增書籤"];
		if(x1 || x2 || x3){
			NSLog(@"----I INJECT U-----");
			if(x1){
				[self addButtonWithTitle:@"Weibo"];
			}else if(x2){
				[self addButtonWithTitle:@"新浪微博"];
			}else if(x3){
				[self addButtonWithTitle:@"新浪微薄"];
			}
			
			[button exchangeObjectAtIndex:[button count] - 2 withObjectAtIndex:[button count] - 1];

			id cancelButton = [button objectAtIndex:[button count] - 1];
			if (cancelButton) {
						[cancelButton setTag:[button count]];
			}

			id weiboButton = [button objectAtIndex:[button count] - 2];
			if (weiboButton) {
						[weiboButton setTag:[button count] - 1];
			}
			self.cancelButtonIndex = [button count] - 1;
			//Get sheet
			mySheet = self;
		}
		%orig;
}

- (void)_presentFromBarButtonItem:(id)arg1 orFromRect:(struct CGRect)arg2 inView:(id)arg3 direction:(int)arg4 allowInteractionWithViews:(id)arg5 backgroundStyle:(int)arg6 animated:(BOOL)arg7{
	NSString *bundleId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
	BOOL iPad = [[[UIDevice currentDevice] model] isEqualToString: @"iPad"];
	if ([bundleId isEqualToString:@"com.apple.mobilesafari"] && iPad){
		
		id button = [self buttons];
		int cc = [self cancelButtonIndex];
		int value = -1;
		int cbtn = (int)&value;
		
		object_setInstanceVariable(self, "_cancelButton", *(int**)cbtn);
		
		NSLog(@"----%i----", [self cancelButtonIndex]);
		
		[button removeObjectAtIndex: cc];
		
		BOOL x1 = [[[button objectAtIndex:0] title] isEqualToString: @"Add Bookmark"];
		BOOL x2 = [[[button objectAtIndex:0] title] isEqualToString: @"添加书签"];
		BOOL x3 = [[[button objectAtIndex:0] title] isEqualToString: @"新增書籤"];
		if(x1 || x2 || x3){
			NSLog(@"----I INJECT U-----");
			if(x1){
				[self addButtonWithTitle:@"Weibo"];
			}else if(x2){
				[self addButtonWithTitle:@"新浪微博"];
			}else if(x3){
				[self addButtonWithTitle:@"新浪微薄"];
			}
			//Get sheet
			mySheet = self;
		}
	}
	%orig;	
}

- (void)dismissWithClickedButtonIndex:(int)arg1 animated:(BOOL)arg2{
	if(arg1 == -1){
		%orig(-1,1);
		return;
	}
	NSString *bundleId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
	if([bundleId isEqualToString:@"com.apple.mobilesafari"] && [self isEqual: mySheet]){
		BOOL x1 = [[self buttonTitleAtIndex: arg1] isEqualToString: @"Weibo"];
		BOOL x2 = [[self buttonTitleAtIndex: arg1] isEqualToString: @"新浪微博"];
		BOOL x3 = [[self buttonTitleAtIndex: arg1] isEqualToString: @"新浪微薄"];
		if(x1 || x2 || x3){
			if(getStatusSafari()){
					pwflagSafari = YES;
					//B: IPC For Remnant
					CPDistributedMessagingCenter *center;
					center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
					NSDictionary* reply = [center sendMessageAndReceiveReplyName:@"com.icenuts.photo2weibo.remnant" userInfo: nil];
					//E: IPC For Remnant
					
					address = [safariBrowser addressView];
					Ivar var;
					const char *name = "_URLString";
					var = class_getInstanceVariable([address class], name);
					id url = object_getIvar(address, var);
					
					safariURL = [url copy];
					
					[sendViewSafari _setText: [reply valueForKey: @"msg"]];
					[viewController presentViewController: sendViewSafari animated: NO completion: NULL];
				}else{
				//redirect
				CPDistributedMessagingCenter *center;
				center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
				[center sendMessageName:@"com.icenuts.photo2weibo.redirect" userInfo: nil];
			}
		}else{
			pwflagSafari = NO;
		}	
	}
	%orig;
}

%end

%hook BrowserRootViewController
- (id)init{
	Class $TWTweetComposeViewController = objc_getClass("TWTweetComposeViewController");
	viewController = self;
	sendViewSafari = [[$TWTweetComposeViewController alloc] init];
	%orig;
}
%end

%hook Application
- (void)applicationDidFinishLaunching:(id)arg1{
	Ivar var;
	const char *name = "_controller";
	var = class_getInstanceVariable([self class], name);
	safariBrowser = object_getIvar(self, var);
	%orig;
}
- (void)applicationDidBecomeActive:(id)arg1{
	Ivar var;
	const char *name = "_controller";
	var = class_getInstanceVariable([self class], name);
	safariBrowser = object_getIvar(self, var);
	%orig;
}
%end






