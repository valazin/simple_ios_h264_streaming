//
//  AudioFrameHandler.swift
//  simple_ios_h264_streaming
//
//  Created by valazin on 17/10/2019.
//  Copyright © 2019 valazin. All rights reserved.
//

import AVFoundation
import AudioToolbox

class AudioFrameHandler : NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    init(sender: OpaquePointer) {
        _sender = sender

        super.init()
    }
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if _converter == nil {
            guard let inFormatDescription = sampleBuffer.formatDescription else {
                return
            }
            guard var inBasicStreamDescription = CMAudioFormatDescriptionGetStreamBasicDescription(inFormatDescription)?.pointee else {
                return
            }
            
            _inSampleRate = inBasicStreamDescription.mSampleRate
            _inChannelsCount = inBasicStreamDescription.mChannelsPerFrame
            _converter = AudioFrameHandler.newConverter(inBasicStreamDescription: inBasicStreamDescription)
        }
        
        guard let converter = _converter else {
            return
        }
        
        // Save input data to _inBufferList
        // We use _inBufferList later in _inputDataProc
        var blockBuffer: CMBlockBuffer?
        var res = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer,
                                                                          bufferListSizeNeededOut: nil,
                                                                          bufferListOut: _inBufferList.unsafeMutablePointer,
                                                                          bufferListSize: _inBufferListSize,
                                                                          blockBufferAllocator: kCFAllocatorDefault,
                                                                          blockBufferMemoryAllocator: kCFAllocatorDefault,
                                                                          flags: 0,
                                                                          blockBufferOut: &blockBuffer)
        if res != 0 || blockBuffer == nil {
            return print("CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer returned with res=\(res)")
        }
        
        // Prepare output buffers for encoded data
        var outPacketsNumber: UInt32 = 1
        var outPacketSize: UInt32 {
            var res = UInt32(0)
            var size = UInt32(MemoryLayout.size(ofValue: res))
            AudioConverterGetProperty(converter,
                                      kAudioConverterPropertyMaximumOutputPacketSize,
                                      &size,
                                      &res)
            return res
        }
        let outBufferList = AudioBufferList.allocate(maximumBuffers: Int(outPacketsNumber))
        for i in 0..<Int(outPacketsNumber) {
            outBufferList[i].mNumberChannels = _inChannelsCount
            outBufferList[i].mDataByteSize = outPacketSize
            outBufferList[i].mData = UnsafeMutableRawPointer.allocate(byteCount: Int(outPacketSize), alignment: 0)
        }
        
        // Converting.
        // This method blocks thread and call _inputDataProc.
        res = AudioConverterFillComplexBuffer(converter,
                                              self._inputDataProc,
                                              Unmanaged.passUnretained(self).toOpaque(),
                                              &outPacketsNumber,
                                              outBufferList.unsafeMutablePointer,
                                              nil)
        if res != 0 {
            for i in 0..<Int(outPacketsNumber) {
                free(outBufferList[i].mData)
            }
            free(outBufferList.unsafeMutablePointer)
            return print("AudioConverterFillComplexBuffer returned with res=\(res)")
        }
        
        // Send
        var frameInfo = FrameContext()
        frameInfo.pts = Int(Float(sampleBuffer.presentationTimeStamp.value * 1000) / Float(sampleBuffer.presentationTimeStamp.timescale))
        frameInfo.dts = frameInfo.pts
        frameInfo.isKeyFrame = 0
        frameInfo.isVideoFrame = 0
        for i in 0..<Int(outPacketsNumber) {
            let aacDataSize = outBufferList[i].mDataByteSize
            guard let aacData = outBufferList[i].mData else {
                continue
            }
            
            sender_send_frame(_sender,
                              UnsafeMutablePointer<Int8>(OpaquePointer(aacData)),
                              Int(aacDataSize),
                              frameInfo)
        }
    }
    
    // This delegate is called by AudioToolbox. See AudioConverterFillComplexBuffer
    private let _inputDataProc: AudioConverterComplexInputDataProc = {(
        converter: AudioConverterRef,
        ioNumberDataPackets: UnsafeMutablePointer<UInt32>,
        ioData: UnsafeMutablePointer<AudioBufferList>,
        outDataPacketDescription: UnsafeMutablePointer<UnsafeMutablePointer<AudioStreamPacketDescription>?>?,
        inUserData: UnsafeMutableRawPointer?) -> OSStatus in
        
        let this = Unmanaged<AudioFrameHandler>.fromOpaque(inUserData!).takeUnretainedValue()
        memcpy(ioData, this._inBufferList.unsafePointer, this._inBufferListSize)
        ioNumberDataPackets.pointee = 1
        
        return noErr
    }
    
    
    private static func newConverter(inBasicStreamDescription: AudioStreamBasicDescription) -> AudioConverterRef? {
        var outAudioClassDescription = [AudioClassDescription]()
        for _ in 1...inBasicStreamDescription.mChannelsPerFrame {
            outAudioClassDescription.append(AudioClassDescription(mType: kAudioEncoderComponentType,
                                                                  mSubType: kAudioFormatMPEG4AAC,
                                                                  mManufacturer: kAppleSoftwareAudioCodecManufacturer))
        }
        
        var outBasicStreamDescription = AudioStreamBasicDescription (
            mSampleRate: inBasicStreamDescription.mSampleRate,
            mFormatID: kAudioFormatMPEG4AAC,
            mFormatFlags: UInt32(MPEG4ObjectID.AAC_LC.rawValue),
            mBytesPerPacket: 0,
            mFramesPerPacket: 0,
            mBytesPerFrame: 0,
            mChannelsPerFrame: inBasicStreamDescription.mChannelsPerFrame,
            mBitsPerChannel: 0,
            mReserved: 0)
        
        var size = UInt32(MemoryLayout.size(ofValue: outBasicStreamDescription))
        AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, nil, &size, &outBasicStreamDescription)
        
        var res: AudioConverterRef?
        var copyInBasicStreamDescription = inBasicStreamDescription
        AudioConverterNewSpecific(&copyInBasicStreamDescription,
                                  &outBasicStreamDescription,
                                  UInt32(outAudioClassDescription.count),
                                  &outAudioClassDescription,
                                  &res)
        return res
    }
    
    // TODO: 
    private static func createAdtsHeader()
    {
//        let profile = 2
//        let freqIdx = 4
//        let channelsConfig = 1
//
//        let adtsDataSize = Int(aacDataSize) + 7
//        let adtsData = UnsafeMutablePointer<UInt8>.allocate(capacity: adtsDataSize)
//        memset(adtsData, 0, adtsDataSize)
//        adtsData[0] = 0xFF
//        adtsData[1] = 0xF9
//        adtsData[2] = UInt8((1<<6) + (freqIdx<<2) + (channelsConfig>>2))
//        adtsData[3] = UInt8(((channelsConfig&3) << 6) + (adtsDataSize >> 11))
//        adtsData[4] = UInt8((adtsDataSize & 0x7FF) >> 3)
//        adtsData[5] = UInt8(((adtsDataSize & 7) << 5) + 0x1F)
//        adtsData[6] = 0xFC
//
//        memcpy(adtsData + 7, aacData, Int(aacDataSize))
//        free(aacData)
    }
    
    private var _sender: OpaquePointer
    private var _converter: AudioConverterRef?
    
    private var _inChannelsCount: UInt32 = 0
    private var _inSampleRate: Float64 = 0
    
    private let _inBufferListSize = AudioBufferList.sizeInBytes(maximumBuffers: 1)
    private var _inBufferList = AudioBufferList.allocate(maximumBuffers: 1)
}
