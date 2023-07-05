//
//  ViewController.swift
//  MetalShapeViews
//
//  Created by Caner Ergin on 5.07.2023.
//

import UIKit
import MetalKit

let sharedDevice: MTLDevice = MTLCreateSystemDefaultDevice()!
let sharedPixelFormat: MTLPixelFormat = .bgra8Unorm

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.view.addSubview(theScene)
        theScene.frame = CGRect(x: 50, y: 150, width: 300, height: 500)
        
        theScene.clearColor = MTLClearColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1.0)
        
        theScene.delegate = renderer
    }
    
    var renderer: Renderer = Renderer()
    
    var theScene: Scene = Scene(frame: .zero, device: sharedDevice)


}

class Scene: MTKView {
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class Renderer: NSObject, MTKViewDelegate {
    
    var commandQueue: MTLCommandQueue!
    var renderPipelineState: MTLRenderPipelineState!
    
    override init() {
        super.init()
        commandQueue = sharedDevice.makeCommandQueue()!
        createPipelineState()
        createBuffers()
    }
    
    func createPipelineState() {
        let lib = sharedDevice.makeDefaultLibrary()!
        let vertexFunction = lib.makeFunction(name: "basic_vertex_shader")
        let fragmentFunction = lib.makeFunction(name: "basic_fragment_shader")
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = sharedPixelFormat
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        
        do {
            renderPipelineState = try sharedDevice.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            print("renderPipelineState creation error \(error)")
        }
    }
    
    // Data
    let offset: Float = 0.9
    lazy var vertices: [SIMD3<Float>] = [
        .init( 0, offset, 0),
        .init(-offset,-offset, 0),
        .init( offset,-offset, 0)
    ]
    
    var vertexBuffer: MTLBuffer!
    
    func createBuffers() {
        vertexBuffer = sharedDevice.makeBuffer(bytes: vertices,
                                               length: MemoryLayout<SIMD3<Float>>.stride * vertices.count)
    }
    
    /// Render
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        //
    }
    
    func draw(in view: MTKView) {
        //
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor
        else { return }
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        let renderCommandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderCommandEncoder?.setRenderPipelineState(renderPipelineState)
        
        renderCommandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        renderCommandEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
        renderCommandEncoder?.endEncoding()
        
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
        
    }
}
