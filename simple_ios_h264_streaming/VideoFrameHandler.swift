//
//  VideoFrameHandler.swift
//  simple_ios_h264_streaming
//
//  Created by valazin on 13/10/2019.
//  Copyright © 2019 valazin. All rights reserved.
//

import AVFoundation
import VideoToolbox

class VideoFrameHandler : NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        
    init (resolution: CGSize, sender: OpaquePointer) {
        super.init()
        
        VTCompressionSessionCreate(allocator: nil,
                                   width: Int32(resolution.width),
                                   height: Int32(resolution.height),
                                   codecType: kCMVideoCodecType_H264,
                                   encoderSpecification: nil,
                                   imageBufferAttributes: nil,
                                   compressedDataAllocator: nil,
                                   outputCallback: _compressionCallback,
                                   refcon: UnsafeMutableRawPointer(sender),
                                   compressionSessionOut: &_comperessionSession)
        
        VTCompressionSessionCreate(allocator: nil,
                                   width: Int32(640),
                                   height: Int32(480),
                                   codecType: kCMVideoCodecType_H264,
                                   encoderSpecification: nil,
                                   imageBufferAttributes: nil,
                                   compressedDataAllocator: nil,
                                   outputCallback: _compressionCallback,
                                   refcon: UnsafeMutableRawPointer(sender),
                                   compressionSessionOut: &_comperessionSession2)
        
        _currentComperssionSession = _comperessionSession
    }
    
    func changeEncoder(id: Int) {
        if (id == 0) {
            _currentComperssionSession = _comperessionSession;
        } else {
            _currentComperssionSession = _comperessionSession2;
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("Frame was droped")
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let session = _currentComperssionSession else {
            return print("Session was not created")
        }
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return print("Couldn't get image buffer")
        }
        
        var flags: VTEncodeInfoFlags = []
        VTCompressionSessionEncodeFrame(session,
                                        imageBuffer: imageBuffer,
                                        presentationTimeStamp: CMSampleBufferGetPresentationTimeStamp(sampleBuffer),
                                        duration: CMSampleBufferGetDuration(sampleBuffer),
                                        frameProperties: nil,
                                        sourceFrameRefcon: nil,
                                        infoFlagsOut: &flags)
    }
    
    private var _compressionCallback: VTCompressionOutputCallback = {(
        outputCallbackRefCon: UnsafeMutableRawPointer?,
        sourceFrameRefCon: UnsafeMutableRawPointer?,
        status: OSStatus,
        infoFlags: VTEncodeInfoFlags,
        sampleBuffer: CMSampleBuffer?) in
        
        // TODO: check status
        
        guard let sampleBuffer = sampleBuffer else {
            return print("sampleBuffer is null")
        }
        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
            return print("dataBuffer is null")
        }
        
        var inputDataLength = 0
        var inputData: UnsafeMutablePointer<Int8>?
        CMBlockBufferGetDataPointer(blockBuffer,
                                    atOffset: 0,
                                    lengthAtOffsetOut: nil,
                                    totalLengthOut: &inputDataLength,
                                    dataPointerOut: &inputData)
        if (inputData == nil || inputDataLength <= 0) {
            return print("Couldn't get dataPointer from CMBlockBufferGetDataPointer")
        }
        
        var outputDataOffset = 0
        var outputDataLength = inputDataLength
        var outputData: UnsafeMutablePointer<Int8>?
        
        let isKeyFrame = calcIsKeyFrame(data: sampleBuffer)
        if isKeyFrame == 1 {
            let parametersLength = calcSpsAndPpsParametersLength(data: sampleBuffer)
            if parametersLength > 0 {
                outputDataLength += parametersLength
                outputData = UnsafeMutablePointer<Int8>.allocate(capacity: outputDataLength)
                
                copySpsAndPpsParameters(src: sampleBuffer, dst: outputData!)
                outputDataOffset += parametersLength
            }
        }
        
        if outputData == nil {
            outputData = UnsafeMutablePointer<Int8>.allocate(capacity: outputDataLength)
        }
        
        memcpy(outputData! + outputDataOffset, inputData!, inputDataLength)
        rewriteAvvcToAnnexB(data: outputData! + outputDataOffset, length: outputDataLength - outputDataOffset)
        
        var frameInfo = FrameContext()
        frameInfo.dts = Int64(Float(CMSampleBufferGetDecodeTimeStamp(sampleBuffer).value * 1000) / Float(CMSampleBufferGetDecodeTimeStamp(sampleBuffer).timescale))
        frameInfo.pts = Int64(Float(CMSampleBufferGetPresentationTimeStamp(sampleBuffer).value * 1000) / Float(CMSampleBufferGetPresentationTimeStamp(sampleBuffer).timescale))
        frameInfo.isKeyFrame = isKeyFrame > 0 ? 1 : 0
        frameInfo.isVideoFrame = 1
        
        sender_send_frame(OpaquePointer(outputCallbackRefCon),
                          outputData,
                          Int64(outputDataLength),
                          frameInfo)
    }
    
    private static func calcIsKeyFrame(data: CMSampleBuffer) -> Int {
        var res = 0
        
        let attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(data, createIfNecessary: false)
        if let array = attachmentsArray {
            if CFArrayGetCount(array) > 0 {
                let dict = Unmanaged<CFDictionary>.fromOpaque(CFArrayGetValueAtIndex(array, 0)).takeUnretainedValue()
                let key = Unmanaged.passUnretained(kCMSampleAttachmentKey_NotSync).toOpaque()
                var value: UnsafeRawPointer?

                let keyExists = CFDictionaryGetValueIfPresent(dict, key, &value)
                if keyExists && value != nil {
                    let isNotSync = Unmanaged<CFBoolean>.fromOpaque(value!).takeUnretainedValue()
                    res = CFBooleanGetValue(isNotSync) == false ? 1 : 0
                } else {
                    res = 1
                }
            }
        }
        
        return res
    }
    
    private static func calcSpsAndPpsParametersLength(data: CMSampleBuffer) -> Int {
        guard let description = CMSampleBufferGetFormatDescription(data) else {
            return 0
        }
        
        let annexBHeaderLength = 4
        
        var parametersNumber: Int = 0
        CMVideoFormatDescriptionGetH264ParameterSetAtIndex(description,
                                                           parameterSetIndex: 0,
                                                           parameterSetPointerOut: nil,
                                                           parameterSetSizeOut: nil,
                                                           parameterSetCountOut: &parametersNumber,
                                                           nalUnitHeaderLengthOut: nil)
        
        var res = 0
        // TODO: must start from 1?
        for index in 0...parametersNumber {
            var size: Int = 0
            CMVideoFormatDescriptionGetH264ParameterSetAtIndex(description,
                                                               parameterSetIndex: index,
                                                               parameterSetPointerOut: nil,
                                                               parameterSetSizeOut: &size,
                                                               parameterSetCountOut: nil,
                                                               nalUnitHeaderLengthOut: nil)
            res += size + annexBHeaderLength
        }
        
        return res
    }
    
    private static func copySpsAndPpsParameters(src: CMSampleBuffer, dst: UnsafeMutablePointer<Int8>) {
        guard let description = CMSampleBufferGetFormatDescription(src) else {
            return
        }
        
        let annexBHeader: [UInt8] = [0,0,0,1]
        let annexBHeaderLength = annexBHeader.count
        
        var parametersNumber: Int = 0
        CMVideoFormatDescriptionGetH264ParameterSetAtIndex(description,
                                                           parameterSetIndex: 0,
                                                           parameterSetPointerOut: nil,
                                                           parameterSetSizeOut: nil,
                                                           parameterSetCountOut: &parametersNumber,
                                                           nalUnitHeaderLengthOut: nil)
        
        var offset = 0
        for index in 0...parametersNumber {
            var pointer: UnsafePointer<UInt8>?
            var size: Int = 0
            CMVideoFormatDescriptionGetH264ParameterSetAtIndex(description,
                                                               parameterSetIndex: index,
                                                               parameterSetPointerOut: &pointer,
                                                               parameterSetSizeOut: &size,
                                                               parameterSetCountOut: nil,
                                                               nalUnitHeaderLengthOut: nil)
            memcpy(dst + offset, annexBHeader, annexBHeaderLength)
            offset += annexBHeaderLength
            
            memcpy(dst + offset, pointer, size)
            offset += size
        }
    }
    
    private static func rewriteAvvcToAnnexB(data: UnsafeMutablePointer<Int8>, length: Int) {
        let annexBHeader: [UInt8] = [0,0,0,1]
        let headerLength = annexBHeader.count
        
        var offset = 0
        while offset < length - headerLength {
            var h264PacketLength: UInt32 = 0
            memcpy(&h264PacketLength, data + offset, headerLength)
            h264PacketLength = CFSwapInt32BigToHost(h264PacketLength)
            
            memcpy(data + offset, annexBHeader, headerLength)
            offset += headerLength + Int(h264PacketLength)
        }
    }
    
    private var _currentComperssionSession: VTCompressionSession?
    private var _comperessionSession: VTCompressionSession?
    private var _comperessionSession2: VTCompressionSession?
}
