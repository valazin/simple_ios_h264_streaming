//
//  ViewController.swift
//  simple_ios_h264_streaming
//
//  Created by valazin on 16/10/2019.
//  Copyright © 2019 valazin. All rights reserved.
//


import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    private let _captureSession = CaptureSession()
    private var _videoFrameHandler: VideoFrameHandler? = nil
    private var _audioFrameHandler: AudioFrameHandler? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
                
        guard let camera = DeviceDetector.DetectCamera() else {
            return print("Not found any cameras")
        }

        let dimensions = CMVideoFormatDescriptionGetDimensions(camera.activeFormat.formatDescription)
        let resolution = CGSize(width:  CGFloat(dimensions.width)/1,
                                height: CGFloat(dimensions.height)/1)
        
        print("Found camera with position=\(camera.position.rawValue), type=\(camera.deviceType), resolution=\(resolution)")
        
        guard let microphone  = DeviceDetector.DetectMicrophone() else {
            return print("Not found any microphones")
        }
        
        guard let sender: OpaquePointer = sender_create("10.110.3.43", 4444, 5) else {
            return print("Couldn't create sender")
        }
        
//        guard let sender: OpaquePointer = sender_create("videos-p2p-storage.dev.avalab.io", 4444, 5) else {
//            return print("Couldn't create sender")
//        }
        
//        guard let sender: OpaquePointer = sender_create("192.168.88.253", 4444, 5) else {
//            return print("Couldn't create sender")
//        }
        
        var videoContext = VideoContext();
        videoContext.frameHeight = Int32(Int(resolution.width))
        videoContext.frameWidth = Int32(Int(resolution.height))
        videoContext.timebase.den = 1000
        videoContext.timebase.num = 1
        
        // TODO: init with appropriate data
        var audioContext = AudioContext()
        audioContext.channelsCount = 1
        audioContext.sampleRate = 44100
        audioContext.timebase.den = 1000
        audioContext.timebase.num = 1
        
        let isConnected = sender_connect(sender,
                                         "77b207b2-f6da-460b-9ae7-b0a6c5d2020f",
                                         videoContext,
                                         audioContext,
                                         3)
        
        guard isConnected > 0 else {
            sender_destroy(sender)
            return print("Couldn't connect")
        }
        
        // Keep from release
        _videoFrameHandler = VideoFrameHandler(resolution: resolution, sender: sender)
        _audioFrameHandler = AudioFrameHandler(sender: sender)
        
        guard let videoFrameHandler = _videoFrameHandler, let audioFrameHandler = _audioFrameHandler else {
            return
        }
        
        if _captureSession.Start(camera: camera,
                                 microphone: microphone,
                                 videoFrameHandler: videoFrameHandler,
                                 audioFrameHandler: audioFrameHandler) {
            print("Sucess start CaptureSession")
        } else {
            sender_destroy(sender)
            print("Couldn't start CaptureSession")
        }
    }

}

