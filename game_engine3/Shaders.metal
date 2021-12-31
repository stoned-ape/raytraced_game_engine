//
//  Shaders.metal
//  gputest1
//
//  Created by Apple1 on 12/13/20.
//


#include <metal_stdlib>
#import "ShaderTypes.h"
//#define PATH_TRACE

using namespace metal;


constant float PI=3.14159265;
#ifndef PATH_TRACE
constant float ambient=.4;
#else
constant float ambient=0;
#endif
constant float3 etaRC(1.5,1.55,1.6);//real world values: {1.50917,1.52534,1.51609};


float map(float t,float a,float b,float c,float d){
    return c+(d-c)*(t-a)/(b-a);
}


float3x3 rotz(float theta){
    return float3x3(cos(theta),-sin(theta),0.,
                    sin(theta), cos(theta),0.,
                    0.        ,0.         ,1.);
}

float3x3 roty(float theta){
    return float3x3(cos(theta) ,0.,sin(theta),
                    0.         ,1.,        0.,
                    -sin(theta),0.,cos(theta));
}

float3x3 rotx(float theta){
    return float3x3(1.,0.         ,0.        ,
                    0.,cos(theta),-sin(theta),
                    0.,sin(theta), cos(theta));
}

float4 qMult(float4 q1,float4 q2){
    return float4(q1.x*q2.x-dot(q1.yzw,q2.yzw),
                q1.x*q2.yzw+q2.x*q1.yzw+cross(q1.yzw,q2.yzw));
}

float3 rotate(float3 v,float angle,float3 axis){
    axis=normalize(axis);
    float4 p=float4(cos(angle/2.),sin(angle/2.)*axis);
    float4 r=qMult(p,float4(0.,v));
    return qMult(r,float4(p.x,-p.yzw)).yzw;
}


float3 look(float3 v,constant Uniforms &uni [[buffer(2)]]){
    float theta=map(uni.iMouse.x,0.,uni.iRes.x,-PI,PI);
    float phi=map(uni.iMouse.y,0.,uni.iRes.y,-PI/2.,PI/2.);
    return roty(theta)*rotx(-phi)*v;
}

float4x4 id(){
    return float4x4(
    1.,0.,0.,0.,
    0.,1.,0.,0.,
    0.,0.,1.,0.,
    0.,0.,0.,1.
    );
}
float4x4 trans(float3 v){
    return float4x4(
    1. ,0. ,0. ,0.,
    0. ,1. ,0. ,0.,
    0. ,0. ,1. ,0.,
    v.x,v.y,v.z,1.
    );
}
float4x4 trans(float x,float y,float z){
    return trans(float3(x,y,z));
}
float4x4 scale(float3 v){
    return float4x4(
    v.x,0.,0.,0.,
    0.,v.y,0.,0.,
    0.,0.,v.z,0.,
    0.,0.,0.,1.
    );
}
float4x4 scale(float x,float y,float z){
    return scale(float3(x,y,z));
}
float4x4 rotx4(float theta){
    float s=sin(theta);
    float c=cos(theta);
    return float4x4(
    1.,0.,0.,0.,
    0.,c ,-s,0.,
    0.,s ,c ,0.,
    0.,0.,0.,1.
    );
}
float4x4 roty4(float theta){
    float s=sin(theta);
    float c=cos(theta);
    return float4x4(
    c ,0.,s ,0.,
    0.,1.,0.,0.,
    -s,0.,c ,0.,
    0.,0.,0.,1.
    );
}
float4x4 rotz4(float theta){
    float s=sin(theta);
    float c=cos(theta);
    return float4x4(
    c ,-s,0.,0.,
    s ,c ,0.,0.,
    0.,0.,1.,0.,
    0.,0.,0.,1.
    );
}




float3 m4v3(float4x4 m,float3 v,bool translate){
    return (m*float4(v,float(int(translate)))).xyz;
}


struct quat{
    float s;
    float3 v;
    quat(float _s,float3 _v):s(_s),v(_v){}
    quat operator*(quat q){
        return quat(s*q.s-dot(v,q.v),s*q.v+q.s*v+cross(v,q.v));
    }
    quat conj(){
        return quat(s,-v);
    }
};

quat angleAxis(float theta,float3 n){
    return quat(cos(theta/2),sin(theta/2)*normalize(n));
}
quat fromTo(float3 a,float3 b){
    return angleAxis(acos(dot(normalize(a),normalize(b))),
                     normalize(cross(a,b)));
}
float3 rotate(float3 v,quat q){
    return (q*quat(0,v)*q.conj()).v;
}

float3 project(float3 a,float3 b){
    b=normalize(b);
    return b*dot(a,b);
}


struct ray{
    float3 p;
    float3 v;
    ray(float3 _p,float3 _v):p(_p),v(_v){};
    ray transform(float4x4 m){
        return ray(m4v3(m,p,true),m4v3(m,v,false));
    }
};




struct isec{
    bool hit;
    float dist;
    float3 p;
    float3 n;
    isec(bool _hit,float _dist,float3 _p,float3 _n){
        hit=_hit;
        dist=_dist;
        p=_p;
        n=_n;
    }
    isec(){
        hit=false;
        dist=1e20;
        p=float3(0);
        n=float3(0);
    }
};

struct trace{
    bool hit;
    float3 p;
    float3 n;
    float3 color;
    int material;
    float spec;
    int idx;
    trace(){
        hit=false;
        p=float3(0.);
        n=float3(0.);
        color=float3(0.);
        material=0;
        spec=0;
        idx=0;
    }
};

    


isec sphereIntersect(ray r,constant sceneObject &s){
    isec I;
    r=r.transform(s.inverse);

    float3 d=r.p;
    float A=dot(r.v,r.v);
    float B=dot(r.v,d)*2.;
    float C=dot(d,d)-1;
    float D=B*B-4.*A*C;
    if(D<0.) return I;
    float t2=(-B+sqrt(D))/(2.*A);
    if(t2<0.) return I;
    float t1=(-B-sqrt(D))/(2.*A);
    float t=(t1>0)?t1:t2;
    I.hit=true;
    I.dist=t;
    I.p=r.p+r.v*t;
    I.n=normalize(I.p);
    
    I.p=m4v3(s.transform,I.p,true);
    I.n=normalize(m4v3(s.transform,I.n,false));
    return I;
}
isec planeIntersect(ray r,constant sceneObject &s){
    isec I;
    r=r.transform(s.inverse);
    
    float t=-r.p.y/r.v.y;
    if(t<0.) return I;
    I.hit=true;
    I.dist=t;
    I.p=r.p+r.v*t;
    I.n=float3(0,1,0);
    
    I.p=m4v3(s.transform,I.p,true);
    I.n=normalize(m4v3(s.transform,I.n,false));
    return I;
}
isec cylinderIntersect(ray r,constant sceneObject &s){
    isec I;
    r=r.transform(s.inverse);
    
    float3 d=r.p;
    float A=dot(r.v.xz,r.v.xz);
    float B=dot(r.v.xz,d.xz)*2.;
    float C=dot(d.xz,d.xz)-1;
    float D=B*B-4.*A*C;
    if(D<0.) return I;
    float t2=(-B+sqrt(D))/(2.*A);
    if(t2<0.) return I;
    float t1=(-B-sqrt(D))/(2.*A);
    float t=(t1>0)?t1:t2;
    I.hit=true;
    I.dist=t;
    I.p=r.p+r.v*t;
    I.n=normalize(float3(I.p.xz,0).xzy);
    

    I.p=m4v3(s.transform,I.p,true);
    I.n=normalize(m4v3(s.transform,I.n,false));
    
    return I;
}

isec cubeIntersect(ray r,constant sceneObject &s){
    isec I;
    r=r.transform(s.inverse);
    
    float t=1e20;
    float d=1;
    bool hit=false;
    float3 n(0);
    float3 xp(0);
    for(int i=0;i<3;i++){
        for(int j=-1;j<=1;j+=2){
            float3 N(0,0,0);
            N[i]=j;
            float tp=(d-dot(r.p,N))/dot(r.v,N);
            float3 ip=r.p+r.v*tp;
            if(tp>0 && tp<t && abs(ip[(i+1)%3])<d && abs(ip[(i+2)%3])<d ){
                t=tp;
                hit=true;
                n=N;
                xp=ip;
            }
        }
    }
    I.hit=hit;
    I.dist=t;
    I.p=xp;
    I.n=n;
    
    I.p=m4v3(s.transform,I.p,true);
    I.n=normalize(m4v3(s.transform,I.n,false));
    return I;
}
isec pollIntersect(ray r,constant sceneObject &s){
    isec I;
    r=r.transform(s.inverse);
    
    float3 d=r.p;
    float A=dot(r.v.xz,r.v.xz);
    float B=dot(r.v.xz,d.xz)*2.;
    float C=dot(d.xz,d.xz)-1;
    float D=B*B-4.*A*C;
    if(D<0.) return I;
    float t2=(-B+sqrt(D))/(2.*A);
    if(t2<0.) return I;
    float t1=(-B-sqrt(D))/(2.*A);
    
    float t3= (1-r.p.y)/r.v.y;
    float t4=-(1+r.p.y)/r.v.y;
    if(t3<0 && t4<0) return I;
    float t=1e20;
    float3 n(1);
    if(t1*t2<0 && t3*t4<0){
        //inside poll
        float t5=min(t1,t2);
        float t6=min(t3,t4);
        t=max(t5,t6);
        if(t==t5) n=float3(r.p.xz+r.v.xz*t,0).xzy;
        else n=t==t3?float3(0,1,0):float3(0,-1,0);
    }else if(t1*t2<0){
        //inside cylinder
        t=min(t3,t4);
        if(length(r.p.xz+t*r.v.xz)>1) return I;
        n=t==t3?float3(0,1,0):float3(0,-1,0);
    }else if(t3*t4<0){
        //between the planes
        t=min(t1,t2);
        if(abs(r.p.y+t*r.v.y)>1) return I;
        n=float3(r.p.xz+r.v.xz*t,0).xzy;
    }else{
        float t5=min(t1,t2);
        float t6=min(t3,t4);
        t=max(t5,t6);
        if(abs(r.p.y+t*r.v.y)>1.01 || length(r.p.xz+t*r.v.xz)>1.01) return I;
        if(t==t5) n=float3(r.p.xz+r.v.xz*t,0).xzy;
        else n=t==t3?float3(0,1,0):float3(0,-1,0);
    }
    
    I.hit=true;
    I.dist=t;
    I.p=r.p+r.v*t;
    I.n=n;
    
    I.p=m4v3(s.transform,I.p,true);
    I.n=normalize(m4v3(s.transform,I.n,false));
    return I;
}

isec coneIntersect(ray r,constant sceneObject &s){
    isec I;
    r=r.transform(s.inverse);

    float A= dot(r.v,r.v)-2*r.v.y*r.v.y;
    float B=(dot(r.v,r.p)-2*r.v.y*r.p.y)*2;
    float C= dot(r.p,r.p)-2*r.p.y*r.p.y;
    float D=B*B-4.*A*C;
    if(D<0.) return I;
    float t1=(-B-sqrt(D))/(2.*A);
    float t2=(-B+sqrt(D))/(2.*A);
    float t3= (1-r.p.y)/r.v.y;
    float t=1e20;
    thread float ts[4]={t1,t2,t3};
    float3 gip(1);
    for(int i=0;i<3;i++){
        float3 ip=r.p+r.v*ts[i];
        if(ts[i]>0 && ts[i]<t && ip.y>0 &&
                abs(ip.y)<1.01 && length(ip.xz)<1){
            t=ts[i];
            gip=ip;
        }
    }
    if(t==1e20) return I;
    float3 n=t==t3?float3(0,1,0):normalize(float3(gip.x,-1,gip.z));
    I.hit=true;
    I.dist=t;
    I.p=r.p+r.v*t;
    I.n=n;
    
    I.p=m4v3(s.transform,I.p,true);
    I.n=normalize(m4v3(s.transform,I.n,false));
    return I;
}

isec triangleIntersect(ray r,constant sceneObject &s){
    isec I;
    r=r.transform(s.inverse);
    
    float3 n(1);
    float t=(1-dot(r.p,n))/dot(r.v,n);
    if(t<0.) return I;
    
    I.p=r.p+r.v*t;
    bool3 b=(I.p>0 && I.p<1);
    if(!(b.x && b.y && b.z)) return I;
    I.n=n;
    I.hit=true;
    I.dist=t;
    
    I.p=m4v3(s.transform,I.p,true);
    I.n=normalize(m4v3(s.transform,I.n,false));
    return I;
}


int fac(int n){
    if(n<=1) return 1;
    return n*fac(n-1);
}


void setTraceObj(thread isec &I,thread trace &tr,constant sceneObject &s,ray r,
                 constant Uniforms &uni [[buffer(2)]],int idx){
    tr.spec=.7*pow(max(dot(r.v,reflect(-uni.light,I.n)),0.),43);
    tr.n=I.n;
    tr.color=s.color*max(dot(-uni.light,tr.n),ambient);
    tr.p=I.p;
    tr.hit=true;
    tr.material=s.material;
    tr.idx=idx;
}

trace raytrace(ray r,float3 bg,constant Uniforms &uni [[buffer(2)]]){
    trace tr;
    tr.color=bg;
    float minD=1e10;
    for(int i=0;i<uni.objNum;i++){
        constant sceneObject &s=uni.objs[i];
#define GEO_CASE(ISEC_FUNC) { \
    isec I=ISEC_FUNC(r,s); \
    if(I.hit && I.dist<minD){ \
        setTraceObj(I,tr,s,r,uni,i); \
    } \
    minD=min(minD,I.dist); \
    break; \
}
        switch(s.geometry){
            case SPHERE:   GEO_CASE(sphereIntersect);
            case PLANE:    GEO_CASE(planeIntersect);
            case CYLINDER: GEO_CASE(cylinderIntersect);
            case CUBE:     GEO_CASE(cubeIntersect);
            case POLE:     GEO_CASE(pollIntersect);
            case CONE:     GEO_CASE(coneIntersect);
            case TRIANGLE: GEO_CASE(triangleIntersect);
        }
#undef GEO_CASE
    }
    return tr;
}
int f2i(float f){
    thread void *v=&f;
    thread int *i=(thread int*)v;
    return *i;
}
float i2f(int i){
    thread void *v=&i;
    thread int *f=(thread int*)v;
    return *f;
}
    


float rand(ray r,constant Uniforms &uni [[buffer(2)]],int n=10){
    thread float seeds[10]={1111111,r.v.x,r.v.y,r.v.z,uni.iMouse.x,uni.iMouse.y,uni.iTime};
    thread void *v1=seeds;
    thread int *si=(thread int*)v1;
    int j=1530546462;
    for(int i=0;i<n;i++){
        j^=si[i];
        j=~j;
    }
    thread void *v2=&j;
    thread float *f=(thread float*)v2;
    float rnd=abs(sin(*f));
    return rnd;
}

float3 stars(float3 v,constant Uniforms &uni [[buffer(2)]]){
    float col=0;
    for(int i=0;i<NUM_STARS;i++) col+=pow(dot(v,uni.stars[i]),10000);
    return clamp(float3(col),0,1);
}

float3 skycolor(ray r,constant Uniforms &uni [[buffer(2)]]){
    float spec=1-step(dot(r.v,-uni.light),.999);
    spec=10*pow(max(dot(r.v,-uni.light),0.),1003);
    float neg=1-step(dot(r.v,-uni.light*roty(.03)),.997);
    float3 sky=uni.sky+max(spec-neg*1000.0,0.0);
    sky=abs(sky);
    sky*=float3(1,0,.8);
    float phi=atan(r.v.y/length(r.v.xz));
    
    sky+=1.5*float3(.5,0,1)*(1-exp(-.2*abs(phi-PI/2)));
    
//    sky+=stars(r.v,uni);
//    float3 noise=float3(rand(r,uni,10));
//    sky+=noise;//pow(step(noise,.00001),10);
    
    return clamp(sky,0,1);
}

float3 radiate(ray r,float3 bg,constant Uniforms &uni [[buffer(2)]],
               thread bool &rfr,int rgb=0){
    trace tr;
    rfr=false;
    float a=-1;
    for(int i=0;i<20;i++){
        tr=raytrace(r,bg,uni);
        if(tr.material==DIFFUSE || tr.material==EMISSIVE || !tr.hit) break;
        float3 nv(0);
        float3 reflected=reflect(r.v,tr.n);
        
        switch(tr.material){
            case SPECULAR: nv=reflected; break;
            case GLASS:{
                nv=refract(r.v,-a*tr.n,pow(etaRC[rgb],a));
                if(length(nv)==0 || rand(r,uni)>1){
                    nv=reflected;
                }else{
                    a*=-1;
                    rfr=true;
                }
            }break;
            case PORTAL_1:{
                ray r1(tr.p+.1*r.v,r.v);
                r1=r1.transform(uni.p1Inverse*uni.p2Inverse*uni.p1Transform);
                nv=r1.v;
                tr.p=r1.p;
            }break;
            case PORTAL_2:{
                ray r1(tr.p+.1*r.v,r.v);
                r1=r1.transform(uni.p1Inverse*uni.p2Transform*uni.p1Transform);
                nv=r1.v;
                tr.p=r1.p;
            }break;
            case SCREEN:{
                float3 p_screen=m4v3(uni.objs[tr.idx].inverse,tr.p,true);
                float3 ray_dir=normalize(float3(p_screen.x,p_screen.y,-uni.zoom));
                ray r1(float3(0),ray_dir);
                r1=r1.transform(uni.virtCamTransform);
                nv=normalize(r1.v);
                tr.p=r1.p+nv*0.75;
            }break;
                
        }
        r=ray(tr.p+nv*.01,nv);
        bg=skycolor(r,uni);
    }

    r=ray(tr.p-uni.light*.01,-uni.light);
    
    trace sh=raytrace(r,bg,uni);
    if(sh.hit) tr.color*=ambient;
    else tr.color+=tr.spec;
    return tr.color;
}


float3 pathtrace(ray R,int samples,float3 bg,
                 constant Uniforms &uni [[buffer(2)]]){
    
    float3 col=0;
    int hits=0;
    for(int j=0;j<samples;j++){
        bool hit=false;
        trace tr;
        float a=-1;
        ray r=R;
        float3 diffcol=1;
        for(int i=0;i<6;i++){
            tr=raytrace(r,bg,uni);
            if(!tr.hit){
                if(abs(dot(r.v,uni.light))>.95){
                    col+=diffcol;
                    if(!hit) col+=100;
                }
                break;
            }
            if(tr.material==EMISSIVE){
                col+=diffcol;
                hits++;
                if(!hit) col+=100;
                break;
            }
            if(tr.material==DIFFUSE){
                float xr=  rand(r.transform(roty4((uni.iTime+j)/100)),uni);
                float yr=2*rand(r.transform(rotx4((uni.iTime+j)/100)*roty4(xr)),uni)-1;
                float zr=2*rand(r.transform(rotz4((uni.iTime-j)/100)*rotx4(yr)),uni)-1;
                
                float3 nv=normalize(float3(xr,yr,zr));
                nv=rotate(nv,fromTo(float3(1,0,0),tr.n));
                r=ray(tr.p+nv*.01,nv);
                diffcol=project(diffcol,normalize(tr.color));
                
                hit=true;
                continue;
            }
            float3 nv(0);
            float3 reflected=reflect(r.v,tr.n);
            if(tr.material==SPECULAR) nv=reflected;
            else if(tr.material==GLASS){
                nv=refract(r.v,-a*tr.n,pow(etaRC[0],a));
                if(length(nv)==0 || rand(r,uni)>1){
                    nv=reflected;
                }else{
                    a*=-1;
                }
            }else  if(tr.material==PORTAL_1){
                ray r1(tr.p+.1*r.v,r.v);
                r1=r1.transform(uni.p1Inverse*uni.p2Inverse*uni.p1Transform);
                nv=r1.v;
                tr.p=r1.p;
            }else  if(tr.material==PORTAL_2){
                ray r1(tr.p+.1*r.v,r.v);
                r1=r1.transform(uni.p1Inverse*uni.p2Transform*uni.p1Transform);
                nv=r1.v;
                tr.p=r1.p;
            }else  if(tr.material==SCREEN){
                float3 p_screen=m4v3(uni.objs[tr.idx].inverse,tr.p,true);
                float2 uv=p_screen.xy;
                float3 ray_dir=normalize(float3(uv.x,uv.y,-uni.zoom));
                ray r1(float3(0),ray_dir);
                r1=r1.transform(uni.virtCamTransform);
                nv=normalize(r1.v);
                tr.p=r1.p+nv*0.75;
            }
            r=ray(tr.p+nv*.01,nv);
        }
        
    }
    return clamp(1-exp(-5*col/(samples)),0,1);

}

float2 get_uv(uint2 id,float2 res){
    float2 uv=float2(id)/res;
    float aspect=res.x/res.y;
    uv-=.5;
    uv.x*=aspect;
    uv.y*=-1;
    return uv;
}


kernel void compute(uint2 id [[thread_position_in_grid]],
                    texture2d<float, access::write> output [[texture(0)]],
                    constant Uniforms &uni [[buffer(2)]],
                    texture2d<float, access::sample> prev_frame [[texture(1)]]){
   
    float2 uv=get_uv(id,uni.iRes);
    float3 v=normalize(float3(uv.x,uv.y,-uni.zoom));
    
    ray r=ray(float3(0),v);
    r=r.transform(uni.cameraTransform*uni.viewTransform);
    
    
    
    float3 sky=skycolor(r,uni);
    
    float3 col(1);
    bool rfr=false;
    
//    output.write(float4(sky,1),id);
//    return;
    

#ifndef PATH_TRACE
    
    float3 red=radiate(r,sky,uni,rfr,0);
    if(rfr){
        float3 grn=radiate(r,sky,uni,rfr,1);
        float3 blu=radiate(r,sky,uni,rfr,2);
        col=float3(red.x,grn.y,blu.z);
    }else col=red;
    col+=float3(step(length(uv),.005));
    
    output.write(float4(col,1.0),id);
#else
    constexpr sampler colsamp(mip_filter::linear,
                              mag_filter::linear,
                              min_filter::linear);
    float4 prev_col=prev_frame.sample(colsamp,float2(id)/float2(uni.iRes));
    col=pathtrace(r,1,sky,uni)+.1*radiate(r,sky,uni,rfr,0);
    output.write(float4(col,1.0)+.91*prev_col,id);

//    float3 noise=float3(rand(r,uni));
//    col=noise;
#endif
     
}







