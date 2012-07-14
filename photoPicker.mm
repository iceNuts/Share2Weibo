#import "photoPicker.h"
#import "Reachability.h"

#define PrefFilePath @"/var/mobile/Library/Preferences/com.icenuts.photosweibo.image.plist"

@implementation photoPicker

@synthesize parentViewController;
@synthesize picImageView;
@synthesize isAdded;
@synthesize picStatusLabel;
@synthesize glow;
@synthesize chose;
@synthesize text;
@synthesize rawData;
@synthesize popover;

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
	self.chose = [info objectForKey:UIImagePickerControllerOriginalImage];
	self.isAdded = YES;
	//compress photo
	UIImage* original = self.chose;
	
	CGFloat width = original.size.width;
	CGFloat height = original.size.height;
	CGFloat ratio = height/width;
	
	id Preferences = [[NSDictionary alloc] initWithContentsOfFile: PrefFilePath];
	NSString* state;
	int myscale = 600;
	if([[Reachability reachabilityForLocalWiFi] currentReachabilityStatus] == ReachableViaWiFi){
		NSLog(@"-----Wifi-----");
		myscale = 600;
		state = [Preferences valueForKey:@"PhotoImageWifi"];
		if([state isEqualToString: @"low"]){
			myscale = 600;
		}else if([state isEqualToString: @"medium"]){
			myscale = 900;
		}else if([state isEqualToString: @"high"]){
			myscale = 1400;
		}
		if(width > myscale){
			width = myscale;
			height = width*ratio;
		}
	}else{
		myscale = 450;
		state = [Preferences valueForKey:@"PhotoImageCarrier"];
		if([state isEqualToString: @"low"]){
			myscale = 450;
		}else if([state isEqualToString: @"medium"]){
			myscale = 600;
		}else if([state isEqualToString: @"high"]){
			myscale = 900;
		}
		if(width > myscale){
			width = myscale;
			height = width*ratio;
		}
	}
	
	if(width > 650){
		width = 650;
		height = width*ratio;
	}
	CGSize newSize = CGSizeMake(width, height);
	UIGraphicsBeginImageContext(newSize);
	[original drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
	UIImage* send = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	self.chose = send;
	self.rawData = UIImagePNGRepresentation(send);
	//set label & glow view
	[self.picStatusLabel setLocationLabelText: nil];
	[self.picImageView setImage: nil forState: UIControlStateNormal];
	BOOL iPad = [[[UIDevice currentDevice] model] isEqualToString: @"iPad"];
	if(iPad){
		[self.popover dismissPopoverAnimated: YES];
	}else{
		[parentViewController dismissModalViewControllerAnimated: YES];
	}
	[parentViewController _setText: text];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
	BOOL iPad = [[[UIDevice currentDevice] model] isEqualToString: @"iPad"];
	if(iPad){
		[self.popover dismissPopoverAnimated: YES];
	}else{
		[parentViewController dismissModalViewControllerAnimated: YES];
	}
	[parentViewController _setText: text];
}

@end
 