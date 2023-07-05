//
//  Shaders.metal
//  MetalShapeViews
//
//  Created by Caner Ergin on 5.07.2023.
//

#include <metal_stdlib>
using namespace metal;

vertex float4 basic_vertex_shader(constant float3 *vertices [[ buffer(0) ]],
                                  uint vertexID [[ vertex_id ]])
{
    return float4(vertices[vertexID], 1);
}

fragment half4 basic_fragment_shader() {
    return half4(1);
}
