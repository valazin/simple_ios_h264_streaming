//
//  CameraDetector.swift
//  simple_ios_h264_streaming
//
//  Created by valazin on 13/10/2019.
//  Copyright © 2019 valazin. All rights reserved.
//

import AVFoundation

class DeviceDetector {
    
    static func DetectCamera() -> AVCaptureDevice? {
        // TODO: ask permissions
        
        let _discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                                 mediaType: .video,
                                                                 position: .unspecified)
            
        let devices = _discoverySession.devices
        
        guard !devices.isEmpty else {
            return nil
        }
        
        return devices.first(where: { device in device.position == .back } )
    }
    
    static func DetectMicrophone() -> AVCaptureDevice? {
        // TODO: ask permissions
        
        let _discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInMicrophone],
                                                                 mediaType: .audio,
                                                                 position: .unspecified)
            
        let devices = _discoverySession.devices
        
        guard !devices.isEmpty else {
            return nil
        }
        
        return devices.first
    }
    
}
