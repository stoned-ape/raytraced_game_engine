//
//  Renderer.swift
//  gputest1
//
//  Created by Apple1 on 12/13/20.
//
import Metal
import MetalKit
import simd

let alignedUniformsSize=(MemoryLayout<Uniforms>.size + 0xFF) & -0x100
let maxBuffersInFlight=3

class Renderer:NSObject,MTKViewDelegate{
    let device:MTLDevice
    let commandQueue:MTLCommandQueue
    var dynamicUniformBuffer:MTLBuffer
    var pipelineState:MTLComputePipelineState
    let inFlightSemaphore=DispatchSemaphore(value: maxBuffersInFlight)
    var uniformBufferOffset=0
    var uniformBufferIndex=0
    var uniforms:UnsafeMutablePointer<Uniforms>
    
    var iMouse=vec2(400,300)
    var iRes=vec2(556,411)
    var camP=vec3(0,0,5)
    var camV=vec3(0,0,-1)
    var light=vec3(0,1,0)
    var cameraTransform=id()
    var viewTransform=id()
    
    var keyDown:[char:bool]=[:]
    var zoom:float=0.7
    
    var frameCount:int=0
    var frameRate:float=0

    var root=gameObject()
    var game_view:gameview?
    var cursor=sphere()
    var container=gameObject()
    
    var rightMouseDown=false
    var leftMouseDown=false
    
    var portals:portal?
    var bind:bindings?
    
    override init(){
        self.device = MTLCreateSystemDefaultDevice()!
        self.commandQueue = self.device.makeCommandQueue()!
        let library=device.makeDefaultLibrary()!
        let function=library.makeFunction(name: "compute")!
        pipelineState=try! device.makeComputePipelineState(function: function)
        let uniformBufferSize = alignedUniformsSize * maxBuffersInFlight
        self.dynamicUniformBuffer = self.device.makeBuffer(length:uniformBufferSize,
                                                           options:[])!
        self.dynamicUniformBuffer.label = "UniformBuffer"
        uniforms = UnsafeMutableRawPointer(
            dynamicUniformBuffer.contents()).bindMemory(to:Uniforms.self, capacity:1)
        super.init()
        start()
    }
    func draw(in view: MTKView){
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let commandEncoder = commandBuffer.makeComputeCommandEncoder(),
              let drawable = view.currentDrawable else {
            return
        }
        
        _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
        let semaphore = inFlightSemaphore
        commandBuffer.addCompletedHandler { (_ commandBuffer)-> Swift.Void in
            semaphore.signal()
        }
        self.updateDynamicBufferState()
        update()
        commandEncoder.setComputePipelineState(pipelineState)
        commandEncoder.setBuffer(dynamicUniformBuffer, offset:uniformBufferOffset, index: 2)
        commandEncoder.setTexture(drawable.texture, index: 0)
        var w = pipelineState.threadExecutionWidth
        var h = pipelineState.maxTotalThreadsPerThreadgroup / w
        print("w: \(w) h: \(h)")
        iRes=vec2(float(view.drawableSize.width),float(view.drawableSize.height))
        let threadsPerThreadgroup = MTLSizeMake(w, h, 1)
        let dw=Int(view.drawableSize.width)
        let dh=Int(view.drawableSize.height)
        w=dw/w+((dw%w != 0) ? 1:0)
        h=dh/h+((dh%h != 0) ? 1:0)
        commandEncoder.dispatchThreadgroups(
            MTLSize(width:w,height:h,depth:1),
            threadsPerThreadgroup:threadsPerThreadgroup)
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    func updateDynamicBufferState() {
        uniformBufferIndex = (uniformBufferIndex + 1) % maxBuffersInFlight
        uniformBufferOffset = alignedUniformsSize * uniformBufferIndex
        uniforms=UnsafeMutableRawPointer(dynamicUniformBuffer.contents() +
                    uniformBufferOffset).bindMemory(to:Uniforms.self, capacity:1)
    }
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        iRes=vec2(float(size.width),float(size.height))
    }
    func start(){
        for i in 0..<128{
            keyDown[char(UnicodeScalar(i)!)]=false
        }
        
        light = -vec3(2,2.5,3)
        uniforms[0].sky=vec3(0)
        camP=vec3(0,-1,5)
        cameraTransform=trans(camP)
        root.visible=false
        container.visible=false
        
        root.addLeaf(cursor)
        root.addLeaf(container)
        
        
        root.addLeaf(octahedron().setTransform(trans(100,-5,100)*scale(100.0)))
        
        
        
        portals=portal(trans(0,0,5)*rotz(0*PI/8)*scale(1,1,1))
        root.addLeaf(portals!.setTransform(rotx(0)*trans(0,0,1)*roty(-0*PI/2)))
//
//
//        let rb1=box(vec3(0,0,5),vec3(1),.specular)
//
//        var tet=tetrahedron()
//        tet.instanceUpdate={this in this.transform*=rotz(0.01) }
        
        
        var oc=octahedron().setMaterial(.glass).setTransform(trans(-1.5,0,3))

        root.addLeaf(oc)
        oc.instanceUpdate={this in this.transform*=roty(0.03) }
//
//        root.addLeaf(cone([15,0,0],[0,0,1]))
        
        //gound plane
        var p1=plane(vec3(0,-2,0),vec3(0,1,0))
        p1.color=vec3(0,1,0)
        root.addLeaf(p1)
        

//        root.addLeaf(sphere().setTransform(trans(2,3,0)*scale(1)).setMaterial(.emmisive))
//
//
//        let lens=sphere().setMaterial(.glass).setTransform(trans(2,-1,0)*scale(1,1,1))
//        lens.instanceUpdate={
//            $0.transform=trans(0,0.03*sin(self.uniforms[0].iTime/8),0)*$0.transform
//        }
//        root.addLeaf(lens)
//        root.addLeaf(sphere(vec3(-2,1,0),1).setMaterial(.diffuse))

        root.addLeaf(axis(trans(3,3,3)))

        let rb=box(vec3(0,0,-10),vec3(1),.specular)

        rb.addLeaf(box(vec3(+3,0,-3),vec3(1,2,1),.diffuse));
        rb.addLeaf(box(vec3(-3,0,-3),vec3(1,2,1),.diffuse));
        rb.addLeaf(box(vec3(+3,0,+3),vec3(1,2,1),.diffuse));
        rb.addLeaf(box(vec3(-3,0,+3),vec3(1,2,1),.diffuse));

        rb.addLeaf(box(vec3(0,3,0),vec3(4,1,4),.diffuse));
        root.addLeaf(rb)

        let s1=sphere(vec3(2.5,0,5),1)

        s1.material = .specular;
        //root.addLeaf(s1)

    }
    func update(){
        root.updateTree()
        let bottomLeft=vec2(float(globalwindow!.frame.minX),float(globalwindow!.frame.minY))
 
        frameCount+=1
        frameRate=1/(time()-uniforms[0].iTime)
        uniforms[0].iTime=time()
        uniforms[0].iMouse=iMouse-bottomLeft
        uniforms[0].iRes=iRes
        uniforms[0].light=normalize(light)
        
        
        
        
        
        
        //if(frameCount%20==0){print(cameraTransform.position())}
        
        if let p=portals{
            uniforms[0].p1Transform=p.transform.inverse
            uniforms[0].p1Inverse=p.transform
            uniforms[0].p2Transform=p.leafs[0].transform.inverse
            uniforms[0].p2Inverse=p.leafs[0].transform
//            if p.checkP1(cameraTransform) {
//                p.togglebounds(portal: 1, hidden: true)
//            }else{
//                p.togglebounds(portal: 1, hidden: false)
//            }
//            if p.checkP2(cameraTransform) {
//                p.togglebounds(portal: 0, hidden: true)
//            }else{
//                p.togglebounds(portal: 0, hidden: false)
//            }
            cameraTransform=p.teleport(cameraTransform)
        }
        controlls()
        
        cursor.transform=cameraTransform*viewTransform *
        trans(0,0,-bind!.zdist.wrappedValue)*scale(bind!.scale.wrappedValue)
        cursor.geometry=bind!.geo.wrappedValue
        cursor.material=bind!.mat.wrappedValue
        cursor.visible=bind!.on.wrappedValue
        
        
        var obj:[sceneObject]=[]
        root.load(&obj,id())
        uniforms[0].objNum=Int32(obj.count);
        memcpy(&uniforms[0].objs,&obj,obj.count*sizeof(sceneObject()))
    }
    func onLeftClick(){}
    func onRightClick(){}
    func onKeyPress(_ c:char){}
    func controlls(){
        let theta = map(uniforms[0].iMouse.x,0,iRes.x,-PI,PI);
        let phi = map(uniforms[0].iMouse.y,0,iRes.y,-PI/2,PI/2);
        let speed:float=0.1*20/frameRate
        
        //cameraTransform=trans(cameraTransform.position())
        viewTransform=roty(-theta)*rotx(phi);
        
        if(keyDown[char("a")]!){
            let d = +speed*vec3(-cos(theta),0,-sin(theta))
            cameraTransform=trans(m4v3(cameraTransform,d,false))*cameraTransform
        }
        if(keyDown[char("d")]!){
            let d = -speed*vec3(-cos(theta),0,-sin(theta))
            cameraTransform=trans(m4v3(cameraTransform,d,false))*cameraTransform
        }
        if(keyDown[char("w")]!){
            let d = -speed*vec3(-sin(theta),0,+cos(theta))
            cameraTransform=trans(m4v3(cameraTransform,d,false))*cameraTransform
        }
        if(keyDown[char("s")]!){
            let d = +speed*vec3(-sin(theta),0,+cos(theta))
            cameraTransform=trans(m4v3(cameraTransform,d,false))*cameraTransform
        }
        if(keyDown[char("e")]!){
            let d = +speed*vec3(0,1,0)
            cameraTransform=trans(m4v3(cameraTransform,d,false))*cameraTransform
        }
        if(keyDown[char("f")]!){
            let d = -speed*vec3(0,1,0)
            cameraTransform=trans(m4v3(cameraTransform,d,false))*cameraTransform
        }
        let zoomSpeed:float=0.5/frameRate
        if(keyDown[char("x")]!){
            zoom+=zoomSpeed
        }
        if(keyDown[char("z")]!){
            zoom-=zoomSpeed
            zoom=max(zoom,0)
        }
        if(keyDown[char(" ")]!){
            let copy=gameObject(cursor)
            container.addLeaf(copy)
        }
        uniforms[0].zoom=zoom
        uniforms[0].cameraTransform=cameraTransform
        uniforms[0].viewTransform=viewTransform
    }
}

