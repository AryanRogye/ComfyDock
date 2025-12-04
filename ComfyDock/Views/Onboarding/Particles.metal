//
//  Particles.metal
//  MacOS_Onboarding
//
//  Created by Aryan Rogye on 11/5/25.
//

#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float  time;
    float2 size;
    uint   count;
    float  baseScale;
    float  speed;
};

struct VSOut {
    float4 position [[position]];
    float  pointSize [[point_size]];
    float4 color;
    float2 uv; // for soft round sprite
};

vertex VSOut vs_particles(uint vid [[vertex_id]],
                          constant Uniforms& u [[buffer(0)]]) {
    float rel = (float)vid / max(1.0, (float)u.count);
    
    float radius = min(u.size.x, u.size.y) * 0.45;
    float angle  = u.time * u.speed + rel * M_PI_F * 4.0;
    
    float x = sin(angle) * radius + u.size.x * 0.5;
    float y = cos(angle * 0.5) * radius + u.size.y * 0.5;
    
    float2 ndc = float2((x / u.size.x) * 2.0 - 1.0,
                        1.0 - (y / u.size.y) * 2.0);
    
    // SPAWN/FADE LOGIC - particles appear and disappear cyclically
    float lifecycle = fract(u.time * u.speed * 0.3 + rel); // 0 to 1 cycle
    
    float opacity;
    if (lifecycle < 0.1) {
        // Fade IN (10%)
        opacity = lifecycle / 0.1;
    } else if (lifecycle < 0.4) {
        // Fully visible (30%)
        opacity = 1.0;
    } else if (lifecycle < 0.5) {
        // Fade OUT (10%)
        opacity = (0.5 - lifecycle) / 0.1;
    } else {
        // INVISIBLE (50%)
        opacity = 0.0;
    }
    
    float scale = u.baseScale + sin(u.time * 2.0 + rel * M_PI_F) * 2.0;
    
    VSOut o;
    o.position  = float4(ndc, 0, 1);
    o.pointSize = max(1.0, scale);
    o.color     = float4(1, 1, 1, opacity);
    o.uv        = float2(0.0);
    return o;
}

fragment float4 fs_particles(VSOut in [[stage_in]],
                             float2 pointCoord [[point_coord]]) {
    // Distance from center of the point sprite
    float2 coord = pointCoord * 2.0 - 1.0;
    float dist = length(coord);
    
    // Soft fade-out from center to edge (creates the glow)
    float alpha = 1.0 - smoothstep(0.0, 1.0, dist);
    
    // Extra soft - makes it super ethereal
    alpha = pow(alpha, 2.5);
    
    // Combine with your existing opacity
    float4 color = in.color;
    color.a *= alpha;
    
    return color;
}
