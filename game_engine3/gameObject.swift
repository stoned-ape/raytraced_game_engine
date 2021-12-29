//
//  gameObject.swift
//  gputest1
//
//  Created by Apple1 on 12/14/20
//

import Foundation
import Metal
import MetalKit
import simd
import Dispatch
import GameKit

typealias float=Float
typealias double=Double
typealias int=Int
typealias bool=Bool
typealias string=String
typealias char=Character
typealias vec2=SIMD2<float>
typealias vec3=SIMD3<float>
typealias vec4=SIMD4<float>

typealias mat2=matrix_float2x2
typealias mat3=matrix_float3x3
typealias mat4=matrix_float4x4
typealias quat=simd_quatf

let PI=float.pi

var startTime:int=0

func rand()->float{
    return float.random(in: 0...1)
}

func time()->float{
    return float(ProcessInfo.processInfo.systemUptime)
}

func sizeof<T:Any>(_ a:T)->int{
    return MemoryLayout.size(ofValue:a)
}

func map(_ t:float,_ a:float,_ b:float,_ c:float,_ d:float)->float{
    return c+(d-c)*(t-a)/(b-a)
}

func m4v3(_ m:mat4,_ v:vec3,_ transform:bool)->vec3{
    var a:float=0
    if(transform){a=0}
    let u=m*vec4(v,a)
    return vec3(u.x,u.y,u.z)
}



extension mat4{
    init<T: BinaryFloatingPoint>
        (_ i0:T,_ i1:T,_ i2:T,_ i3:T,_ i4:T,_ i5:T,_ i6:T,_ i7:T,
         _ i8:T,_ i9:T,_ ia:T,_ ib:T,_ ic:T,_ id:T,_ ie:T,_ iff:T){
        self.init(
            vec4(float(i0),float(i1),float(i2),float(i3)),
            vec4(float(i4),float(i5),float(i6),float(i7)),
            vec4(float(i8),float(i9),float(ia),float(ib)),
            vec4(float(ic),float(id),float(ie),float(iff)))
    }
    func position()->vec3{
        let v=self[3]
        return vec3(v.x,v.y,v.z)
    }
}



func id()->mat4{
    return mat4(
    1.0,0.0,0.0,0.0,
    0.0,1.0,0.0,0.0,
    0.0,0.0,1.0,0.0,
    0.0,0.0,0.0,1.0
    );
}
func trans(_ v:vec3)->mat4{
    return mat4(
    1.0,0.0,0.0,0.0,
    0.0,1.0,0.0,0.0,
    0.0,0.0,1.0,0.0,
    v.x,v.y,v.z,1.0
    );
}
func trans(_ x:float,_ y:float,_ z:float)->mat4{
    return trans(vec3(x,y,z));
}
func scale(_ v:vec3)->mat4{
    return mat4(
    v.x,0.0,0.0,0.0,
    0.0,v.y,0.0,0.0,
    0.0,0.0,v.z,0.0,
    0.0,0.0,0.0,1.0
    );
}
func scale(_ x:float,_ y:float,_ z:float)->mat4{
    return scale(vec3(x,y,z));
}
func scale(_ s:float)->mat4{
    return scale(vec3(s));
}
func rotx(_ theta:float)->mat4{
    let s=sin(theta);
    let c=cos(theta);
    return mat4(
    1.0,0.0,0.0,0.0,
    0.0,c  ,s  ,0.0,
    0.0,-s ,c  ,0.0,
    0.0,0.0,0.0,1.0
    );
}
func roty(_ theta:float)->mat4{
    let s=sin(theta);
    let c=cos(theta);
    return mat4(
    c  ,0.0,-s ,0.0,
    0.0,1.0,0.0,0.0,
    s  ,0.0,c  ,0.0,
    0.0,0.0,0.0,1.0
    );
}
func rotz(_ theta:float)->mat4{
    let s=sin(theta);
    let c=cos(theta);
    return mat4(
    c  ,s  ,0.0,0.0,
    -s ,c  ,0.0,0.0,
    0.0,0.0,1.0,0.0,
    0.0,0.0,0.0,1.0
    );
}

enum Material:string,CaseIterable{
    case diffuse  = "diffuse"
    case specular = "specular"
    case glass    = "glass"
    case portal1  = "portal1"
    case portal2  = "portal2"
    case emmisive = "emmisive"
}

enum Geometry:string,CaseIterable{
    case sphere   = "sphere"
    case plane    = "plane"
    case cylinder = "cylinder"
    case cube     = "cube"
    case poll     = "poll"
    case cone     = "cone"
    case triangle = "triangle"
}

class gameObject{
    var transform:mat4=id()
    var material=Material.diffuse
    var geometry=Geometry.sphere
    var leafs:[gameObject]=[]
    var visible=true
    var color:vec3=normalize(vec3(rand(),rand(),rand()))
    var instanceUpdate:(gameObject)->Void={_ in }
    var ex:bool=true
    init(){}
    init(_ m:Material,_ g:Geometry){
        material=m
        geometry=g
    }
    init(_ m:Material,_ g:Geometry,_ t:mat4){
        material=m
        geometry=g
        transform=t
    }
    init(_ obj:gameObject){
        transform=obj.transform
        material=obj.material
        geometry=obj.geometry
        visible=obj.visible
        color=obj.color
        instanceUpdate=obj.instanceUpdate
        ex=obj.ex
        for l in obj.leafs{
            addLeaf(gameObject(l))
        }
    }
    func addLeaf(_ g:gameObject){
        leafs.append(g)
    }
    func toScene(_ t:mat4)->sceneObject{
        var s=sceneObject()
        var i:Int32=0
        for mat in Material.allCases{
            if mat==material{
                s.material=i
                break
            }
            i+=1
        }        
        i=0
        for geo in Geometry.allCases{
            if geo==geometry{
                s.geometry=i
                break
            }
            i+=1
        }
        s.transform=t
        s.inverse=t.inverse
        s.color=color
        return s
    }
    func load(_ v:inout [sceneObject],_ t:mat4){
        if(visible){v.append(toScene(t*transform))}
        for l in leafs{
            l.load(&v,t*transform)
        }
    }
    func update(){}
    func updateTree(){
        update()
        instanceUpdate(self)
        for l in leafs{
            l.updateTree()
        }
    }
    func setColor(_ c:vec3)->gameObject{
        color=c;
        for l in leafs{
            _=l.setColor(c);
        }
        return self
    }
    func setMaterial(_ m:Material)->gameObject{
        material=m
        for l in leafs{
            _=l.setMaterial(m);
        }
        return self
    }
    func setTransform(_ m:mat4)->gameObject{
        transform=m
        return self
    }
    func addTransform(_ m:mat4)->gameObject{
        transform=m*transform
        return self
    }
    func setVisible(_ v:bool)->gameObject{
        visible=v
        for l in leafs{
            _=l.setVisible(v);
        }
        return self
    }
}

class plane:gameObject{
    override init(){
        super.init(.diffuse,.plane)
    }
    init(_ p:vec3,_ n:vec3){
        super.init(.diffuse,.plane)
        let q=quat(from:vec3(0,1,0),to:normalize(n))
        transform=trans(p)*mat4(q)
        color=normalize(vec3(rand(),rand(),rand()))
    }
}

class cylinder:gameObject{
    override init(){
        super.init(.diffuse,.cylinder)
    }
    init(_ p:vec3,_ n:vec3){
        super.init(.diffuse,.cylinder)
        let q=quat(from:vec3(0,1,0),to:normalize(n))
        transform=trans(p)*mat4(q)
    }
}

class sphere:gameObject{
    override init(){
        super.init(.diffuse,.sphere)
    }
    init(_ p:vec3,_ r:float){
        super.init(.diffuse,.sphere)
        transform=trans(p)*scale(r)
    }
}

class box:gameObject{
    override init(){
        super.init(.diffuse,.cube)
    }
    init(_ p:vec3,_ sc:vec3,_ material:Material){
        super.init(material,.cube)
        transform=scale(sc)*trans(p)
    }
}
class block:box{
    init(_ e:bool){
        super.init()
        ex=e;
    }
}

class axis:gameObject{
    init(_ t:mat4){
        super.init(.diffuse,.sphere)
        visible=false
        let x=cylinder(vec3(0),vec3(1,0,0))
        let y=cylinder(vec3(0),vec3(0,1,0))
        let z=cylinder(vec3(0),vec3(0,0,1))
        transform=t*scale(1.0/3);
        x.color=vec3(1,0,0)
        y.color=vec3(0,1,0)
        z.color=vec3(0,0,1)
        addLeaf(x)
        addLeaf(y)
        addLeaf(z)
    }
}

class cone:gameObject{
    override init(){
        super.init(.diffuse,.cone)
    }
    init(_ p:vec3,_ n:vec3){
        super.init(.diffuse,.cone)
        let q=quat(from:vec3(0,1,0),to:normalize(n))
        transform=trans(p)*mat4(q)
    }
}

class triangle:gameObject{
    override init(){
        super.init(.diffuse,.triangle)
    }
    init(_ v1:vec3,_ v2:vec3,_ v3:vec3){
        super.init(.diffuse,.triangle)
        transform=mat4(vec4(v1,0),vec4(v2,0),vec4(v3,0),vec4(vec3(0),1))
    }
}
class ray{
    var p:vec3
    var v:vec3
    init(_ _p:vec3,_ _v:vec3){
        p=_p
        v=_v
    }
    func transform(_ m:mat4)->ray{
        return ray(m4v3(m,p,true),m4v3(m,v,false))
    }
}

class blockWorld:gameObject{
    var mtx:[[[gameObject]]]=[]
    var size:int=0
    init(_ s:int){
        super.init(.diffuse,.sphere)
        visible=false
        size=s
        let nm=GKNoiseMap(GKNoise(GKPerlinNoiseSource()))
        for i in 0..<size{
            var mi:[[gameObject]]=[]
            for j in 0..<size{
                var mj:[gameObject]=[]
                for k in 0..<size{
                    if(Float(j-3)<4*nm.value(at:SIMD2<Int32>(4*Int32(i),4*Int32(k+300)))){
                        let b=block(true)
                        b.transform=scale(0.5)*trans(float(i),float(j),float(k))
                        mj.append(b)
                        addLeaf(b)
                    }else{
                        let b=block(false).setVisible(false)
                        mj.append(b)
                        addLeaf(b)
                    }
                }
                mi.append(mj)
            }
            mtx.append(mi)
        }
        for i in 1..<size-1{
            for j in 1..<size-1{
                for k in 1..<size-1{
                    if(     mtx[i+1][j][k].ex &&
                            mtx[i-1][j][k].ex &&
                            mtx[i][j+1][k].ex &&
                            mtx[i][j-1][k].ex &&
                            mtx[i][j][k+1].ex &&
                            mtx[i][j][k-1].ex){
                        mtx[i][j][k].visible=false
                    }
                }
            }
        }
    }
    
}

class octahedron:gameObject{
    override init(){
        super.init(.diffuse,.sphere)
        visible=false
        addLeaf(triangle([1,0,0],[0,1,0],[0,0,-1]))
        addLeaf(triangle([1,0,0],[0,1,0],[0,0,1]))
        addLeaf(triangle([1,0,0],[0,-1,0],[0,0,-1]))
        addLeaf(triangle([1,0,0],[0,-1,0],[0,0,1]))
        addLeaf(triangle([-1,0,0],[0,1,0],[0,0,-1]))
        addLeaf(triangle([-1,0,0],[0,1,0],[0,0,1]))
        addLeaf(triangle([-1,0,0],[0,-1,0],[0,0,-1]))
        addLeaf(triangle([-1,0,0],[0,-1,0],[0,0,1]))
    }
}

class tetrahedron:gameObject{
    override init(){
        super.init(.diffuse,.sphere)
        visible=false
        var t=vec3(0.5)
        addLeaf(triangle([1,0,0],[0,1,0],[0,0,1]).addTransform(trans(t)))
        addLeaf(triangle([1,0,0],[0,1,0],[1,1,1]).addTransform(trans(t)))
        addLeaf(triangle([0,0,1],[0,1,0],[1,1,1]).addTransform(trans(t)))
        addLeaf(triangle([1,0,0],[0,0,1],[1,1,1]).addTransform(trans(t)))
    }
}

class camera:gameObject{
    init(_ p:vec3){
        super.init(.diffuse,.sphere)
        visible=false
        transform=trans(p)
    }
}

class portal:gameObject{
    var sideP1:float=1;
    var psideP1:float=1;
    var sideP2:float=1;
    var psideP2:float=1;
    init(_ pt:mat4){
        super.init(.diffuse,.sphere)
        visible=false
        let b1=box().setTransform(scale(2,2,1.0/1000)).setMaterial(.portal1)
        b1.addLeaf(box().setTransform(trans(0,0,-0.1)*scale(1/0.9,1/0.9,1)))
        
        
        let p2=gameObject(.diffuse,.sphere)
        addLeaf(p2)
        addLeaf(b1)
        p2.transform=pt
        p2.visible=false;
        let b2=box().setTransform(scale(2,2,1.0/1000)).setMaterial(.portal2)
        b2.addLeaf(box().setTransform(trans(0,0,0.1)*scale(1/0.9,1/0.9,1)))
        p2.addLeaf(b2)
    }
    func checkP1(_ camT:mat4)->bool{
        let tr=transform
        let v=camT.position()-tr.position()+m4v3(camT,vec3(0,0,0),false)
        psideP1=sideP1
        sideP1=dot(v,m4v3(tr,vec3(0,0,1),false))
        return sideP1*psideP1<0 && length(v)<2
    }
    func checkP2(_ camT:mat4)->bool{
        let tr=transform*leafs[0].transform
        let v=camT.position()-tr.position()+m4v3(camT,vec3(0,0,0),false)
        psideP2=sideP2
        sideP2=dot(v,m4v3(tr,vec3(0,0,1),false))
        return sideP2*psideP2<0 && length(v)<2
    }
    func teleport(_ camT:mat4)->mat4{
        togglebounds(portal: true, hidden: false)
        togglebounds(portal: false, hidden: false)
        
        if checkP1(camT){
            print("hit p1")
            togglebounds(portal: true, hidden: true)
            let nt=transform*leafs[0].transform*transform.inverse*camT;
            _=checkP2(nt)
            return nt
        }
        if checkP2(camT){
            print("hit p2")
            togglebounds(portal: false, hidden: true)
            let nt=transform*leafs[0].transform.inverse*transform.inverse*camT;
            _=checkP1(nt)
            return nt
        }
        return camT
    }
    override func update() {
        //leafs[0].transform=leafs[0].transform*rotz(0.01)
//        leafs[0].transform=leafs[0].transform*trans(0,0,0.25*sin(time()))
    }
    func  togglebounds(portal:bool,hidden:bool){
        if !portal{
            leafs[1].leafs[0].visible = !hidden
            return
        }
        leafs[0].leafs[0].leafs[0].visible = !hidden
    }
}



    


