//
//  PhotoViewController.swift
//  FoodViz
//
//  Created by Lukas Joswiak on 10/22/17.
//  Copyright © 2017 Lukas Joswiak. All rights reserved.
//

import UIKit
import TesseractOCR

class PhotoViewController: UIViewController, G8TesseractDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    
    var photoTaken: UIImage?
    var rect: CGRect?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let availableImage = photoTaken {
            imageView.image = availableImage
            
            if let rectCoords = rect {
                let croppedImage = availableImage.crop(rect: CGRect(x: rectCoords.minX + 65, y: rectCoords.minY - 150, width: rectCoords.width, height: rectCoords.height))
                self.imageView.image = croppedImage
                
                self.imageView.image = self.imageView.image!.toGrayScale()
                self.imageView.image = self.imageView.image!.binarise()
                self.imageView.image = self.imageView.image!.scaleImage()
                
                if let tesseract = G8Tesseract(language: "eng") {
                    tesseract.delegate = self
                    //tesseract.engineMode = .tesseractCubeCombined
                    tesseract.pageSegmentationMode = .singleLine
                    tesseract.image = self.imageView.image!.g8_blackAndWhite()
                    //tesseract.image = UIImage(named: "home")?.g8_blackAndWhite()
                    tesseract.recognize()
                    
                    print("Recognized text: \(tesseract.recognizedText)")
                }
                
                print("got here")
            }
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}


extension UIImage {
    func toGrayScale() -> UIImage {
        
        let greyImage = UIImageView()
        greyImage.image = self
        let context = CIContext(options: nil)
        let currentFilter = CIFilter(name: "CIPhotoEffectNoir")
        currentFilter!.setValue(CIImage(image: greyImage.image!), forKey: kCIInputImageKey)
        let output = currentFilter!.outputImage
        let cgimg = context.createCGImage(output!,from: output!.extent)
        let processedImage = UIImage(cgImage: cgimg!)
        greyImage.image = processedImage
        
        return greyImage.image!
    }
    
    func crop( rect: CGRect) -> UIImage {
        var rect = rect
        //rect.origin.x*=self.scale
        //rect.origin.y*=self.scale
        rect.size.width*=self.scale
        rect.size.height*=self.scale
        
        let imageRef = self.cgImage!.cropping(to: rect)
        let image = UIImage(cgImage: imageRef!, scale: self.scale, orientation: self.imageOrientation)
        return image
    }
    
    func binarise() -> UIImage {
        
        let glContext = EAGLContext(api: .openGLES2)!
        let ciContext = CIContext(eaglContext: glContext, options: [kCIContextOutputColorSpace : NSNull()])
        let filter = CIFilter(name: "CIPhotoEffectMono")
        filter!.setValue(CIImage(image: self), forKey: "inputImage")
        let outputImage = filter!.outputImage
        let cgimg = ciContext.createCGImage(outputImage!, from: (outputImage?.extent)!)
        
        return UIImage(cgImage: cgimg!)
    }
    
    func scaleImage() -> UIImage {
        
        let maxDimension: CGFloat = 640
        var scaledSize = CGSize(width: maxDimension, height: maxDimension)
        var scaleFactor: CGFloat
        
        if self.size.width > self.size.height {
            scaleFactor = self.size.height / self.size.width
            scaledSize.width = maxDimension
            scaledSize.height = scaledSize.width * scaleFactor
        } else {
            scaleFactor = self.size.width / self.size.height
            scaledSize.height = maxDimension
            scaledSize.width = scaledSize.height * scaleFactor
        }
        
        UIGraphicsBeginImageContext(scaledSize)
        self.draw(in: CGRect(x: 0, y: 0, width: scaledSize.width, height: scaledSize.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }
    
    func orientate(img: UIImage) -> UIImage {
        
        if (img.imageOrientation == UIImageOrientation.up) {
            return img;
        }
        
        UIGraphicsBeginImageContextWithOptions(img.size, false, img.scale)
        let rect = CGRect(x: 0, y: 0, width: img.size.width, height: img.size.height)
        img.draw(in: rect)
        
        let normalizedImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return normalizedImage
        
    }
    
}
