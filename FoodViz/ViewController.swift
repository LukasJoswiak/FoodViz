//
//  ViewController.swift
//  FoodViz
//
//  Created by Lukas Joswiak on 10/21/17.
//  Copyright © 2017 Lukas Joswiak. All rights reserved.
//

import UIKit
import AVFoundation
import Vision
// import URLSessions
import TesseractOCR

class ViewController: UIViewController, G8TesseractDelegate {
    
    // MARK: Properties
    @IBOutlet weak var imageView: UIImageView!
    
    var session = AVCaptureSession()
    var cameraOutput = AVCapturePhotoOutput()
    var requests = [VNRequest]()
    var currentBoxes = [CGRect]()
    
    var takePhoto: CGRect?
    
    var foodImage = UIImage()
    var rect: CGRect?
    
    
    //let tesseract: G8Tesseract = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*
        if let tesseract = G8Tesseract(language: "eng") {
            tesseract.delegate = self
            tesseract.image = UIImage(named: "testImage")?.g8_blackAndWhite()
            tesseract.recognize()
            
            print("Recognized text: \(tesseract.recognizedText)")
        }
         */
    }
    
    override func viewWillAppear(_ animated: Bool) {
        startLiveVideo()
        startTextDetection()
    }
    
    override func viewDidLayoutSubviews() {
        imageView.layer.sublayers?[0].frame = imageView.bounds
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Gesture Recognizer

    @IBAction func panGestureAction(_ sender: UIPanGestureRecognizer) {
        let view = sender.view
        let locationInView = sender.location(in: view)
        if sender.state == .began || sender.state == .changed {
            // get distance moved
            let currentX = locationInView.x
            let currentY = locationInView.y
            let currentPoint = CGPoint(x: currentX, y: currentY)
            
            for highlightedWord in self.currentBoxes {
                if highlightedWord.contains(currentPoint) {
                    if let tesseract = G8Tesseract(language: "eng") {
                        captureImage(highlightedWord)
                        
                        print("CAPTURED IMAGE")
                        tesseract.delegate = self
                        let image = UIImage(named: "testImage")?.g8_blackAndWhite()
                        tesseract.image = image
                        //tesseract.rect = highlightedWord
                        tesseract.recognize()
                        
                        print("Recognized text: \(tesseract.recognizedText)")
                    }
                }
            }
            
        }
    }
    
    // MARK: Text Recognition
    
    func progressImageRecognition(for tesseract: G8Tesseract!) {
        print("Recognition progress: \(tesseract.progress) %")
    }

    // MARK: Video Capture
    var isInitialized = false
    func startLiveVideo() {
        session.sessionPreset = AVCaptureSession.Preset.photo
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        
        let deviceInput = try! AVCaptureDeviceInput(device: captureDevice!)
        let deviceOutput = AVCaptureVideoDataOutput()
        deviceOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        deviceOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
        
        session.addInput(deviceInput)
        session.addOutput(deviceOutput)
        
        let imageLayer = AVCaptureVideoPreviewLayer(session: session)
        imageLayer.frame = imageView.bounds
        imageView.layer.addSublayer(imageLayer)
        
        session.startRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let rect = takePhoto {
            takePhoto = nil
            
            if let image = self.getImageFromSampleBuffer(buffer: sampleBuffer) {
                print("got image")
                //let croppedImage = image.crop(rect: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height))
                //self.stopCaptureSession()
                
                self.foodImage = image
                self.rect = rect
                
//                DispatchQueue.main.async {
                    self.session.stopRunning()
                    self.performSegue(withIdentifier: "Food", sender: self)
                    
//                }
            }
        }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        var requestOptions: [VNImageOption : Any] = [:]
        
        if let camData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics:camData]
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation(rawValue: 6)!, options: requestOptions)
        
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let nextVC = segue.destination as? PhotoViewController else { return }
        //if let nextVC = navVC.viewControllers[0] as? PhotoViewController {
        nextVC.photoTaken = self.foodImage
        nextVC.rect = self.rect
        //}
    }
    
    func getImageFromSampleBuffer (buffer: CMSampleBuffer) -> UIImage? {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) {
            var ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            ciImage = ciImage.transformed(by: ciImage.orientationTransform(forExifOrientation: 6))
            print("set image")
            let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
            
            if let image = context.createCGImage(ciImage, from: imageRect) {
                return UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: .right)
            }
            
        }
        
        return nil
    }
    
    func stopCaptureSession () {
        self.session.stopRunning()
        
        if let inputs = session.inputs as? [AVCaptureDeviceInput] {
            for input in inputs {
                self.session.removeInput(input)
            }
        }
        
    }

    /*
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: NSError?) {
        print("captured image")
        if let error = error {
            print("error: \(error)")
        }
        
        /*
        if let sampleBuffer = photoSampleBuffer, let previewBuffer = previewPhotoSampleBuffer, let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
            print("image: \(UIImage(data: dataImage)?.size)") // Your Image
        }
         */
    }
     */
    
    func captureImage(_ rect: CGRect) {
        takePhoto = rect
        print("capturing image")
        /*
        //session.stopRunning()
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.__availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                             kCVPixelBufferWidthKey as String: 160,
                             kCVPixelBufferHeightKey as String: 160]
        settings.previewPhotoFormat = previewFormat
        self.cameraOutput.capturePhoto(with: settings, delegate: self)
         */
    }
    
    // MARK: Text Detection
    
    func startTextDetection() {
        let textRequest = VNDetectTextRectanglesRequest(completionHandler: self.detectTextHandler)
        textRequest.reportCharacterBoxes = true
        self.requests = [textRequest]
    }
    
    func detectTextHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results else {
            print("no result")
            return
        }
        
        let result = observations.map({$0 as? VNTextObservation })
        
        DispatchQueue.main.async() {
            // empty out array of current boxes
            self.currentBoxes.removeAll(keepingCapacity: true)
            self.imageView.layer.sublayers?.removeSubrange(1...)
            for region in result {
                guard let rg = region else {
                    continue
                }
                
                self.highlightWord(box: rg)
                
                if let boxes = region?.characterBoxes {
                    for characterBox in boxes {
                        self.highlightLetters(box: characterBox)
                    }
                }
            }
        }
    }
    
    func highlightWord(box: VNTextObservation) {
        guard let boxes = box.characterBoxes else {
            return
        }
        var maxX: CGFloat = 9999.0
        var minX: CGFloat = 0.0
        var maxY: CGFloat = 9999.0
        var minY: CGFloat = 0.0
        
        for char in boxes {
            if char.bottomLeft.x < maxX {
                maxX = char.bottomLeft.x
            }
            if char.bottomRight.x > minX {
                minX = char.bottomRight.x
            }
            if char.bottomRight.y < maxY {
                maxY = char.bottomRight.y
            }
            if char.topRight.y > minY {
                minY = char.topRight.y
            }
        }
        
        let xCoord = maxX * imageView.frame.size.width
        let yCoord = (1 - minY) * imageView.frame.size.height
        let width = (minX - maxX) * imageView.frame.size.width + 5
        let height = (minY - maxY) * imageView.frame.size.height + 5
        
        let outline = CALayer()
        let rect = CGRect(x: xCoord, y: yCoord, width: width, height: height)
        outline.frame = rect
        outline.borderWidth = 2.0
        outline.borderColor = UIColor.red.cgColor
        
        imageView.layer.addSublayer(outline)
        
        // add frame to currentBoxes
        self.currentBoxes.append(rect)
    }
    
    func highlightLetters(box: VNRectangleObservation) {
        let xCord = box.topLeft.x * imageView.frame.size.width
        let yCord = (1 - box.topLeft.y) * imageView.frame.size.height
        let width = (box.topRight.x - box.bottomLeft.x) * imageView.frame.size.width
        let height = (box.topLeft.y - box.bottomLeft.y) * imageView.frame.size.height
        
        let outline = CALayer()
        outline.frame = CGRect(x: xCord, y: yCord, width: width, height: height)
        outline.borderWidth = 1.0
        outline.borderColor = UIColor.blue.cgColor
        
        imageView.layer.addSublayer(outline)
    }
    
    // MARK: Search API Calls
    
    func sendQuery() {
        let query = "CheeseBurger"
        
        let temp = "https://api.cognitive.microsoft.com/bing/v7.0/images/search?q=" + query
        
        let url = URL(string: "https://api.cognitive.microsoft.com/bing/v7.0/images/search?q=CheeseBurger")
        
        let task = URLSession.shared.dataTask(with: url!) {(data, response, error) in
            print(NSString(data: data!, encoding: String.Encoding.utf8.rawValue))
        }
        
        task.resume()
        
//        let src = task.resume().value.contentUrl
//
//        print(src)
    }
    
    

}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
}

extension ViewController: AVCapturePhotoCaptureDelegate {
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: NSError?) {
        print("captured image")
        if let error = error {
            print("error: \(error)")
        }
        
        /*
         if let sampleBuffer = photoSampleBuffer, let previewBuffer = previewPhotoSampleBuffer, let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
         print("image: \(UIImage(data: dataImage)?.size)") // Your Image
         }
         */
    }
}


