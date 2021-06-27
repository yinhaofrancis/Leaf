//
//  Computer.swift
//  Leaf
//
//  Created by wenyang on 2021/6/27.
//

import Metal

public class Computer{
    public var leaf:Leaf
    
    public init(leaf:Leaf = Leaf.shared){
        self.leaf = leaf
    }
    
    public typealias EncodeBuild = (Computer,MTLComputeCommandEncoder) throws ->Void
    public typealias EncodeComplete = (Bool)->Void
    
    public func compute(comandBuffer:MTLCommandBuffer,encoder:EncodeBuild) throws{
        guard let enc = comandBuffer.makeComputeCommandEncoder() else {
            throw NSError(domain: "create encoder", code: 3, userInfo: nil)
        }
        try encoder(self,enc)
        enc.endEncoding()
    }
    public func begin(function:String,lib:MTLLibrary,size:MTLSize,encoder: @escaping EncodeBuild,complete:@escaping EncodeComplete) throws{
        try self.leaf.beginAsync(call: { leaf, buffer in
            try? self.compute(comandBuffer: buffer, encoder: { c, enc in
                guard let state = try? self.loadShader(encoder: enc, name: function, lib: lib) else {
                    complete(false)
                    return
                }
                enc.setComputePipelineState(state)
                try encoder(c,enc)
                c.concurrent2d(encoder: enc, size:size)
            })
        }, complete: { c in
            complete(true)
        })
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
