import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController {

    let session = AVCaptureSession()
    lazy var previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
    let videoDataOutput = AVCaptureVideoDataOutput()
    var faceLayersArray: [CAShapeLayer] = []
    var point = CGPoint(x: 0, y: 0)
    
    @IBAction func shootButton(_ sender: Any) { createAndLaunchRocket() }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        setupCamera()
        session.startRunning()
    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        self.previewLayer.frame = self.view.frame
    }

    func setupCamera() {
        
        let camera = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front)
        if let device = camera.devices.first {
            if let cameraInput = try? AVCaptureDeviceInput(device: device) {
                if session.canAddInput(cameraInput) {
                    session.addInput(cameraInput)
                    setupPreview()
                }
            }
        }
    }
    
    func setupPreview() {
        
        self.previewLayer.videoGravity = .resizeAspectFill
        self.view.layer.addSublayer(self.previewLayer)
        self.previewLayer.frame = self.view.frame
        
        self.videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]

        self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera queue"))
        self.session.addOutput(self.videoDataOutput)
        
        let videoConnection = self.videoDataOutput.connection(with: .video)
        videoConnection?.videoOrientation = .portrait
    }
    
    func createAndLaunchRocket() {
        
        let rocketImageView = createRocket()
        let boom = showBoom(x: point.x, y: point.y)
        let boom2 = showBoom(x: point.x - 20, y: point.y - 20)
        
        UIView.animate(withDuration: 1.0, delay: 0, options: .curveEaseIn, animations: {
            rocketImageView.frame.origin = CGPoint(x: self.point.x, y: self.point.y)
        }) { (_) in
            rocketImageView.alpha = 0
            UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseIn, animations: {
                boom.alpha = 1
                boom.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }) { (_) in
                UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseIn, animations: {
                    boom.alpha = 0
                    boom.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
                }) { (_) in
                }
            }
            UIView.animate(withDuration: 0.4, delay: 0.1, options: .curveEaseIn, animations: {
                boom2.alpha = 1
                boom2.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }) { (_) in
                UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseIn, animations: {
                    boom2.alpha = 0
                    boom2.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
                }) { (_) in
                }
            }
        }
    }
    
    func createRocket() -> UIImageView {
        
        let rocketImage = UIImage(named: "rocket.png")
        let rocketImageView = UIImageView(frame: CGRect(x: view.frame.size.width / 2 - 18, y: view.frame.size.height, width: 37, height: 73))
        rocketImageView.image = rocketImage
        view.addSubview(rocketImageView)
        return rocketImageView
    }
    
    func showBoom(x: CGFloat, y: CGFloat) -> UIImageView {
        
        let boomImage = UIImage(named: "boom.png")
        let boomImageView = UIImageView(frame: CGRect(x: x, y: y, width: 80, height: 78))
        boomImageView.image = boomImage
        view.addSubview(boomImageView)
        boomImageView.alpha = 0
        return boomImageView
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: { (request: VNRequest, error: Error?) in
            DispatchQueue.main.async {
                self.faceLayersArray.forEach({ drawing in drawing.removeFromSuperlayer() })
                if let results = request.results as? [VNFaceObservation] {
                    self.handleFaceDetectionObservations(results: results)
                }
            }
        })

        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: imageBuffer, orientation: .leftMirrored, options: [:])

        do {
            try imageRequestHandler.perform([faceDetectionRequest])
        } catch {
          print(error.localizedDescription)
        }
    }
    
    func handleFaceDetectionObservations(results: [VNFaceObservation]) {
        
        for result in results {
            let faceRectConverted = self.previewLayer.layerRectConverted(fromMetadataOutputRect: result.boundingBox)
            let faceRectanglePath = CGPath(rect: faceRectConverted, transform: nil)
            
            let faceLayer = CAShapeLayer()
            faceLayer.path = faceRectanglePath
            faceLayer.fillColor = UIColor.clear.cgColor
            faceLayer.strokeColor = UIColor.yellow.cgColor
            
            self.faceLayersArray.append(faceLayer)
            self.view.layer.addSublayer(faceLayer)
            
            point = result.boundingBox.origin
        }
    }
}

