//
//  ViewController.swift
//  simple_ios_h264_streaming
//
//  Created by Develop on 16/10/2019.
//  Copyright © 2019 Develop. All rights reserved.
//


import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    private let _frameExtractor = CameraFrameExtractor()
    private var _frameHandler: CameraFrameHandler? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cameraDetector = CameraDetector()
        guard let camera = cameraDetector.Detect() else {
            return print("Not found any cameras")
        }

        let dimensions = CMVideoFormatDescriptionGetDimensions(camera.activeFormat.formatDescription)
        let resolution = CGSize(width:  CGFloat(dimensions.width)/2,
                                height: CGFloat(dimensions.height)/2)
        
        print("Found camera with position=\(camera.position.rawValue), type=\(camera.deviceType), resolution=\(resolution)")
        
        guard let sender: OpaquePointer = sender_create("192.168.88.253", 4444, 5) else {
            return print("Couldn't create sender")
        }
        
//        guard let sender: OpaquePointer = sender_create("videos-p2p-storage.dev.avalab.io", 4444, 5) else {
//            return print("Couldn't create sender")
//        }
        
        var videoContext = VideoContext();
        videoContext.frameHeight = Int32(Int(resolution.width))
        videoContext.frameWidth = Int32(Int(resolution.height))
        videoContext.timebase.den = 1000
        videoContext.timebase.num = 1
        
        var audioContext = AudioContext()
        audioContext.channelsCount = 0
        audioContext.sampleRate = 0
        audioContext.timebase.num = 0
        audioContext.timebase.den = 0
        
        let isConnected = sender_connect(sender,
                                         "77b207b2-f6da-460b-9ae7-b0a6c5d2020f",
                                         videoContext,
                                         audioContext,
                                         3)
        
        guard isConnected > 0 else {
            sender_destroy(sender)
            return print("Couldn't connect")
        }
        
        let frameHandler = CameraFrameHandler(resolution: resolution, sender: sender)
        // Keep from release
        _frameHandler = frameHandler
        
        if _frameExtractor.Start(device: camera, frameHandler: frameHandler) {
            print("Sucess start CameraFrameExtractor")
        } else {
            sender_destroy(sender)
            print("Couldn't start CameraFrameExtractor")
        }
    }

}

