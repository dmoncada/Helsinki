//
//  WaterRipple.metal
//  Helsinki
//
//  GPU height-field wave simulation + 2D refraction of the artwork.
//  Technique ported from the Three.js WebGL Water sim (Water.ts /
//  WaveSimulation.frag): a ping-pong height/velocity field solved with a
//  4-neighbour Laplacian wave equation, normals from the height gradient,
//  then a final pass that refracts the artwork by the surface normal.
//
//  State texture packing (rgba16Float): R = height, G = velocity,
//  B = normal.x, A = normal.y.
//

#include <metal_stdlib>
using namespace metal;

/// Simulation tunables, shared 1:1 with the Swift `WaterParams` struct.
struct WaterParams {
    float damping;            // velocity damping per step (e.g. 0.995)
    float speed;              // wave-speed factor (e.g. 2.0)
    float refractionStrength; // how far the normal nudges the artwork UV
    uint  gridSize;           // simulation grid resolution (square)
};

/// A single ripple excitation, shared 1:1 with the Swift `Drop` struct.
struct Drop {
    float2 center;   // normalized [0,1], top-left origin
    float  radius;   // normalized
    float  strength; // peak height added at the center
};

// Clamp an integer texel coordinate to the texture bounds (clamp-to-edge,
// matching the Three.js sim's stable boundaries).
static inline uint2 clampCoord(int2 c, uint w, uint h) {
    return uint2(clamp(c, int2(0), int2(int(w) - 1, int(h) - 1)));
}

/// Inject all pending drops into the height channel using a raised-cosine
/// (Hann) profile: 1 at the center, smoothly decaying to 0 at the radius.
kernel void injectDrops(texture2d<float, access::read>  src       [[texture(0)]],
                        texture2d<float, access::write> dst       [[texture(1)]],
                        constant Drop*        drops               [[buffer(0)]],
                        constant uint&        dropCount           [[buffer(1)]],
                        constant WaterParams& params              [[buffer(2)]],
                        uint2 gid [[thread_position_in_grid]]) {
    const uint w = src.get_width();
    const uint h = src.get_height();
    if (gid.x >= w || gid.y >= h) { return; }

    float4 s = src.read(gid);
    const float2 uv = (float2(gid) + 0.5) / float2(params.gridSize, params.gridSize);

    float added = 0.0;
    for (uint i = 0; i < dropCount; ++i) {
        const Drop d = drops[i];
        const float dist = distance(uv, d.center);
        if (dist < d.radius) {
            added += d.strength * 0.5 * (cos(dist / d.radius * M_PI_F) + 1.0);
        }
    }
    s.r += added;
    dst.write(s, gid);
}

/// Advance the wave field one step. Discrete wave equation: velocity is
/// accelerated toward the 4-neighbour average height, damped, then
/// integrated into height. Normals are left untouched (recomputed later).
kernel void stepWave(texture2d<float, access::read>  src      [[texture(0)]],
                     texture2d<float, access::write> dst      [[texture(1)]],
                     constant WaterParams& params             [[buffer(0)]],
                     uint2 gid [[thread_position_in_grid]]) {
    const uint w = src.get_width();
    const uint h = src.get_height();
    if (gid.x >= w || gid.y >= h) { return; }

    const float4 s = src.read(gid);
    float height = s.r;
    float velocity = s.g;

    const int2 g = int2(gid);
    const float hl = src.read(clampCoord(g + int2(-1, 0), w, h)).r;
    const float hr = src.read(clampCoord(g + int2( 1, 0), w, h)).r;
    const float hu = src.read(clampCoord(g + int2( 0, -1), w, h)).r;
    const float hd = src.read(clampCoord(g + int2( 0,  1), w, h)).r;

    const float average = (hl + hr + hu + hd) * 0.25;
    velocity += (average - height) * params.speed;
    velocity *= params.damping;
    height += velocity;

    dst.write(float4(height, velocity, s.b, s.a), gid);
}

/// Recompute surface normals from the height gradient and store them in
/// B/A. Stored as the in-plane gradient (x/y); this is what the display
/// pass uses to refract the artwork.
kernel void computeNormals(texture2d<float, access::read>  src   [[texture(0)]],
                           texture2d<float, access::write> dst   [[texture(1)]],
                           constant WaterParams& params          [[buffer(0)]],
                           uint2 gid [[thread_position_in_grid]]) {
    const uint w = src.get_width();
    const uint h = src.get_height();
    if (gid.x >= w || gid.y >= h) { return; }

    const float4 s = src.read(gid);
    const int2 g = int2(gid);
    const float hl = src.read(clampCoord(g + int2(-1, 0), w, h)).r;
    const float hr = src.read(clampCoord(g + int2( 1, 0), w, h)).r;
    const float hu = src.read(clampCoord(g + int2( 0, -1), w, h)).r;
    const float hd = src.read(clampCoord(g + int2( 0,  1), w, h)).r;

    const float nx = hl - hr;
    const float ny = hu - hd;
    dst.write(float4(s.r, s.g, nx, ny), gid);
}

// MARK: - Display pass

struct VSOut {
    float4 position [[position]];
    float2 uv;
};

/// Full-screen triangle. UV uses a top-left origin (y-down) so it lines up
/// with both the artwork texture and the simulation grid.
vertex VSOut fsRefractVertex(uint vid [[vertex_id]]) {
    const float2 p = float2((vid << 1) & 2, vid & 2); // (0,0) (2,0) (0,2)
    VSOut out;
    out.position = float4(p * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
    out.uv = p;
    return out;
}

/// Sample the surface normal and offset the artwork lookup by it, producing
/// the "looking through rippling water" refraction.
fragment float4 fsRefractFragment(VSOut in [[stage_in]],
                                  texture2d<float> state   [[texture(0)]],
                                  texture2d<float> artwork [[texture(1)]],
                                  constant WaterParams& params [[buffer(0)]],
                                  sampler samp [[sampler(0)]]) {
    const float2 normal = state.sample(samp, in.uv).ba;
    const float2 uv = in.uv + normal * params.refractionStrength;
    return artwork.sample(samp, uv);
}
