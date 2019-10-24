//
//  CameraFrameExtractor.swift
//  simple_ios_h264_streaming
//
//  Created by valazin on 12/10/2019.
//  Copyright © 2019 valazin. All rights reserved.
//

import AVFoundation

class CaptureSession {
    
    private let _captureSession = AVCaptureSession()
    private var _resolution = CGSize(width: 0, height: 0)
    
    func Start(camera: AVCaptureDevice,
               microphone: AVCaptureDevice,
               videoFrameHandler: AVCaptureVideoDataOutputSampleBufferDelegate,
               audioFrameHandler: AVCaptureAudioDataOutputSampleBufferDelegate) -> Bool {
        if _captureSession.isRunning {
            return false
        }
        
        // prepare video input
        do {
            let videoInput = try AVCaptureDeviceInput(device: camera)

            if _captureSession.canAddInput(videoInput) {
                print("Success add video Input")
                _captureSession.addInput(videoInput)
            } else {
                print("Couldn't add video Input")
                return false
            }
        } catch let error {
            print("Couldn't init AVCaptureDeviceInput with camera: \(error)")
            return false
        }

        // prepare video output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(videoFrameHandler, queue: DispatchQueue(label: "video frame handler queue"))

        if _captureSession.canAddOutput(videoOutput) {
            print("Success add video Output")
            _captureSession.addOutput(videoOutput)
        } else {
            print("Couldn't add video Output")
            return false
        }
        
        // prepare audio input
        do {
            let audioInput = try AVCaptureDeviceInput(device: microphone)
            
            if _captureSession.canAddInput(audioInput) {
                print("Success add audio Input")
                _captureSession.addInput(audioInput)
            } else {
                print("Couldn't add audio Input")
                return false
            }
        } catch let error {
            print("Couldn't init AVCaptureDeviceInput with microphone: \(error)")
            return false
        }
        
        // prepare audio output
        let audioOutput = AVCaptureAudioDataOutput()
        audioOutput.setSampleBufferDelegate(audioFrameHandler, queue: DispatchQueue(label: "audio frame handler queue"))
        
        if _captureSession.canAddOutput(audioOutput) {
            print("Success add audio Output")
            _captureSession.addOutput(audioOutput)
        } else {
            print("Couldn't add audio Output")
            return false
        }
        
        _captureSession.startRunning()
               
        return true
    }
        
}
