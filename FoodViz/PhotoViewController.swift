//
//  PhotoViewController.swift
//  FoodViz
//
//  Created by Lukas Joswiak on 10/22/17.
//  Copyright © 2017 Lukas Joswiak. All rights reserved.
//

import UIKit

class PhotoViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    
    var photoTaken: UIImage?
    var rect: CGRect?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let availableImage = photoTaken {
            imageView.image = availableImage
            
            if let rectCoords = rect {
                let croppedImage2 = self.photoTaken?.cgImage
                let croppedImage3 = croppedImage2?.cropping(to: CGRect(x: rectCoords.minX, y: rectCoords.minY, width: rectCoords.width, height: rectCoords.height))
                let croppedImage = availableImage.crop(rect: CGRect(x: rectCoords.minX, y: rectCoords.minY, width: rectCoords.width, height: rectCoords.height))
                self.imageView.image = croppedImage
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
    func crop( rect: CGRect) -> UIImage {
        var rect = rect
        rect.origin.x*=self.scale
        rect.origin.y*=self.scale
        rect.size.width*=self.scale
        rect.size.height*=self.scale
        
        let imageRef = self.cgImage!.cropping(to: rect)
        let image = UIImage(cgImage: imageRef!, scale: self.scale, orientation: self.imageOrientation)
        return image
    }
    
    
}
