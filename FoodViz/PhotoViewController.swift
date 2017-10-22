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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let availableImage = photoTaken {
            imageView.image = availableImage
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
