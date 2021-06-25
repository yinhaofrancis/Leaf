//
//  ViewController.swift
//  example
//
//  Created by hao yin on 2021/6/25.
//

import UIKit
import Leaf
class ViewController: UIViewController {

    
    let count = 1000
    let com = Computer()
    var a:[Float] = []
    var b:MTLBuffer?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.b = com.leaf.createBuffer(length: MemoryLayout<Float>.stride * count)
        
        self.a = (0 ..< count).reduce(into: self.a, { r, i in
            r.append(Float(i))
        })
        print(a)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let lib = com.leaf.defaultLibrary{
            com.begin(function: "go", lib: lib,size:MTLSize(width: 1000 ,height: 1 ,depth: 1)) { c, e in
                c.loadByte(encoder: e, byte: self.a, len: MemoryLayout<Float>.stride * self.a.count, index: 0)
                c.loadBuffer(encoder: e, buffer: self.b, index: 1)
            } complete: { c in

                for i in 0 ..< self.a.count{
                    let p = self.b!.contents()
                    self.a[i] = p.advanced(by: i * 4).load(as: Float.self)
                }
                print(self.a)
            }
        }
        
    }

}

