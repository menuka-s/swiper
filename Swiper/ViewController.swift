//
//  ViewController.swift
//  Swiper
//
//  Created by Menuka Samaranayake on 7/20/15.
//  Copyright © 2015 Menuka Samaranayake. All rights reserved.
//

import UIKit
import AssetsLibrary


class ViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIScrollViewDelegate{
    
    @IBOutlet var scrollView: UIScrollView!
    
    let picker = UIImagePickerController()
    
    var myImageView: UIImageView!
    
    var galleryStatus: ALAuthorizationStatus = ALAssetsLibrary.authorizationStatus()

    
    // Opens Swiper settings in Settings
    @IBAction func goToSettings(sender: AnyObject) {
        let settingsUrl = NSURL(string: UIApplicationOpenSettingsURLString)
        UIApplication.sharedApplication().openURL(settingsUrl!)
    }
    
    // Button that opens built-in Photo Library to pick new picture
    @IBAction func photoFromLibrary(sender: UIBarButtonItem) {
        
        galleryStatus = ALAuthorizationStatus.Authorized // Hard coded this in since the authorization and basic app settings isn't working at the moment. Need to fix. I believe iOS 8.4.1 is the problem (8/19/15)
        
        // Check if Swiper has permission to access Photos
        if (galleryStatus == ALAuthorizationStatus.Authorized){
            picker.allowsEditing = false
            picker.sourceType = .PhotoLibrary
            presentViewController(picker, animated: true, completion: nil)
            self.navigationController?.hidesBarsOnTap = true
            self.navigationController?.setNavigationBarHidden(true, animated: true)
        }
        else {
            let galleryAlert = UIAlertController(title: "Permission denied", message: "Please give Swiper permission to access Photos in your settings app.", preferredStyle: UIAlertControllerStyle.Alert)
            galleryAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(galleryAlert, animated: true, completion: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // Sets up ViewController by setting up scrollView, swipe gestures, image picker and calling setZoomScale
    override func viewDidLoad() {
        super.viewDidLoad()
        
        picker.delegate = self
        self.navigationController?.hidesBarsOnTap = false
        
        // Swipe Gesture setup
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.handleSwipes(_:)))
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.handleSwipes(_:)))
        leftSwipe.direction = .Left
        rightSwipe.direction = .Right
        view.addGestureRecognizer(leftSwipe)
        view.addGestureRecognizer(rightSwipe)
        
        // Chooses initial picture. Need to change this since this causes myImageView to have the same bounds through all pictures
        myImageView = UIImageView(image: UIImage(named: "black-iphone4"))
        myImageView.contentMode = .ScaleAspectFit
        
        // scrollView setup
        scrollView.backgroundColor = UIColor.blackColor()
        scrollView.contentSize = myImageView.bounds.size
        scrollView.autoresizingMask = UIViewAutoresizing.FlexibleWidth.union(UIViewAutoresizing.FlexibleHeight)
        scrollView.addSubview(myImageView)
        view.addSubview(scrollView)
        
        scrollView.delegate = self
        setZoomScale()
        setupGestureRecognizer()
        
    }
    
    func image(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo:UnsafePointer<Void>) {
        if error == nil {
            let ac = UIAlertController(title: "Swiper No Swiping!", message: "Your face has been saved.", preferredStyle: .Alert)
            ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            presentViewController(ac, animated: true, completion: nil)
        } else {
            let ac = UIAlertController(title: "Save error", message: error?.localizedDescription, preferredStyle: .Alert)
            ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            presentViewController(ac, animated: true, completion: nil)
        }
    }
    
    // Replaces old myImageView with new chosen picture or picture from camera
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        // If the picture was taken with the camera then it will also save the picture
        if (picker.sourceType == UIImagePickerControllerSourceType.Camera) {
            let chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
            //myImageView.contentMode = .ScaleAspectFit
            myImageView.image = UIImage(CGImage: chosenImage.CGImage!, scale: 1.0, orientation: .LeftMirrored)
            var flippedToSaveImage = myImageView.image
            flippedToSaveImage = fixOrientation(flippedToSaveImage!)
            UIImageWriteToSavedPhotosAlbum(flippedToSaveImage!, self, #selector(ViewController.image(_:didFinishSavingWithError:contextInfo:)), nil)
            dismissViewControllerAnimated(true, completion: nil)

            setZoomScale()
        }
        else {
            let chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
            myImageView.contentMode = .ScaleAspectFit
            myImageView.image = chosenImage
            dismissViewControllerAnimated(true, completion: nil)
            setZoomScale()
        }
    }
    
    func fixOrientation(img:UIImage) -> UIImage {
        
        if (img.imageOrientation == UIImageOrientation.Up) {
            return img;
        }
        
        UIGraphicsBeginImageContextWithOptions(img.size, false, img.scale);
        let rect = CGRect(x: 0, y: 0, width: img.size.width, height: img.size.height)
        img.drawInRect(rect)
        
        let normalizedImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        return normalizedImage;
        
    }
    
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return myImageView
    }
    
    // Sets the minimum, maximum, and default zoom scales when viewing each picture
    func setZoomScale() {
        
        let imageViewSize = myImageView.bounds.size
        let scrollViewSize = scrollView.bounds.size
        let widthScale = scrollViewSize.width / imageViewSize.width
        let heightScale = scrollViewSize.height / imageViewSize.height
        
        scrollView.minimumZoomScale = min(widthScale, heightScale)
        scrollView.maximumZoomScale = 1.0
        scrollView.zoomScale = min(widthScale, heightScale)
    }
    
    override func viewWillLayoutSubviews() {
        setZoomScale()
    }
    
    

    
    // Allows scrollView to adjust picture when the device is rotated
    func scrollViewDidZoom(scrollView: UIScrollView) {
        let imageViewSize = myImageView.frame.size
        let scrollViewSize = scrollView.bounds.size
        
        let verticalPadding = imageViewSize.height < scrollViewSize.height ? (scrollViewSize.height - imageViewSize.height) / 2 : 0
        let horizontalPadding = imageViewSize.width < scrollViewSize.width ? (scrollViewSize.width - imageViewSize.width) / 2 : 0
        
        scrollView.contentInset = UIEdgeInsets(top: verticalPadding, left: horizontalPadding, bottom: verticalPadding, right: horizontalPadding)
    }
    
    // Sets up gesture recognizer for double taps and then calls method handleDoubleTap to handle double tap zooming in and out
    func setupGestureRecognizer() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }
    
    // Handles double tap zooming. Will hide or show Navigation Bars if zoomed in or out respectively
    func handleDoubleTap(recognizer: UITapGestureRecognizer) {
        
        if (scrollView.zoomScale > scrollView.minimumZoomScale) {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
            self.navigationController?.hidesBarsOnTap = true
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            
        } else {
            self.navigationController?.setNavigationBarHidden(true, animated: false)
            self.navigationController?.hidesBarsOnTap = false
            scrollView.setZoomScale(scrollView.maximumZoomScale, animated: true)
        }
    }
    
    // Handles right and left swipe gestures. If the picture is zoomed out to minimum and a swipe is registered, then shootPhoto is called
    func handleSwipes(sender:UISwipeGestureRecognizer) {
        if (scrollView.zoomScale <= scrollView.minimumZoomScale) {
            if (sender.direction == .Left) || (sender.direction == .Right) {
                shootPhoto()

            }
        }
    }
    
    // Shows a preview of what the front camera sees. After a 1 second delay a picture is taken with the camera and that becomes the new view
    func shootPhoto() {
        if UIImagePickerController.availableCaptureModesForCameraDevice(.Front) != nil {
            picker.sourceType = UIImagePickerControllerSourceType.Camera
            picker.cameraDevice = UIImagePickerControllerCameraDevice.Front
            
            let delay = 1.0 * Double(NSEC_PER_SEC)
        
            picker.showsCameraControls = false;
            
            // Finds size of device screen and scales camera accordingly
            
            let screenBounds: CGSize = UIScreen.mainScreen().bounds.size
            let cameraAspectRatio: CGFloat = 4.0/3.0
            let camViewHeight: CGFloat = screenBounds.width * cameraAspectRatio
            let scale: CGFloat = screenBounds.height/camViewHeight
            picker.cameraViewTransform = CGAffineTransformMakeTranslation(0, (screenBounds.height - camViewHeight) / 2.0)
            picker.cameraViewTransform = CGAffineTransformScale(picker.cameraViewTransform, scale, scale)

            
            presentViewController(picker, animated: true, completion:{
                let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
                dispatch_after(time, dispatch_get_main_queue()) {
                    self.picker.takePicture()
                }
            })
        }
        else {
            noCamera()
        }
    }
    
    // Check if there is no camera. Used for testing purposes
    func noCamera(){
        let alertVC = UIAlertController(title: "No Camera", message: "Please use device with a front camera", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style:.Default, handler: nil)
        alertVC.addAction(okAction)
        presentViewController(alertVC, animated: true, completion: nil)
    }
    


}

