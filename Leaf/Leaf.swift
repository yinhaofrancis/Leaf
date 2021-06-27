//
//  Configure.swift
//  Leaf
//
//  Created by hao yin on 2021/6/25.
//

import Foundation
import Metal

public class Leaf{
    
    
    public typealias CommandBuild = (Leaf,MTLCommandBuffer)throws->Void
    
    public typealias Complete = (MTLCommandBuffer)->Void
    
   var runQueue:DispatchQueue = DispatchQueue(label: "Leaf.Configure")
    
    public init(capcity:Int = 1) throws{
        guard let dev = MTLCreateSystemDefaultDevice() else {
            throw NSError(domain: "create device fail", code: 0, userInfo: nil)
        }
        self.device = dev
        
        guard let queue = dev.makeCommandQueue(maxCommandBufferCount: capcity) else {
            throw NSError(domain: "create queue fail", code: 1, userInfo: nil)
        }
        self.queue = queue
    }
    
    public var device:MTLDevice
    
    private var queue:MTLCommandQueue
    
    public func beginAsync(call:CommandBuild,complete: Complete? = nil) throws{
        let buffer = try self.begin()
        try call(self,buffer)
        if let completeCall = complete{
            buffer.addCompletedHandler { e in
                completeCall(e)
            }
            buffer.commit()
        }else{
            buffer.commit()
        }
    }
    public func begin() throws->MTLCommandBuffer{
        guard let buffer = queue.makeCommandBuffer() else {
            throw NSError(domain: "create buffer fail", code: 2, userInfo: nil)
        }
        return buffer
    }
    
    public func commit(buffer:MTLCommandBuffer){
        buffer.commit()
        buffer.waitUntilCompleted()
    }
    
    public func perform(call:@escaping ()->Void){
        self.runQueue.async {
            call()
        }
    }
    
    lazy public var LeafLibrary:MTLLibrary? = {
        let bundle = Bundle.init(for: Leaf.self)
        do{
            return try self.device.makeDefaultLibrary(bundle: bundle)
        }catch{
            return nil
        }
    }()
    
    lazy public var defaultLibrary:MTLLibrary? = {
        self.device.makeDefaultLibrary()
    }()
    
    public func loadLibrary(url:URL) throws->MTLLibrary{
        try self.device.makeLibrary(URL: url)
    }
    public func createBuffer(length:Int,
                             options:MTLResourceOptions = [.storageModeShared])->MTLBuffer?{
        self.device.makeBuffer(length: length, options: options)
    }
    public func createTexture(width:Int,height:Int,
                              pixelFormat:MTLPixelFormat = .rgba8Unorm_srgb,options:MTLResourceOptions = .storageModeShared)->MTLTexture?{
        
        let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: width, height: height, mipmapped: true)
        desc.resourceOptions = options
        return self.device.makeTexture(descriptor: desc)
    }
    public static var shared:Leaf = {
        do{
            return try Leaf()
        }catch{
            fatalError(error.localizedDescription)
        }
    }()
}
