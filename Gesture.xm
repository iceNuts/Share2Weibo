#import "libactivator.h"
#import "sqlService.h"
#import <tweet2weibo/TWTweetComposeViewController.h>
#import <tweet2weibo/TWUserRecord.h>
#import <tweet2weibo/TWMentionTableViewCell.h>
#import <tweet2weibo/TWTweetSheetLocationAssembly.h>
#import <tweet2weibo/TWTweetComposeViewController-TWTweetComposeViewControllerMentionAdditions.h>
#import <tweet2weibo/UIActionSheet-Private.h>

BOOL pwflagGesture = NO;
UIWindow *wd;
UIAlertView* av;
id sendViewGesture;

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
BOOL getStatusGesture(){
	sqlService *sqlSer = [[sqlService alloc] init];
	NSMutableArray *temparray=  [sqlSer getuserList];
	if(![temparray count]){
		return NO;
	}
	double expireTime = [[temparray objectAtIndex:2] doubleValue];
    if(expireTime > 0){
		return YES;
	}
	return NO;
}

//////////////////////////
/////// IPC LOGIN////////
//////////////////////////

//////////////////////////
/////// Twitter UI////////
//////////////////////////

//Hook for twitter UI
id cellGesture;
id searchBarTextGesture = [[NSString alloc] init];
BOOL isCancelTappedGesture = NO;

%hook UIButton
- (void)setEnabled:(BOOL)arg1{
	if(pwflagGesture){
		%orig(YES);
		return;
	}
	%orig(arg1);
}
%end

%hook TWTweetComposeViewController

+ (BOOL)canSendTweet{
	if(pwflagGesture){
		return true;
	}
	return %orig;
}
+ (BOOL)canSendTweetViaTwitterd{
	if(pwflagGesture){
		return true;
	}
	return %orig;
}
- (void)send:(id)arg1{
	if(pwflagGesture){
		
		NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys: [self enteredText], @"text", nil, @"imgPath",nil ];
		CPDistributedMessagingCenter *center;
		center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
		[center sendMessageName:@"com.icenuts.share2weibo.send" userInfo: dictionary];
		
		pwflagGesture = false;
		[self complete: 0];
		
		//DISMISS
		if (wd) {
			[wd release];
			wd = nil;
			if(av){
				[av release];
				av = nil;
			}
		}
		
	}else{
		%orig;
	}
}
- (void)sendButtonTapped:(id)arg1{
	isCancelTappedGesture = NO;
	if(pwflagGesture){
		[self send: arg1];
		return;
	}
	%orig;
}

- (void)cancelButtonTapped:(id)arg1{
	isCancelTappedGesture = YES;
	%orig;
}

-(void) viewWillDisappear:(BOOL)arg1{
	if(arg1 && pwflagGesture && isCancelTappedGesture){
		CPDistributedMessagingCenter *center;
		center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
		[center sendMessageName:@"com.icenuts.photo2weibo.cleardb" userInfo: nil];
		pwflagGesture = false;
		isCancelTappedGesture = NO;
	}
	%orig;
}

- (void)textViewDidChange:(id)arg1{
	//B: IPC For Renew Content
	if(pwflagGesture){
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
	if(pwflagGesture){
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
	pwflagGesture = false;
	%orig;
}
- (void)presentNoAccountsDialog{
	if(!pwflagGesture){
		%orig;
	}
}
- (int)characterCountForEnteredText:(id)arg1 attachments:(id)arg2 allImagesDownsampled:(char *)arg3{
	if(pwflagGesture){
		arg2 = nil;
	}
	return %orig;
}
- (void)tableView:(id)arg1 didSelectRowAtIndexPath:(id)arg2{
	cellGesture = [arg1 cellForRowAtIndexPath:arg2];
	%orig;
}
- (void)searchBar:(id)arg1 textDidChange:(id)arg2{
	searchBarTextGesture = [arg2 copy];
	if(pwflagGesture){
		[self noteMentionsResultsChanged];
	}
	%orig;
}
- (void)searchBarWillClear:(id)arg1{
	%orig;
}
- (id)currentResults{
	if(pwflagGesture){
		//Use weibodb
		
		NSMutableArray *specs = [NSMutableArray array];
		
		if([searchBarTextGesture isEqualToString: @""]){
			NSLog(@"------CLEAR------");
			return nil;
		}
						
		sqlService *sql = [[sqlService alloc] init];
		NSDictionary *Result = [[NSDictionary alloc]init];	
		Result = [sql getweibofriendHead: searchBarTextGesture];
		
		TWUserRecord *item1 = [TWUserRecord userRecordWithScreenName: searchBarTextGesture];
		
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
	if(pwflagGesture && [[cellGesture userRecord] screen_name] != nil){
		arg1 = [[[cellGesture userRecord] screen_name] stringByAppendingString: @" "];
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

@interface Gesture: NSObject<LAListener, UIAlertViewDelegate>{
	
}
@end



@implementation Gesture

- (BOOL)dismiss
{
	// Ensures alert view is dismissed
	// Returns YES if alert was visible previously
	if (wd) {
		[wd release];
		wd = nil;
		if(av){
			[av release];
			av = nil;
		}
		return YES;
	}
	return NO;
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
	//redirect
	CPDistributedMessagingCenter *center;
	center = [CPDistributedMessagingCenter centerNamed:@"com.icenuts.photo2weibo.bannerserver"];
	[center sendMessageName:@"com.icenuts.photo2weibo.redirect" userInfo: nil];
	[av release];
	av = nil;
}

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event
{
	// Called when we recieve event
	if (![self dismiss]) {
		if(getStatusGesture()){
			pwflagGesture = YES;
			wd = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
			wd.screen = [UIScreen mainScreen];
			[wd setWindowLevel: UIWindowLevelStatusBar];
			Class $TWTweetComposeViewController = objc_getClass("TWTweetComposeViewController");
			sendViewGesture = [[$TWTweetComposeViewController alloc] init];
			[wd setRootViewController: [[UIViewController alloc] init]];
			NSLog(@"----@@@@@-----");
			[wd makeKeyAndVisible];			
			[[wd rootViewController] presentViewController: sendViewGesture animated: NO completion: NULL];
		}else{
			pwflagGesture = NO;
			av = [[UIAlertView alloc] initWithTitle:@"请先登陆新浪微博" message:[event name] delegate:self cancelButtonTitle:@"好" otherButtonTitles:nil];
			[av setMessage: nil];
			[av show];
		}
		
		[event setHandled:YES];
	}
}

- (void)activator:(LAActivator *)activator abortEvent:(LAEvent *)event
{
	// Called when event is escalated to a higher event
	// (short-hold sleep button becomes long-hold shutdown menu, etc)
	[self dismiss];
}

- (void)activator:(LAActivator *)activator otherListenerDidHandleEvent:(LAEvent *)event
{
	// Called when some other listener received an event; we should cleanup
	[self dismiss];
}

- (void)activator:(LAActivator *)activator receiveDeactivateEvent:(LAEvent *)event
{
	// Called when the home button is pressed.
	// If (and only if) we are showing UI, we should dismiss it and call setHandled:
	if ([self dismiss])
		[event setHandled:YES];
}

- (void)dealloc
{
	// Since this object lives for the lifetime of SpringBoard, this will never be called
	// It's here for the sake of completeness
	[wd release];
	[super dealloc];
}

+ (void)load
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	// Register our listener
	[[LAActivator sharedInstance] registerListener:[self new] forName:@"com.icenuts.photopluginactivator"];
	[pool release];
}

@end