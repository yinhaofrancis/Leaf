//
//  IconGallery.swift
//  Leaf
//
//  Created by hao yin on 2021/7/5.
//

import UIKit

public protocol BoxDelegate:AnyObject{
    var size:CGSize { get }
}

public class Box:Hashable{
    public static func == (lhs: Box, rhs: Box) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(Unmanaged.passRetained(self).toOpaque())
    }
    
    public enum Number{
        case value(CGFloat)
        case percent(CGFloat)
        case none
        
        func calc(c:CGFloat)->CGFloat{
            switch self {
            case let .value(v):
                return v
            case let .percent(p):
                return c * p
            case .none:
                return 0
            }
        }
        func limit(parent:CGFloat,min:Number,max:Number)->CGFloat{
            let v = self.calc(c: parent)
            let min = min.calc(c: parent)
            let max = max.calc(c: parent)
            if v > min && v < max{
                return v
            }else if v < min{
                return min
            }else{
                return max
            }
        }
         
        var isNone:Bool{
            switch self {
            case .value(_):
                return false
            case .percent(_):
                return false
            case .none:
                return true
            }
        }
    }
 
    public var width:Number = .none
    
    public var minWidth:Number = .none
    
    public var maxWidth:Number = .none
    
    public var height:Number = .none
    
    public var minHeight:Number = .none
    
    public var maxHeight:Number = .none
    
    public weak var superBox:Box?
    
    public private(set) var subBoxes:[Box] = []
    
    public weak var contentDelegate:BoxDelegate?
    
    public private(set) var displayRealSize:CGSize = .zero
 
    public var originSize:CGSize{
        let parentSize:CGSize = self.superBox?.displayRealSize ?? .zero
        let w = self.width.isNone ? .value(self.contentDelegate?.size.width ?? 0) : self.width
        let h = self.height.isNone ? .value(self.contentDelegate?.size.height ?? 0) : self.height
        return CGSize(
            width: w.limit(
                parent: parentSize.width,
                min: self.minWidth,
                max: self.maxWidth
            ),
            height: h.limit(
                parent: parentSize.height,
                min: self.minHeight,
                max: self.maxHeight
            )
        )
    }
    public init(){}
    public func layout(size:CGSize? = nil){
        if let s = size{
            self.displayRealSize = s
        }
        self.subBoxes.forEach { b in
            b.layout(size: b.originSize)
        }
    }
}
