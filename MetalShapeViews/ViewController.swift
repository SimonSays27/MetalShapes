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
        
        theScene.transform = CGAffineTransform(scaleX: 3, y: 3)
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
        // TBD
        let center = g.location(in: theScene)

        renderer.selfRect.x = Float(center.x) - 50;
        renderer.selfRect.y = Float(center.y) - 50;

        theScene.setNeedsDisplay()
    }
    
}

class Scene: MTKView {
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        self.enableSetNeedsDisplay = true
        self.clearColor = MTLClearColor(red: 0, green: 0.1, blue: 0.1, alpha: 0.1) // MTLClearColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1.0)
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
        descriptor.colorAttachments[0].isBlendingEnabled = true
        
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha

        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        
        do {
            renderPipelineState = try sharedDevice.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            print("renderPipelineState creation error \(error)")
        }
    }
    
    // Data
    var quadVertices: [SIMD2<Float>] = [
        .init(-1,-1),
        .init( 1,-1),
        .init( 1, 1),
        .init( 1, 1),
        .init(-1, 1),
        .init(-1,-1)
    ]
    
    var canvasRect: SIMD4<Float> = .init(0, 0, 300, 500)
    
    var selfRect: SIMD4<Float> = .init(150, 150, 100, 100)

    
    var vertexBuffer: MTLBuffer!
    
    func createBuffers() {
        vertexBuffer = sharedDevice.makeBuffer(bytes: quadVertices,
                                               length: MemoryLayout<SIMD2<Float>>.stride * quadVertices.count)
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
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else { return }
                
        renderCommandEncoder.setRenderPipelineState(renderPipelineState)
        
        renderCommandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        renderCommandEncoder.setVertexBytes(&canvasRect, length: MemoryLayout<SIMD4<Float>>.stride, index: 1)
        renderCommandEncoder.setVertexBytes(&selfRect, length: MemoryLayout<SIMD4<Float>>.stride, index: 2)
        
        renderCommandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: quadVertices.count)
        renderCommandEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
    }
}
