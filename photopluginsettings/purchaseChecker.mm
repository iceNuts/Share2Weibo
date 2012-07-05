#import "purchaseChecker.h"

@implementation dataParser
@synthesize parseData;
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
	self.parseData = [string copy];
}
@end

@implementation purchaseChecker

-(id) readCode{
	id preference = [[NSDictionary alloc] initWithContentsOfFile: @"/var/mobile/Library/Preferences/com.icenuts.photoplugin.authorize.plist"];
	return [preference objectForKey: @"redeemtext"];
}

-(BOOL) purchase{
	id udid = [[UIDevice currentDevice] uniqueIdentifier];
	id code = [self readCode];
	if(udid && code){
		NSString* requestString = [[[@"http://change.59igou.com/AuthorService.asmx/JY_UDID_SN?soft_id=2&SN=" stringByAppendingString: code] stringByAppendingString: @"&UDID="] stringByAppendingString: udid];
		
		NSURL* url = [NSURL URLWithString: requestString];     
		NSMutableURLRequest* request = [NSMutableURLRequest new];     
		[request setURL:url];     
		[request setHTTPMethod:@"GET"]; 
		NSURLResponse* response;
		NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse: &response error:nil];  
		id parser = [[NSXMLParser alloc] initWithData: data];
		id parseDelegate = [[dataParser alloc] init];
		[parser setDelegate: parseDelegate];
		[parser parse];
		id flag = [parseDelegate parseData];
		if([flag isEqualToString: @"1"]){
			return YES;
		}
		return NO;
	}
	return NO;
}

-(BOOL) isPurchased{
	id 	udid = [[UIDevice currentDevice] uniqueIdentifier];
	if(udid){
		NSString* requestString = [@"http://change.59igou.com/AuthorService.asmx/JY_UDID_DATABASE?soft_id=2&UDID=" stringByAppendingString: udid];
		NSURL* url = [NSURL URLWithString: requestString];     
		NSMutableURLRequest* request = [NSMutableURLRequest new];     
		[request setURL:url];     
		[request setHTTPMethod:@"GET"]; 
		NSURLResponse* response;
		NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse: &response error:nil];  
		id parser = [[NSXMLParser alloc] initWithData: data];
		id content = [[NSString alloc] initWithData: data encoding:NSUTF8StringEncoding];
		id parseDelegate = [[dataParser alloc] init];
		[parser setDelegate: parseDelegate];
		[parser parse];
		id flag = [parseDelegate parseData];
		if([flag isEqualToString: @"1"]){
			return YES;
		}
		return NO;
	}
	return NO;
}

@end