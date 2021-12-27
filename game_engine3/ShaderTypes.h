//
//  ShaderTypes.h
//  gputest1
//
//  Created by Apple1 on 12/13/20.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#define NSInteger metal::int32_t
#else
#import <Foundation/Foundation.h>
#endif

#include <simd/simd.h>

typedef struct{
    matrix_float4x4 transform;
    matrix_float4x4 inverse;
    int material;
    // 0=diffuse,1=specular,2=glass,3=portal 1,4=portal 2
    int geometry;
    // 0=sphere,1=plane,2=cylinder,3=cube,4=poll,5=cone,6=triangle
    vector_float3 color;
}sceneObject;

typedef struct{
    float iTime;
    vector_float2 iMouse;
    vector_float2 iRes;
    int objNum;
    vector_float3 light;
    vector_float3 sky;
    matrix_float4x4 cameraTransform;
    matrix_float4x4 viewTransform;
    matrix_float4x4 p1Transform;
    matrix_float4x4 p1Inverse;
    matrix_float4x4 p2Transform;
    matrix_float4x4 p2Inverse;
    float zoom;
    sceneObject objs[40];
} Uniforms;


    
    
    

#endif

