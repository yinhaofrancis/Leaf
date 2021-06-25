//
//  run.metal
//  example
//
//  Created by hao yin on 2021/6/25.
//

#include <metal_stdlib>
using namespace metal;


kernel void go(
               const device float* value [[buffer(0)]],
               device float* value2 [[buffer(1)]],
               uint id [[ thread_position_in_grid ]]){
    value2[id] = value[id] + 1;
}
