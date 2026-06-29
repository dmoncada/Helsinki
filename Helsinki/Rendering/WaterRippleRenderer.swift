//
//  WaterRippleRenderer.swift
//  Helsinki
//
//  Owns the Metal device, pipelines, ping-pong simulation textures and the
//  artwork texture, and encodes the per-frame passes that drive the water
//  ripple effect. Mirrors the Three.js sim's per-frame flow: inject drops →
//  step the wave field (×2) → recompute normals → refract & display.
//

import MetalKit
import simd

/// Simulation tunables. Memory layout matches the Metal `WaterParams` struct.
struct WaterParams {
  var damping: Float
  var speed: Float
  var refractionStrength: Float
  var gridSize: UInt32
}

/// A single ripple excitation. Memory layout matches the Metal `Drop` struct.
struct Drop {
  var center: SIMD2<Float>
  var radius: Float
  var strength: Float
}

/// Renders the water ripple effect into an `MTKView`. The class is
/// MainActor-isolated (the project uses Main Actor default isolation), and
/// `MTKView` delivers `draw(in:)` on the main actor, so the pending-drops
/// buffer needs no extra locking.
final class WaterRippleRenderer: NSObject, MTKViewDelegate {
  /// The Metal device, exposed so the view representable can configure the
  /// `MTKView` with the same device.
  let device: MTLDevice

  private let commandQueue: MTLCommandQueue
  private let injectPipeline: MTLComputePipelineState
  private let stepPipeline: MTLComputePipelineState
  private let normalsPipeline: MTLComputePipelineState
  private let displayPipeline: MTLRenderPipelineState
  private let sampler: MTLSamplerState

  private var stateA: MTLTexture
  private var stateB: MTLTexture
  private var artwork: MTLTexture?

  private var params: WaterParams
  private let gridSize: Int
  private let stepsPerFrame = 2

  /// Drops queued since the last frame. Drained each `draw(in:)`.
  private var pendingDrops: [Drop] = []
  private let maxQueuedDrops = 64

  init?(gridSize: Int = 256) {
    guard
      let device = MTLCreateSystemDefaultDevice(),
      let commandQueue = device.makeCommandQueue(),
      let library = try? device.makeDefaultLibrary(bundle: .main)
    else { return nil }

    func computePipeline(_ name: String) -> MTLComputePipelineState? {
      guard let function = library.makeFunction(name: name)
      else { return nil }
      return try? device.makeComputePipelineState(function: function)
    }

    guard
      let inject = computePipeline("injectDrops"),
      let step = computePipeline("stepWave"),
      let normals = computePipeline("computeNormals"),
      let vertexFunction = library.makeFunction(name: "fsRefractVertex"),
      let fragmentFunction = library.makeFunction(name: "fsRefractFragment")
    else { return nil }

    let renderDescriptor = MTLRenderPipelineDescriptor()
    renderDescriptor.vertexFunction = vertexFunction
    renderDescriptor.fragmentFunction = fragmentFunction
    renderDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    guard let display = try? device.makeRenderPipelineState(descriptor: renderDescriptor)
    else { return nil }

    let samplerDescriptor = MTLSamplerDescriptor()
    samplerDescriptor.minFilter = .linear
    samplerDescriptor.magFilter = .linear
    samplerDescriptor.sAddressMode = .clampToEdge
    samplerDescriptor.tAddressMode = .clampToEdge
    guard let sampler = device.makeSamplerState(descriptor: samplerDescriptor)
    else { return nil }

    guard
      let stateA = Self.makeStateTexture(device: device, size: gridSize),
      let stateB = Self.makeStateTexture(device: device, size: gridSize)
    else { return nil }

    self.device = device
    self.commandQueue = commandQueue
    self.injectPipeline = inject
    self.stepPipeline = step
    self.normalsPipeline = normals
    self.displayPipeline = display
    self.sampler = sampler
    self.stateA = stateA
    self.stateB = stateB
    self.gridSize = gridSize
    self.params = WaterParams(
      damping: 0.995,
      speed: 2.0,
      refractionStrength: 0.10,
      gridSize: UInt32(gridSize)
    )
    super.init()
  }

  // MARK: - Public API

  /// Loads the artwork to refract from prefetched image bytes.
  func loadArtwork(from data: Data) async {
    do {
      let loader = MTKTextureLoader(device: device)
      let texture = try await loader.newTexture(
        data: data,
        options: [
          .SRGB: false,
          .origin: MTKTextureLoader.Origin.topLeft,
          .generateMipmaps: false
        ]
      )
      artwork = texture
    } catch {
      print("WaterRippleRenderer: failed to load artwork — \(error)")
    }
  }

  /// Queues a ripple at a normalized point (top-left origin, [0,1]).
  func enqueueDrop(at point: SIMD2<Float>, radius: Float = 0.03, strength: Float = 0.5) {
    guard pendingDrops.count < maxQueuedDrops else { return }
    let clamped = simd_clamp(point, SIMD2(repeating: 0), SIMD2(repeating: 1))
    pendingDrops.append(Drop(center: clamped, radius: radius, strength: strength))
  }

  // MARK: - MTKViewDelegate

  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

  func draw(in view: MTKView) {
    guard
      let artwork,
      let drawable = view.currentDrawable,
      let renderPass = view.currentRenderPassDescriptor,
      let commandBuffer = commandQueue.makeCommandBuffer()
    else { return }

    let threadsPerGroup = MTLSize(width: 16, height: 16, depth: 1)
    let groups = MTLSize(
      width: (gridSize + 15) / 16,
      height: (gridSize + 15) / 16,
      depth: 1
    )

    // 1. Inject any queued drops.
    if pendingDrops.count > 0 {
      encodeCompute(
        in: commandBuffer,
        pipeline: injectPipeline,
        groups: groups,
        threadsPerGroup: threadsPerGroup
      ) { encoder in
        encoder.setTexture(stateA, index: 0)
        encoder.setTexture(stateB, index: 1)
        encoder.setBytes(
          pendingDrops, length: MemoryLayout<Drop>.stride * pendingDrops.count, index: 0)
        var count = UInt32(pendingDrops.count)
        encoder.setBytes(&count, length: MemoryLayout<UInt32>.stride, index: 1)
        encoder.setBytes(&params, length: MemoryLayout<WaterParams>.stride, index: 2)
      }
      swap(&stateA, &stateB)
      pendingDrops.removeAll(keepingCapacity: true)
    }

    // 2. Step the wave field twice for faster propagation.
    for _ in 0 ..< stepsPerFrame {
      encodeCompute(
        in: commandBuffer, pipeline: stepPipeline, groups: groups, threadsPerGroup: threadsPerGroup
      ) { encoder in
        encoder.setTexture(stateA, index: 0)
        encoder.setTexture(stateB, index: 1)
        encoder.setBytes(&params, length: MemoryLayout<WaterParams>.stride, index: 0)
      }
      swap(&stateA, &stateB)
    }

    // 3. Recompute normals from the height gradient.
    encodeCompute(
      in: commandBuffer, pipeline: normalsPipeline, groups: groups, threadsPerGroup: threadsPerGroup
    ) { encoder in
      encoder.setTexture(stateA, index: 0)
      encoder.setTexture(stateB, index: 1)
      encoder.setBytes(&params, length: MemoryLayout<WaterParams>.stride, index: 0)
    }
    swap(&stateA, &stateB)

    // 4. Refract the artwork and present.
    if let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass) {
      encoder.setRenderPipelineState(displayPipeline)
      encoder.setFragmentTexture(stateA, index: 0)
      encoder.setFragmentTexture(artwork, index: 1)
      encoder.setFragmentBytes(&params, length: MemoryLayout<WaterParams>.stride, index: 0)
      encoder.setFragmentSamplerState(sampler, index: 0)
      encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
      encoder.endEncoding()
    }

    commandBuffer.present(drawable)
    commandBuffer.commit()
  }

  // MARK: - Helpers

  private func encodeCompute(
    in commandBuffer: MTLCommandBuffer,
    pipeline: MTLComputePipelineState,
    groups: MTLSize,
    threadsPerGroup: MTLSize,
    configure: (MTLComputeCommandEncoder) -> Void
  ) {
    guard let encoder = commandBuffer.makeComputeCommandEncoder()
    else { return }
    encoder.setComputePipelineState(pipeline)
    configure(encoder)
    encoder.dispatchThreadgroups(groups, threadsPerThreadgroup: threadsPerGroup)
    encoder.endEncoding()
  }

  private static func makeStateTexture(device: MTLDevice, size: Int) -> MTLTexture? {
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(
      pixelFormat: .rgba16Float,
      width: size,
      height: size,
      mipmapped: false
    )
    descriptor.usage = [.shaderRead, .shaderWrite]
    descriptor.storageMode = .shared
    guard let texture = device.makeTexture(descriptor: descriptor)
    else { return nil }

    // Zero the field so it starts perfectly flat.
    let bytesPerRow = size * 4 * MemoryLayout<Float16>.stride
    let zeros = [UInt8](repeating: 0, count: bytesPerRow * size)
    texture.replace(
      region: MTLRegionMake2D(0, 0, size, size),
      mipmapLevel: 0,
      withBytes: zeros,
      bytesPerRow: bytesPerRow
    )
    return texture
  }
}
