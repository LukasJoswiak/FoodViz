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
    
    @IBAction func closeButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
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
                    self.makeQuery(food: tesseract.recognizedText)
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
    
    func makeQuery(food: String) {
        let foood = food.replacingOccurrences(of: " ", with: "%20").replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "|", with: "").replacingOccurrences(of: "-", with: "")
        let temp = "https://api.cognitive.microsoft.com/bing/v7.0/images/search?q=" + foood
        let url = URL(string: temp)
        var request = URLRequest(url: url!)
        request.setValue("d22ae2acfcb64236be526d07be0ca7d4", forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            do {
                if let result = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any] {
                    let values = result["value"] as? [[String:Any]]
                    for index in 0...0 {
                        let firstResult = values?[index]
                        if let contentUrl = firstResult!["contentUrl"], let urlString = contentUrl as? String {
                            print(contentUrl)
                            let pic = URL(string : urlString)
                            let session = URLSession(configuration: .default)
                            let downloadPicTask = session.dataTask(with: pic!) { (data, response, error) in
                                // The download has finished.
                                if let e = error {
                                    print("Error downloading cat picture: \(e)")
                                } else {
                                    // No errors found.
                                    // It would be weird if we didn't have a response, so check for that too.
                                    if let res = response as? HTTPURLResponse {
                                        print("Downloaded cat picture with response code \(res.statusCode)")
                                        if let imageData = data {
                                            // Finally convert that Data into an image and do what you wish with it.
                                            let image = UIImage(data: imageData)!
                                            // Do something with your image.
                                            print("Assigning image")
                                            DispatchQueue.main.async {
                                                self.imageView.image = image
                                                print("Just assigned image")
                                            }
                                            
                                        } else {
                                            print("Couldn't get image: Image is nil")
                                        }
                                    } else {
                                        print("Couldn't get response code for some reason")
                                    }
                                }
                            }
                            downloadPicTask.resume()
                        }
                    }
                    
                } else { print("serialziation error") }
            } catch { print("network error") }
        }
        task.resume()
    }

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
