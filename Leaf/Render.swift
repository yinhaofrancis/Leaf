//
//  Render.swift
//  Leaf
//
//  Created by wenyang on 2021/6/27.
//

import MetalKit

public class LeafRender{
    public var leaf:Leaf
    
    public init(leaf:Leaf = Leaf.shared){
        self.leaf = leaf
    }
    
    public typealias RenderBuild = (LeafRender,MTLRenderCommandEncoder)->Void
    
    public func begin(renderPass:LeafRenderPass,build:RenderBuild,viewPort:MTLViewport) throws {
        try self.leaf.beginAsync { leaf, command in
            guard let encoder = command.makeRenderCommandEncoder(descriptor: renderPass.currentRenderPassDescriptor) else {
                return
            }
            encoder.setViewport(viewPort)
            build(self,encoder)
        }
    }
    
}

public class LeafRenderPass{
    var renderPassDescriptor:MTLRenderPassDescriptor
    var layer:CAMetalLayer
    public init(layer:CAMetalLayer){
        self.renderPassDescriptor = MTLRenderPassDescriptor()
        self.renderPassDescriptor.colorAttachments[0].storeAction = .store
        self.renderPassDescriptor.colorAttachments[0].loadAction = .clear
        self.renderPassDescriptor.depthAttachment.clearDepth = 1
        self.layer = layer
    }
    
    public var clearColor:MTLClearColor{
        get{
            return self.renderPassDescriptor.colorAttachments[0].clearColor
        }
        set{
            self.renderPassDescriptor.colorAttachments[0].clearColor = newValue
        }
    }
    
    public var currentRenderPassDescriptor:MTLRenderPassDescriptor{
        self.renderPassDescriptor.colorAttachments[0].texture = self.nextDrawable?.texture
        return self.renderPassDescriptor
    }
    var nextDrawable:CAMetalDrawable?{
        return self.layer.nextDrawable()
    }
}
