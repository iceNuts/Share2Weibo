#import "photoPicker.h"

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

@end
 