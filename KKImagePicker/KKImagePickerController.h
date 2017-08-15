//
//  KKImagePickerController.h
//  KKImagePicker
//
//  Created by dev2.ttm on 1/11/16.
//  Copyright © 2016 dev2.ttm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

typedef NS_ENUM(NSInteger,KKImagePickerType) {
    KKImagePickerTypePhotos,
    KKImagePickerTypeVideos,
    KKImagePickerTypeCamera
};
//图片选择器
@interface KKImagePickerController : UIViewController

@property (nonatomic, copy) void(^cropBlock)(UIImage *image);
@property (nonatomic, assign) BOOL allowsEditing;
@property (nonatomic, assign) KKImagePickerType imagePickerType;

@end

//展示图片cell
@interface KKImageCollectionViewCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *imageView;
@end

//图片编辑器
@interface KKImageEditController : UIViewController

@property (nonatomic, strong) ALAsset *asset;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, copy) void(^editingBlock)(UIImage *image);

@end