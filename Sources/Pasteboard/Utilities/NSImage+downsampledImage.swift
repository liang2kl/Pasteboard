//
//  NSImage+downsampledImage.swift
//  Pasteboard
//
//  Created by liang2kl on 2021/8/3.
//

import AppKit
import ImageIO

extension NSImage {
    func downsampledImage() -> NSImage? {
        if self.size.height < 300 { return self }
        let size = CGSize(width: 300, height: 300 * self.size.height / self.size.width)

        // Create an CGImageSource that represent an image
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let data = self.pngData(),
              let path = FileManager.default.createTempFile(contents: data)
        else { return nil }
        
        guard let imageSource = CGImageSourceCreateWithURL(path as CFURL, imageSourceOptions) else { return nil }
        
        // Calculate the desired dimension
        let maxDimensionInPixels = max(size.width, size.height)
        
        // Perform downsampling
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as CFDictionary
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return nil
        }
        
        try? FileManager.default.removeItem(at: path)
        // Return the downsampled image as UIImage
        return NSImage(cgImage: downsampledImage, size: self.size)
    }

}
