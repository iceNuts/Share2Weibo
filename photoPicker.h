#import "Constants.h"

@interface photoPicker: NSObject <UIImagePickerControllerDelegate>
{
}

@property (nonatomic, retain) id parentViewController;
@property (nonatomic, retain) id picImageView;
@property (nonatomic) BOOL isAdded;
@property (nonatomic, retain) id picStatusLabel;
@property (nonatomic, retain) id glow;
@property (nonatomic, retain) id chose;
@property (nonatomic, retain) id text;
@property (nonatomic, retain) id rawData;
@property (nonatomic, retain) id popover;


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker;
@end