//
//  Configure.swift
//  Leaf
//
//  Created by hao yin on 2021/6/25.
//

import Foundation
import Metal

public class Leaf{
    
    
    public typealias CommandBuild = (Leaf,MTLCommandBuffer)->Void
    
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
    
    public func begin(call:CommandBuild,complete: Complete? = nil) throws{
        guard let buffer = queue.makeCommandBuffer() else {
            throw NSError(domain: "create buffer fail", code: 2, userInfo: nil)
        }
        call(self,buffer)
        if let completeCall = complete{
            buffer.addCompletedHandler { e in
                completeCall(e)
            }
            buffer.commit()
        }else{
            buffer.commit()
        }
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

public class Computer{
    public var leaf:Leaf
    
    public init(leaf:Leaf = Leaf.shared){
        self.leaf = leaf
    }
    
    public typealias EncodeBuild = (Computer,MTLComputeCommandEncoder)->Void
    public typealias EncodeComplete = (Bool)->Void
    
    public func compute(comandBuffer:MTLCommandBuffer,encoder:EncodeBuild) throws{
        guard let enc = comandBuffer.makeComputeCommandEncoder() else {
            throw NSError(domain: "create encoder", code: 3, userInfo: nil)
        }
        encoder(self,enc)
        enc.endEncoding()
    }
    public func begin(function:String,lib:MTLLibrary,size:MTLSize,encoder: @escaping EncodeBuild,complete:@escaping EncodeComplete){
        self.leaf.perform {
            try? self.leaf.begin(call: { leaf, buffer in
                try? self.compute(comandBuffer: buffer, encoder: { c, enc in
                    guard let state = try? self.loadShader(encoder: enc, name: function, lib: lib) else {
                        complete(false)
                        return
                    }
                    enc.setComputePipelineState(state)
                    encoder(c,enc)
                    c.concurrent2d(encoder: enc, size:size)
                })
            }, complete: { c in
                complete(true)
            })
        }
    }
    public func concurrent2d(encoder:MTLComputeCommandEncoder,size:MTLSize){
        let w = Int(sqrt(Double(self.leaf.device.maxThreadsPerThreadgroup.width)))
        if(min(size.width , size.height) > w){
            let x = Int(ceil(Float(size.width) / Float(w)))
            let y = Int(ceil(Float(size.height) / Float(w)))
            let s = MTLSize(width: x, height: y, depth: 1)
            encoder.dispatchThreadgroups(s, threadsPerThreadgroup: MTLSize(width: w, height: w, depth: 1))
        }else{
            encoder.dispatchThreadgroups(size, threadsPerThreadgroup: MTLSize(width:1, height: 1, depth: 1))
        }
    }

    
    public func concurrent(encoder:MTLComputeCommandEncoder,grid:MTLSize,size:MTLSize){
        encoder.dispatchThreads(grid, threadsPerThreadgroup: size)
    }
    public func loadBuffers(encoder:MTLComputeCommandEncoder,buffer:[MTLBuffer?]){
        encoder.setBuffers(buffer, offsets: (0..<buffer.count).map{_ in 0}, range:0 ..< buffer.count)
    }
    public func loadTextures(encoder:MTLComputeCommandEncoder,texture:[MTLTexture?]) {
        encoder.setTextures(texture, range: 0 ..< texture.count)
    }
    public func loadShader(encoder:MTLComputeCommandEncoder,name:String,lib:MTLLibrary) throws->MTLComputePipelineState {
        guard let function = lib.makeFunction(name: name) else {
            throw NSError(domain: "create function fail", code: 4, userInfo: nil)
        }
        return try self.leaf.device.makeComputePipelineState(function: function)
    }
    public func loadByte(encoder:MTLComputeCommandEncoder,byte:UnsafeRawPointer,len:Int,index:Int){
        encoder.setBytes(byte, length: len, index: index)
    }
    
    public func loadBuffer(encoder:MTLComputeCommandEncoder,buffer:MTLBuffer?,index:Int){
        encoder.setBuffer(buffer, offset: 0, index: index)
    }
}

