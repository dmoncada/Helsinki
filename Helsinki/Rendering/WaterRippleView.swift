//
//  WaterRippleView.swift
//  Helsinki
//
//  SwiftUI layer for the water ripple effect: an observable model that owns
//  the renderer and maps gestures to drops, a thin cross-platform MTKView
//  representable, and the public `WaterRippleSurface` component.
//

import MetalKit
import SwiftUI

#if os(iOS)
  typealias PlatformViewRepresentable = UIViewRepresentable
#else
  typealias PlatformViewRepresentable = NSViewRepresentable
#endif

/// Owns the renderer and translates SwiftUI gestures into ripple drops.
@Observable
final class RippleModel {
  let renderer: WaterRippleRenderer?

  /// Current size of the surface view, used to normalize gesture points.
  var viewSize: CGSize = .zero

  /// Last drop location, for throttling so dragging doesn't flood the queue.
  private var lastDropPoint: SIMD2<Float>?

  init() {
    renderer = WaterRippleRenderer()
  }

  func loadArtwork(from url: URL) async {
    await renderer?.loadArtwork(from: url)
  }

  /// Handles a tap/drag at a point in the view's local coordinate space.
  func excite(at point: CGPoint) {
    guard viewSize.width > 0, viewSize.height > 0 else { return }
    let uv = SIMD2<Float>(
      Float(point.x / viewSize.width),
      Float(point.y / viewSize.height)
    )

    // Throttle: only inject after moving roughly one grid texel.
    if let last = lastDropPoint, simd_distance(last, uv) < (1.0 / 256.0) {
      return
    }
    lastDropPoint = uv
    renderer?.enqueueDrop(at: uv)
  }

  func endExcitation() {
    lastDropPoint = nil
  }

  /// Whether a point in the view's local space falls inside the circular
  /// surface, used to decide if a released drag counts as a trigger.
  func isInsideCircle(_ point: CGPoint) -> Bool {
    guard viewSize.width > 0, viewSize.height > 0 else { return false }
    let radius = min(viewSize.width, viewSize.height) / 2
    let dx = point.x - viewSize.width / 2
    let dy = point.y - viewSize.height / 2
    return (dx * dx + dy * dy) <= radius * radius
  }
}

/// Cross-platform wrapper around an `MTKView` driven by the renderer.
struct MetalRippleView: PlatformViewRepresentable {
  let renderer: WaterRippleRenderer

  private func makeMetalView() -> MTKView {
    let view = MTKView()
    view.device = renderer.device
    view.delegate = renderer
    view.colorPixelFormat = .bgra8Unorm
    view.framebufferOnly = true
    view.preferredFramesPerSecond = 120
    view.clearColor = MTLClearColorMake(0, 0, 0, 0)
    view.enableSetNeedsDisplay = false
    view.isPaused = false
    #if os(iOS)
      view.isOpaque = false
    #else
      view.layer?.isOpaque = false
    #endif
    return view
  }

  #if os(iOS)
    func makeUIView(context: Context) -> MTKView { makeMetalView() }
    func updateUIView(_ uiView: MTKView, context: Context) {}
  #else
    func makeNSView(context: Context) -> MTKView { makeMetalView() }
    func updateNSView(_ nsView: MTKView, context: Context) {}
  #endif
}

/// A circular surface that refracts `artworkURL` like rippling water. Tap or
/// drag (touch on iOS, mouse on macOS) to excite the surface.
struct WaterRippleSurface: View {
  let artworkUrl: URL

  /// Fired when the surface is released — on a tap-up anywhere in the circle,
  /// or when a drag ends. Lets the host treat the whole circle as a button.
  var onTrigger: () -> Void = {}

  @State private var model = RippleModel()

  var body: some View {
    Group {
      if let renderer = model.renderer {
        MetalRippleView(renderer: renderer)
      } else {
        // Metal unavailable: fall back to a static placeholder.
        Color.secondary
      }
    }
    .onGeometryChange(for: CGSize.self) { proxy in
      proxy.size
    } action: { newSize in
      model.viewSize = newSize
    }
    .aspectRatio(1, contentMode: .fit)
    .clipShape(.circle)
    .contentShape(.circle)
    .gesture(
      DragGesture(minimumDistance: 0)
        .onChanged { value in model.excite(at: value.location) }
        .onEnded { value in
          model.endExcitation()
          // Only trigger if the drag was released inside the circle.
          if model.isInsideCircle(value.location) {
            onTrigger()
          }
        }
    )
    .task(id: artworkUrl) {
      await model.loadArtwork(from: artworkUrl)
    }
  }
}
