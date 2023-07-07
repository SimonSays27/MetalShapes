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
    }
    
    var renderer: Renderer = Renderer()
    
    lazy var theScene: Scene = {
        let frame = CGRect(x: 50, y: 200, width: 300, height: 500)
        let v = Scene(frame: frame, device: sharedDevice)
        v.enableSetNeedsDisplay = true
        v.delegate = renderer
        v.addGestureRecognizer(panGesture)
        return v
    }()

    // Gesture
    lazy var panGesture: UIPanGestureRecognizer = {
        return UIPanGestureRecognizer(target: self, action: #selector(panHandler(_:)))
    }()
    @objc func panHandler(_ g: UIPanGestureRecognizer) {
        //
        
        let translation = g.translation(in: theScene)

        renderer.center.x = Float(translation.x / 150)
        renderer.center.y = -Float(translation.y / 250)
        
        renderer.createBuffers()
        
        theScene.setNeedsDisplay()
    }
    
}

class Scene: MTKView {
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        self.enableSetNeedsDisplay = true
        self.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0) // MTLClearColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1.0)
        self.isOpaque = false
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
    var center: SIMD2<Float> = .init(0, 0)
    let offset: Float = 0.9
    var vertices: [SIMD3<Float>] { [
        .init(center.x          , center.y + offset , 0),
        .init(center.x - offset , center.y - offset , 0),
        .init(center.x + offset , center.y          , 0)
    ] }
    
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
