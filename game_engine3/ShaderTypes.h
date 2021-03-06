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

#ifdef __METAL_IOS__
#pragma message "iOS"
#endif

#else
#import <Foundation/Foundation.h>
#import <sys/time.h>
#import <assert.h>

float _itime(){
    struct timeval tp;
    assert(-1!=gettimeofday(&tp,NULL));
    return (tp.tv_sec%(60*60*24))+tp.tv_usec/1E6;
}

#endif

#include <simd/simd.h>


typedef enum:int{
    DIFFUSE=0,
    SPECULAR=1,
    GLASS=2,
    PORTAL_1=3,
    PORTAL_2=4,
    SCREEN=5,
    EMISSIVE=6,
}en_material;

typedef enum:int{
    SPHERE=0,
    PLANE=1,
    CYLINDER=2,
    CUBE=3,
    POLE=4,
    CONE=5,
    TRIANGLE=6,
}en_geometry;

typedef struct{
    matrix_float4x4 transform;
    matrix_float4x4 inverse;
    en_material material; //en_material
    en_geometry geometry; //en_geometry
    vector_float3 color;
}sceneObject;

#define MAX_OBJECTS 40
#define NUM_STARS 1

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
    matrix_float4x4 virtCamTransform;
    matrix_float4x4 virtCamInverse;
    float zoom;
    bool vr;
    bool pathtrace;
    sceneObject objs[MAX_OBJECTS];
    vector_float3 stars[NUM_STARS];
}Uniforms;



    
    
    

#endif

