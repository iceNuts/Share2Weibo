#import "photoPicker.h"

@implementation photoPicker

@synthesize parentViewController;
@synthesize picImageView;
@synthesize isAdded;
@synthesize picStatusLabel;
@synthesize glow;
@synthesize chose;
@synthesize text;

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
	self.chose = [info objectForKey:UIImagePickerControllerOriginalImage];
	self.isAdded = YES;
	//set label & glow view
	[self.picStatusLabel setLocationLabelText: nil];
	[parentViewController dismissModalViewControllerAnimated: YES];
	[parentViewController _setText: text];
}

@end
 