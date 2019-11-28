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
    
    @IBAction func onClicked(_ sender: Any) {
        if (_currentEncoderId == 0) {
            _currentEncoderId = 1
        } else {
            _currentEncoderId = 0
        }
        print("change encoder to \(_currentEncoderId)")
        _videoFrameHandler?.changeEncoder(id: _currentEncoderId)
    }
    
    private let _captureSession = CaptureSession()
    private var _videoFrameHandler: VideoFrameHandler? = nil
    private var _audioFrameHandler: AudioFrameHandler? = nil
    private var _currentEncoderId = 0

    override func viewDidLoad() {
        UIApplication.shared.isIdleTimerDisabled = true
        
        super.viewDidLoad()
                
        guard let camera = DeviceDetector.DetectCamera() else {
            return print("Not found any cameras")
        }

        let dimensions = CMVideoFormatDescriptionGetDimensions(camera.activeFormat.formatDescription)
        let resolution = CGSize(width:  CGFloat(1280),
                                height: CGFloat(720))
        
        print("Found camera with position=\(camera.position.rawValue), type=\(camera.deviceType), resolution=\(resolution)")
        
        guard let microphone  = DeviceDetector.DetectMicrophone() else {
            return print("Not found any microphones")
        }
        
        guard let sender: OpaquePointer = sender_create("10.110.3.43", 4444) else {
            return print("Couldn't create sender")
        }

//        guard let sender: OpaquePointer = sender_create("192.168.88.253", 4444, 5) else {
//            return print("Couldn't create sender")
//        }
        
        var videoContext = VideoContext();
        videoContext.frameHeight = Int32(Int(resolution.width))
        videoContext.frameWidth = Int32(Int(resolution.height))
        videoContext.timebase.den = 1000
        videoContext.timebase.num = 1
        
        var audioContext = AudioContext()
        // TODO: get channels count from device
        audioContext.channelsCount = 1
        // TODO: get sample rate from device
        audioContext.sampleRate = 44100
        audioContext.timebase.den = 1000
        audioContext.timebase.num = 1
        
        let isConnected = sender_connect(sender,"a017f497-cebe-492a-8c0b-60e89a61901c",
                                         videoContext,
                                         audioContext)
        
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
