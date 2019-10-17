//
//  CameraFrameExtractor.swift
//  cameraphone_new_protocol
//
//  Created by Develop on 12/10/2019.
//  Copyright © 2019 Develop. All rights reserved.
//

import AVFoundation

class CameraFrameExtractor {
    
    private let _captureSession = AVCaptureSession()
    private var _resolution = CGSize(width: 0, height: 0)
    
    func Start(device: AVCaptureDevice, frameHandler: AVCaptureVideoDataOutputSampleBufferDelegate) -> Bool {
        if _captureSession.isRunning {
            return false
        }
        
        // prepare input
        do {
            let input = try AVCaptureDeviceInput(device: device)
            
            if _captureSession.canAddInput(input) {
                print("Success add Input")
                _captureSession.addInput(input)
            } else {
                print("Couldn't add Input")
                return false
            }
        } catch let error {
            print("Couldn't init AVCaptureDeviceInput: \(error)")
            return false
        }
        
        // prepare output
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(frameHandler, queue: DispatchQueue(label: "frame handler queue"))
        
        if _captureSession.canAddOutput(output) {
            print("Success add Output")
            _captureSession.addOutput(output)
        } else {
            print("Couldn't add Output")
            return false
        }
        
        _captureSession.startRunning()
               
        return true
    }
        
}
