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

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
@end