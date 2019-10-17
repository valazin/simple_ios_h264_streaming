//
//  CameraDetector.swift
//  cameraphone_new_protocol
//
//  Created by Develop on 13/10/2019.
//  Copyright © 2019 Develop. All rights reserved.
//

import AVFoundation

class CameraDetector {
    
    private let _discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInTrueDepthCamera, .builtInDualCamera],
                                                                     mediaType: .video,
                                                                     position: .unspecified)
        
    func Detect() -> AVCaptureDevice?
    {
        // TODO: ask permissions
            
        let devices = _discoverySession.devices
        
        guard !devices.isEmpty else {
            return nil
        }
        
        return devices.first(where: { device in device.position == .back } )
    }
    
}
