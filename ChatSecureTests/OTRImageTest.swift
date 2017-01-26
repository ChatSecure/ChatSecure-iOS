//
//  OTRImageTest.swift
//  ChatSecure
//
//  Created by David Chiles on 1/25/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import XCTest
@testable import ChatSecureCore



class OTRImageTest: XCTestCase {
    
    struct ImageInfo {
        let name:String
        let image:UIImage
    }
    
    func imageForName(name:String, type:String) -> UIImage? {
        let bundle = NSBundle(forClass: self.dynamicType)
        guard let path = bundle.pathForResource(name, ofType: type) else {
            return nil
        }
        let image = UIImage(contentsOfFile: path)
        return image
    }
    
    func testImages() {
        let resizeImageSize:CGFloat = 120
        
        ["small","landscape","portrait"].map { (name) -> ImageInfo in
            return ImageInfo(name: name, image: self.imageForName(name, type: "jpg")!)
        }.forEach { (imageInfo) in
            let minSide = min(imageInfo.image.size.height, imageInfo.image.size.width)
            let croppedImage = UIImage.otr_squareCropImage(imageInfo.image)
            XCTAssertTrue(CGSizeEqualToSize(croppedImage.size,CGSizeMake(minSide, minSide)),"Checking \(imageInfo.name) square cropping.")
            
            let newImage = UIImage.otr_prepareForAvatarUpload(imageInfo.image, maxSize: resizeImageSize)
            let expectedSide = min(resizeImageSize,minSide)
            let expectedSize = CGSizeMake(expectedSide, expectedSide)
            XCTAssertTrue(CGSizeEqualToSize(newImage.size, expectedSize),"Checking crop and resize for \(imageInfo.name). Expected \(expectedSize). Found \(newImage.size).")
            
        }
    }


}
