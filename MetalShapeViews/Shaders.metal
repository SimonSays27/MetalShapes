//
//  Shaders.metal
//  MetalShapeViews
//
//  Created by Caner Ergin on 5.07.2023.
//

#include <metal_stdlib>
using namespace metal;

// Math
float2 convert_to_metal_coordinates(float2 point, float4 viewRect) {

    float2 pointN = point;
    pointN.x = pointN.x - viewRect.x;
    pointN.y = pointN.y - viewRect.y;
    float2 viewSize = float2(viewRect.z, viewRect.w);
    float2 inverseViewSize = 1 / viewSize;
    float clipX = (2.0f * pointN.x * inverseViewSize.x) - 1.0f;
    float clipY = (2.0f * -pointN.y * inverseViewSize.y) + 1.0f;
    
    return float2(clipX, clipY);
}

struct Matrix {
    /// Identity
    float4x4 matrix = float4x4(1,0,0,0,
                               0,1,0,0,
                               0,0,1,0,
                               0,0,0,1);
    
    /// Translated
    void translate(float x, float y, float z) {
        float4x4 translation = float4x4(1,0,0,0,
                                        0,1,0,0,
                                        0,0,1,0,
                                        x,y,z,1);
        matrix = matrix * translation;
    };
    
    /// Scaled
    void scale(float x, float y, float z) {
        float4x4 scale = float4x4(x,0,0,0,
                                  0,y,0,0,
                                  0,0,z,0,
                                  0,0,0,1);
        matrix = matrix * scale;
    };
    
    /// Rotated
    void rotate(float angle, float x, float y, float z) {
                
        float c = cos(angle);
        float s = sin(angle);
        
        float4 column0 = float4(0,0,0,0);
        column0.x = x * x + (1 - x * x) * c;
        column0.y = x * y * (1 - c) - z * s;
        column0.z = x * z * (1 - c) + y * s;
        column0.w = 0;
        
        float4 column1 = float4(0,0,0,0);
        column1.x = x * y * (1 - c) + z * s;
        column1.y = y * y + (1 - y * y) * c;
        column1.z = y * z * (1 - c) - x * s;
        column1.w = 0;
        
        float4 column2 = float4(0,0,0,0);
        column2.x = x * z * (1 - c) - y * s;
        column2.y = y * z * (1 - c) + x * s;
        column2.z = z * z + (1 - z * z) * c;
        column2.w = 0;
        
        float4 column3 = float4(0,0,0,1);
        
        float4x4 rotation = float4x4(column0, column1, column2, column3);
        
        matrix = matrix * rotation;
    };
};

struct Rectangle {
    float4 position [[position]];
    float4 boundary;
    float4 canvas;
    float cornerRadius;
};

vertex Rectangle basic_vertex_shader(constant float2 *vertices [[ buffer(0) ]],
                                     constant float4 &canvasRect [[ buffer(1) ]],
                                     constant float4 &selfRect [[ buffer(2) ]],
                                     uint vertexID [[ vertex_id ]])
{
    
    float2 selfRectCenter = float2(selfRect.x + selfRect.z / 2, selfRect.y + selfRect.w / 2);
    float2 selfRectCenterConverted = convert_to_metal_coordinates(selfRectCenter, canvasRect);
    
    float canvasScale = canvasRect.z / canvasRect.w;
    float scaleAmount = selfRect.z / canvasRect.z;
    
    Matrix vm;
    vm.translate(selfRectCenterConverted.x, selfRectCenterConverted.y, 0);
    vm.scale(scaleAmount, scaleAmount * canvasScale, 1);
    
    float4 result = vm.matrix * float4(vertices[vertexID], 0, 1);
    
    Rectangle r;
    r.position = result;
    r.boundary = selfRect;
    r.canvas = canvasRect;
    r.cornerRadius = 3;
    
    return r;
}

fragment half4 basic_fragment_shader(Rectangle r [[ stage_in ]])
{
    
    float2 boxCenter = r.boundary.xy * 3 + r.boundary.zw * 3 / 2;
    float2 diff = r.position.xy - boxCenter;
    
    // Topleft corner
    if (diff.x < -120 && diff.y < -120) {
        float calcX = 120 + diff.x;
        float calcY = 120 + diff.y;
        float length = sqrt(calcX * calcX + calcY * calcY);
        if (length > 30) { discard_fragment(); }
    }
    
    // half theX = (r.boundary.x - r.boundary.z) * 3 - r.position.x;
    // half theY = (r.boundary.y - r.boundary.w) * 3 - r.position.y;
    // int sum = theX + theY;
    // if (sum < 10) { discard_fragment(); }
    
    return half4(0.6, 0.2, 0.1, 1.0);
    
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

    
   // /** TRYing to round CORNERS */
   // half theX = r.position.x;
   // half theY = r.position.y;
   //
   // // TopLeft
   // if (theX < 100 && theY < 100) {
   //     int sum = sqrt(theX) + sqrt(theY);
   //     if (sum < 10) { discard_fragment(); }
   // }
   // // TopRight
   // else if (theX > 800 && theY < 100) {
   //     int sum = sqrt(900 - theX) + sqrt(theY);
   //     if (sum < 10) { discard_fragment(); }
   // }
   // // BottomLeft
   // else if (theX < 100 && theY > 1400) {
   //     int sum = sqrt(theX) + sqrt(1500 - theY);
   //     if (sum < 10) { discard_fragment(); }
   // }
   // // BottomRight
   // else if (theX > 800 && theY > 1400) {
   //     int sum = sqrt(900 - theX) + sqrt(1500 - theY);
   //     if (sum < 10) { discard_fragment(); }
   // }
   // /** TRYing to round CORNERS */
   //
   // return half4(0.6, 0.2, 0.1, 1.0);
}

