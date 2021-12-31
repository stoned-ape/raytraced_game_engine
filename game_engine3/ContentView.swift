//
//  ContentView.swift
//  game_engine3
//
//  Created by Apple1 on 4/6/21.
//

import SwiftUI
import MetalKit


enum Material:string,CaseIterable{
    case diffuse  = "diffuse"
    case specular = "specular"
    case glass    = "glass"
    case portal1  = "portal1"
    case portal2  = "portal2"
    case screen   = "screen"
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



struct bindings{
    var geo:Binding<Geometry>
    var mat:Binding<Material>
    var on :Binding<bool>
    var zdist:Binding<float>
    var scale:Binding<float>
}

struct ContentView:View{
    @State private var geo=Geometry.sphere
    @State private var mat=Material.diffuse
    @State private var on=false
    @State private var zdist:float=7
    @State private var scale:float=1
    var body:some View{
        VStack{
            gameview(bind:bindings(geo:$geo,mat:$mat,on:$on,zdist:$zdist,scale:$scale))
#if os(OSX)
            HStack{
                Spacer()
                VStack{
                    Slider(value: $zdist, in: 1...10){Text("z-dist")}
                    Slider(value: $scale, in: 0...2){Text("scale")}
                }
                VStack{
                    Picker("geometry:", selection: $geo){
                        ForEach(Geometry.allCases,id:\.self){
                            Text($0.rawValue).tag($0)
                        }
                    }
                    Picker("material:", selection: $mat){
                        ForEach(Material.allCases,id:\.self){
                            Text($0.rawValue).tag($0)
                        }
                    }
                }
                Spacer()
            }
#endif
        }
    }
}

#if os(OSX)
struct gameview:NSViewRepresentable{
    let mtkview=MTKView()
    var del=Renderer()
    var mouseLocation: NSPoint { NSEvent.mouseLocation }
    var bind:bindings
    func makeNSView(context: Context)->some NSView{
        mtkview.delegate=del
        mtkview.device=del.device
        mtkview.framebufferOnly=false
        set_handlers()
        del.bind=bind
        return mtkview
    }
    func updateNSView(_ uiView: NSViewType, context: Context){}
    
    func set_handlers(){
        //detect mouse position
        NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) {
            self.del.iMouse=vec2(float(self.mouseLocation.x),float(self.mouseLocation.y))
            return $0
        }
        //detect key press
        NSEvent.addLocalMonitorForEvents(matching: [.keyDown]){
            self.del.keyDown[char($0.characters!)]=true
            self.del.onKeyPress(char($0.characters!))
            return $0
        }
        NSEvent.addLocalMonitorForEvents(matching: [.keyUp]){
            self.del.keyDown[char($0.characters!)]=false
            return $0
        }
        //detect mouse press
        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]){
            self.del.onLeftClick()
            self.del.leftMouseDown=true
            return $0
        }
        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseUp]){
            self.del.leftMouseDown=false
            return $0
        }
        NSEvent.addLocalMonitorForEvents(matching: [.rightMouseDown]){
            self.del.onRightClick()
            self.del.rightMouseDown=true
            return $0
        }
        NSEvent.addLocalMonitorForEvents(matching: [.rightMouseUp]){
            self.del.rightMouseDown=false
            return $0
        }
        
    }
}

#elseif os(iOS)

struct gameview:UIViewRepresentable{
    let mtkview=MTKView()
    var del=Renderer()
    //var mouseLocation: UIPoint { NSEvent.mouseLocation }
    var bind:bindings
    func makeUIView(context: Context)->some UIView{
        mtkview.delegate=del
        mtkview.device=del.device
        mtkview.framebufferOnly=false
        set_handlers()
        del.bind=bind
        return mtkview
    }
    func updateUIView(_ uiView: UIViewType, context: Context){}
    
    func set_handlers(){
        
    }
}


#endif


