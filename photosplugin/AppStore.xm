#import <tweet2weibo/TWTweetComposeViewController.h>
#import <tweet2weibo/TWUserRecord.h>
#import <tweet2weibo/TWMentionTableViewCell.h>
#import <tweet2weibo/TWTweetSheetLocationAssembly.h>
#import <tweet2weibo/TWTweetComposeViewController-TWTweetComposeViewControllerMentionAdditions.h>

BOOL pwflagStore = NO;
id storeContent = nil;

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
BOOL getStatusStore(){
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
id cellStore;
id searchBarTextStore = [[NSString alloc] init];
BOOL isCancelTappedStore = NO;
@class LightboxPhoto;

%hook UIButton
- (void)setEnabled:(BOOL)arg1{
	if(pwflagStore){
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
	if(pwflagStore){
		return true;
	}
	return %orig;
}
+ (BOOL)canSendTweetViaTwitterd{
	if(pwflagStore){
		return true;
	}
	return %orig;
}
- (void)send:(id)arg1{
	if(pwflagStore){

		NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys: [self enteredText], @"text", nil, @"imgPath",nil ];
		CPDistributedMessagingCenter *center;
		center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
		[center sendMessageName:@"com.icenuts.share2weibo.send" userInfo: dictionary];
		
		pwflagStore = false;
		[self complete: 0];
	}else{
		%orig;
	}
}
- (void)sendButtonTapped:(id)arg1{
	isCancelTappedStore = NO;
	if(pwflagStore){
		[self send: arg1];
		return;
	}
	%orig;
}

- (void)cancelButtonTapped:(id)arg1{
	isCancelTappedStore = YES;
	%orig;
}

-(void) viewWillDisappear:(BOOL)arg1{
	if(arg1 && pwflagStore && isCancelTappedStore){
		CPDistributedMessagingCenter *center;
		center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
		[center sendMessageName:@"com.icenuts.photo2weibo.cleardb" userInfo: nil];
		pwflagStore = false;
		isCancelTappedStore = NO;
	}
	%orig;
}

- (void)textViewDidChange:(id)arg1{
	//B: IPC For Renew Content
	if(pwflagStore){
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
	if(pwflagStore){
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
	pwflagStore = false;
	%orig;
}
- (void)presentNoAccountsDialog{
	if(!pwflagStore){
		%orig;
	}
}
- (int)characterCountForEnteredText:(id)arg1 attachments:(id)arg2 allImagesDownsampled:(char *)arg3{
	if(pwflagStore){
		arg2 = nil;
	}
	return %orig;
}
- (void)tableView:(id)arg1 didSelectRowAtIndexPath:(id)arg2{
	cellStore = [arg1 cellForRowAtIndexPath:arg2];
	%orig;
}
- (void)searchBar:(id)arg1 textDidChange:(id)arg2{
	searchBarTextStore = [arg2 copy];
	if(pwflagStore){
		[self noteMentionsResultsChanged];
	}
	%orig;
}
- (void)searchBarWillClear:(id)arg1{
	%orig;
}
- (id)currentResults{
	if(pwflagStore){
		//Use weibodb
		
		NSMutableArray *specs = [NSMutableArray array];
		
		if([searchBarTextStore isEqualToString: @""]){
			NSLog(@"------CLEAR------");
			return nil;
		}
						
		CPDistributedMessagingCenter *center;
		center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
		NSDictionary *Result = [center sendMessageAndReceiveReplyName:@"com.icenuts.photo2weibo.query" userInfo: [NSDictionary dictionaryWithObjectsAndKeys: searchBarTextStore, @"msg",nil ]];
		
		TWUserRecord *item1 = [TWUserRecord userRecordWithScreenName: searchBarTextStore];
		
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
	if(pwflagStore && [[cellStore userRecord] screen_name] != nil){
		arg1 = [[[cellStore userRecord] screen_name] stringByAppendingString: @" "];
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
id suItem = nil;

%hook SUStorePageViewController
- (void)_setActiveChildViewController:(id)arg1{
	Ivar var;
	const char *name = "_rootItem";
	var = class_getInstanceVariable([arg1 class], name);
	suItem = object_getIvar(arg1, var);
	NSLog(@"----%@----", suItem);
	%orig;
}
%end

%hook SUClientController
- (void)presentMailComposeViewController:(id)arg1 animated:(BOOL)arg2{
	Class $TWTweetComposeViewController = objc_getClass("TWTweetComposeViewController");	
	id storeSendView = [[$TWTweetComposeViewController alloc] init];
	id storeViewController = [self rootViewController];
	pwflagStore = YES;
	
	Ivar var;
	const char *name = "_urlBagKeys";
	var = class_getInstanceVariable([self class], name);
	id urlBags = object_getIvar(self, var);
	
	NSLog(@"----%@----", urlBags);
	
	[storeSendView _setText: nil];
	[storeViewController presentViewController: storeSendView animated: NO completion: NULL];
}
- (BOOL)isComposingEmail{
	return NO;
}
- (void)composeEmailWithSubject:(id)arg1 body:(id)arg2 animated:(BOOL)arg3{
	[self presentMailComposeViewController: nil animated: NO];
}
%end