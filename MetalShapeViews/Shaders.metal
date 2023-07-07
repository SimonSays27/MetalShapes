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

fragment half4 basic_fragment_shader(float4 position [[position]],
                                     float2 coord [[point_coord]]) {
    
    /** DRAWING HALF AND CHECKED*/
    // int theX = int(position.x);
    // int theY = int(position.y);
    // if (theX % 2 && theX > 450 && theY % 2) { return half4(0.1, 0.9, 0.9, 1.0); }
    /** DRAWING HALF AND CHECKED*/

    
    /** CHAMFER CORNERS */
    // half theX = position.x;
    // half theY = position.y;
    // int sum = theX + theY;
    // if (sum < 100 || sum > 900) { return half4(0.1, 0.9, 0.9, 1.0); }
    /** CHAMFER */

    
    /** TRYing to round CORNERS */
    half theX = position.x;
    half theY = position.y;
    int sum = sqrt(theX) + sqrt(theY);
    if (sum < 10) { discard_fragment(); }
    /** TRYing to round CORNERS */
    
    // if (position.x > len.x / 2) { return half4(0.5, 0.1, 0.1, 1.0); }
    
    float radius = sqrt(position.x * position.x + position.y * position.y);
    
    if (radius < 1000) { return half4(0.6, 0.2, 0.1, 1.0); };
    
    discard_fragment();
    
    return half4(1);
}
