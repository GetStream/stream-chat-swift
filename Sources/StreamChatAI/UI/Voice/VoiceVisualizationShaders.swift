//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// The Metal source of the voice visualizations, compiled when the app first shows one, so
// building the SDK needs no Metal toolchain.
//
// It is ported from the GLSL of the web reference
// (github.com/GetStream/stream-voice-agent-demo, `app/components/visualizations/shaders.ts`),
// and the math is kept line for line so both render alike. What differs is what GLSL and MSL
// disagree on:
// - Metal's fragment origin is the top left, so `coords()` flips y back up.
// - GLSL's `mod` floors and MSL's `fmod` truncates, so the noise uses `glslMod`.
// - `pow` of a negative base is NaN in Metal, so squares are written as `sq`.
// - `smoothstep` with its edges reversed is undefined, so every one is `ss`, the formula WebGL
//   drivers evaluate either way round.
//
// Colors arrive as HSV, hue a fraction of a turn, and leave premultiplied, so the halo melts
// into whatever is behind the view.
enum VoiceVisualizationShaders {
    static let source = """
    #include <metal_stdlib>
    using namespace metal;

    // Mirrors VoiceVisualizationUniforms, field for field.
    struct VoiceUniforms {
        float4 col0;
        float4 col1;
        float4 col2;
        float4 col3;
        float4 col4;
        float2 resolution;
        float2 tap;
        float2 hover;
        float time;
        float count;
        float bright;
        float sat;
        float load;
        float flow;
        float flowSpin;
        float orbSpin;
        float react;
        float expressivity;
        float dark;
        float tapTime;
        float hoverAmt;
        float mic;
        float voice;
        float scale;
    };

    struct VoiceVertexOut {
        float4 position [[position]];
    };

    vertex VoiceVertexOut voiceVisualizationVertex(uint vertexID [[vertex_id]]) {
        const float2 positions[3] = { float2(-1.0, -1.0), float2(3.0, -1.0), float2(-1.0, 3.0) };
        VoiceVertexOut out;
        out.position = float4(positions[vertexID], 0.0, 1.0);
        return out;
    }

    static float glslMod(float x, float y) { return x - y * floor(x / y); }
    static float3 glslMod(float3 x, float y) { return x - y * floor(x / y); }
    static float4 glslMod(float4 x, float y) { return x - y * floor(x / y); }

    static float sq(float x) { return x * x; }

    static float ss(float edge0, float edge1, float x) {
        float t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
        return t * t * (3.0 - 2.0 * t);
    }

    static float3 hsv2rgb(float3 c) {
        float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
        float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
        return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
    }

    static float3 desat(float3 c, float s) {
        float l = dot(c, float3(0.299, 0.587, 0.114));
        return mix(float3(l), c, s);
    }

    static float3 saturate3(float3 c, float s) {
        float l = dot(c, float3(0.299, 0.587, 0.114));
        return clamp(mix(float3(l), c, s), 0.0, 1.0);
    }

    // GLSL's mat2(c, -s, s, c) * p, written out.
    static float2 rot2(float2 p, float a) {
        float s = sin(a), c = cos(a);
        return float2(c * p.x + s * p.y, -s * p.x + c * p.y);
    }

    // The chosen color as is; dark mode lifts saturation a touch so it stays vivid on black.
    static float3 vivid(float4 hsv, float dark) {
        return hsv2rgb(float3(hsv.x, clamp(hsv.y + dark * 0.06, 0.0, 1.0), hsv.z));
    }

    // Waves spreading out from the last tap, fading within a second and a half.
    static float tapRipple(float2 p, constant VoiceUniforms &u) {
        float age = u.tapTime;
        if (age > 1.5) return 0.0;
        float d = distance(p, u.tap);
        float front = age * 0.75;
        float env = exp(-sq((d - front) / 0.14));
        float decay = exp(-age * 2.6);
        return sin(d * 34.0 - age * 24.0) * env * decay;
    }

    // A gentle ripple following a hovering pointer.
    static float hoverRipple(float2 p, constant VoiceUniforms &u) {
        if (u.hoverAmt <= 0.001) return 0.0;
        float d = distance(p, u.hover);
        float env = exp(-sq(d / 0.22));
        return sin(d * 30.0 - u.time * 7.0) * env * u.hoverAmt * 0.6;
    }

    static float poke(float2 p, constant VoiceUniforms &u) {
        return tapRipple(p, u) + hoverRipple(p, u);
    }

    // Ashima / Stefan Gustavson 3D simplex noise.
    static float4 permute(float4 x) { return glslMod(((x * 34.0) + 1.0) * x, 289.0); }
    static float4 taylorInvSqrt(float4 r) { return 1.79284291400159 - 0.85373472095314 * r; }

    static float snoise(float3 v) {
        const float2 C = float2(1.0 / 6.0, 1.0 / 3.0);
        const float4 D = float4(0.0, 0.5, 1.0, 2.0);
        float3 i = floor(v + dot(v, C.yyy));
        float3 x0 = v - i + dot(i, C.xxx);
        float3 g = step(x0.yzx, x0.xyz);
        float3 l = 1.0 - g;
        float3 i1 = min(g.xyz, l.zxy);
        float3 i2 = max(g.xyz, l.zxy);
        float3 x1 = x0 - i1 + 1.0 * C.xxx;
        float3 x2 = x0 - i2 + 2.0 * C.xxx;
        float3 x3 = x0 - 1.0 + 3.0 * C.xxx;
        i = glslMod(i, 289.0);
        float4 p = permute(permute(permute(
                    i.z + float4(0.0, i1.z, i2.z, 1.0))
                  + i.y + float4(0.0, i1.y, i2.y, 1.0))
                  + i.x + float4(0.0, i1.x, i2.x, 1.0));
        float n_ = 1.0 / 7.0;
        float3 ns = n_ * D.wyz - D.xzx;
        float4 j = p - 49.0 * floor(p * ns.z * ns.z);
        float4 x_ = floor(j * ns.z);
        float4 y_ = floor(j - 7.0 * x_);
        float4 x = x_ * ns.x + ns.yyyy;
        float4 y = y_ * ns.x + ns.yyyy;
        float4 h = 1.0 - abs(x) - abs(y);
        float4 b0 = float4(x.xy, y.xy);
        float4 b1 = float4(x.zw, y.zw);
        float4 s0 = floor(b0) * 2.0 + 1.0;
        float4 s1 = floor(b1) * 2.0 + 1.0;
        float4 sh = -step(h, float4(0.0));
        float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
        float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
        float3 p0 = float3(a0.xy, h.x);
        float3 p1 = float3(a0.zw, h.y);
        float3 p2 = float3(a1.xy, h.z);
        float3 p3 = float3(a1.zw, h.w);
        float4 norm = taylorInvSqrt(float4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
        p0 *= norm.x;
        p1 *= norm.y;
        p2 *= norm.z;
        p3 *= norm.w;
        float4 m = max(0.6 - float4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
        m = m * m;
        return 42.0 * dot(m * m, float4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)));
    }

    // How much the agent is talking, 0 to 1: a slow phrase gate times a faster syllable wobble,
    // so speech ebbs and pauses instead of droning.
    static float speechEnv(float t) {
        float gate = ss(-0.25, 0.35, snoise(float3(t * 0.6, 21.0, 0.0)));
        float syl = 0.55 + 0.45 * snoise(float3(t * 3.0, 5.0, 0.0));
        return clamp(gate * syl, 0.0, 1.0);
    }

    // Centred coordinates normalized to the shorter side, y up, shrunk or grown by a tap's bounce.
    static float2 coords(float2 position, constant VoiceUniforms &u) {
        float m = min(u.resolution.x, u.resolution.y);
        float2 q = float2(position.x - 0.5 * u.resolution.x, 0.5 * u.resolution.y - position.y) / m;
        return q / u.scale;
    }

    // GLOW: a soft, airy globe. Color masses orbit inside it, concentric waves drift through
    // them, and the gaps between them let the background show through.
    fragment float4 voiceGlowFragment(VoiceVertexOut in [[stage_in]], constant VoiceUniforms &u [[buffer(0)]]) {
        float2 q = coords(in.position.xy, u);
        float t = u.time;
        float r = length(q);

        float speak = ss(0.6, 1.0, u.react);
        float speech = u.react * mix(0.55 + 0.25 * sin(t * 1.6), speechEnv(t), speak);
        speech = mix(speech, u.mic, u.voice);
        float speechSmooth = mix(speech, u.react * (0.55 + 0.25 * sin(t * 1.6)), 0.5 * speak);
        float energy = 0.12 + 0.30 * u.react + 0.18 * u.flow + 0.28 * u.load + 0.06 * speechSmooth;
        float R = 0.24 * (1.0 + speechSmooth * 0.20 + u.load * 0.05 * sin(t * 2.0) + u.react * 0.04 * sin(t * 1.6));
        float p = r / R;

        float core = exp(-2.0 * p * p);
        float body = ss(1.06, 0.62, p);

        float2 P = q / R;
        float pl = length(P);
        float nt = t * 0.15 + u.flowSpin * 0.05;
        float nAmp = 0.20 + 0.28 * energy;
        float2 sp = P + nAmp * float2(snoise(float3(P * 0.7, nt)), snoise(float3(P * 0.7 + 4.7, nt)));
        float ang = atan2(P.y, P.x);
        float wave = (0.018 + 0.025 * energy) * sin(pl * 5.0 - t * 2.0) * ss(0.0, 0.4, pl);
        sp += wave * float2(-sin(ang), cos(ang));
        sp = rot2(sp, u.flowSpin * 0.30);
        float2 gtoP = q - (u.hoverAmt > 0.001 ? u.hover : u.tap);
        sp += (gtoP / (length(gtoP) + 1e-4)) * poke(q, u) * 0.5;
        float bt = t;
        float a0 = u.orbSpin * 0.42 + 2.0 * snoise(float3(bt * 0.12, 0.0, 0.0));
        float a1 = -u.orbSpin * 0.34 + 2.0 * snoise(float3(bt * 0.10, 5.0, 0.0)) + 2.0;
        float a2 = u.orbSpin * 0.30 + 2.0 * snoise(float3(bt * 0.11, 9.0, 0.0)) + 1.0;
        float a3 = -u.orbSpin * 0.26 + 2.0 * snoise(float3(bt * 0.09, 14.0, 0.0)) + 3.5;
        float2 c0 = 0.40 * float2(cos(a0), sin(a0));
        float2 c1 = 0.38 * float2(cos(a1), sin(a1));
        float2 c2c = 0.36 * float2(cos(a2), sin(a2));
        float2 c3c = 0.34 * float2(cos(a3), sin(a3));
        float b0 = ss(1.15, 0.1, length(sp - c0));
        float b1 = ss(1.30, 0.1, length(sp - c1));
        float b2 = ss(1.20, 0.1, length(sp - c2c));
        float b3 = ss(1.25, 0.1, length(sp - c3c));

        float3 k0 = saturate3(vivid(u.col0, u.dark), 1.7);
        float3 kL = saturate3(clamp(vivid(u.col0, u.dark) * 1.18, 0.0, 1.0), 1.3);
        float3 kD = saturate3(vivid(u.col0, u.dark) * 0.85, 1.3);
        float3 colB = mix(kL, saturate3(vivid(u.col1, u.dark), 1.7), clamp(u.count - 1.0, 0.0, 1.0));
        float3 colC = mix(kD, saturate3(vivid(u.col2, u.dark), 1.7), clamp(u.count - 2.0, 0.0, 1.0));
        float3 colD = saturate3(vivid(u.col3, u.dark), 1.7);
        float3 colE = saturate3(vivid(u.col4, u.dark), 1.7);
        float3 base = saturate3(mix(vivid(u.col0, u.dark), float3(1.0), 0.06), 1.3);
        float3 col = base;
        col = mix(col, k0, b0);
        col = mix(col, colB, b1);
        col = mix(col, colC, b0 * 0.5);
        col = mix(col, colD, b2 * clamp(u.count - 3.0, 0.0, 1.0));
        col = mix(col, colE, b3 * clamp(u.count - 4.0, 0.0, 1.0));
        col = saturate3(col, 1.15);
        col = clamp(col * 1.12, 0.0, 1.0);
        col = desat(col, u.sat);

        float z = sqrt(max(1.0 - p * p, 0.0));
        float3 nrm = normalize(float3(q / R, z + 1e-4));
        float3 Ld = normalize(float3(-0.35, 0.45, 0.85));
        float diff = clamp(dot(nrm, Ld), 0.0, 1.0);
        col *= 0.80 + 0.20 * diff;
        float fres = pow(1.0 - clamp(nrm.z, 0.0, 1.0), 2.5);
        col += fres * 0.10 * mix(float3(1.0), k0, 0.6);

        float3 haloCol = mix(mix(vivid(u.col0, u.dark), float3(1.0), 0.75),
                             mix(vivid(u.col0, u.dark), float3(1.0), 0.32), u.dark);
        float halo = exp(-sq(max(r - R * 0.8, 0.0) / 0.09));
        float haloA = halo * (mix(0.05, 0.10, u.dark) + 0.05 * u.react);
        float waves = clamp(b0 + 0.8 * b1, 0.0, 1.0);
        float bodyA = clamp(body * (0.15 + 0.60 * waves + 0.06 * core) * (0.92 + 0.08 * fres), 0.0, 1.0);
        float fade = mix(1.0, 0.45 + 0.35 * sin(t * 2.0), u.load);
        float3 pm = col * bodyA + haloCol * haloA * (1.0 - bodyA);
        float al = bodyA + haloA * (1.0 - bodyA);
        float gain = u.bright * fade;
        return float4(pm * gain, al * gain);
    }

    // WAVE: a single string, flat at its ends, carrying a travelling wave packet that erupts with
    // speech. The colors flow along it in broad, drifting bands.
    fragment float4 voiceWaveFragment(VoiceVertexOut in [[stage_in]], constant VoiceUniforms &u [[buffer(0)]]) {
        float2 q = coords(in.position.xy, u);
        float t = u.time;
        float x = q.x;

        float sigma = 0.18;
        float center = u.load * 0.30 * sin(t * 1.3);
        float env = exp(-sq((x - center) / sigma));
        float freq = 24.0 + 26.0 * u.react + 10.0 * u.flow;
        float phase = x * freq - t * 5.0;

        float base = 0.018 + 0.022 * u.react;
        float speak = ss(0.6, 1.0, u.react);
        float drive = mix(speak * 0.26 * speechEnv(t), 0.30 * u.mic, u.voice);
        float amp = env * (base + drive + 0.14 * u.flow + 0.10 * u.load);
        float y = amp * sin(phase);

        float wAge = u.tapTime;
        float wBump = exp(-sq((x - u.tap.x) / 0.12))
                    * sin((x - u.tap.x) * 40.0 - wAge * 24.0)
                    * exp(-wAge * 2.6) * (1.0 - step(1.5, wAge));
        y += wBump * 0.05;
        float wHov = exp(-sq((x - u.hover.x) / 0.12))
                   * sin((x - u.hover.x) * 40.0 - t * 7.0) * u.hoverAmt;
        y += wHov * 0.04;

        float dydx = amp * freq * cos(phase);
        float halfWv = 0.0030 * sqrt(1.0 + dydx * dydx);
        float pix = 1.4 / min(u.resolution.x, u.resolution.y);
        float core = 1.0 - ss(halfWv - pix, halfWv + pix, abs(q.y - y));

        float3 k0 = vivid(u.col0, u.dark);
        float3 k1 = vivid(u.col1, u.dark);
        float3 k2 = vivid(u.col2, u.dark);
        float3 k3 = vivid(u.col3, u.dark);
        float3 k4 = vivid(u.col4, u.dark);
        float gx = clamp(x + 0.5, 0.0, 1.0);
        float seg = 1.0 / max(u.count, 1.0);
        float bandW = seg * 0.7;
        float m0 = 0.5 * seg + 0.12 * sin(t * 0.13);
        float m1 = 1.5 * seg + 0.13 * sin(t * 0.11 + 2.1);
        float m2 = 2.5 * seg + 0.12 * sin(t * 0.17 + 4.2);
        float m3 = 3.5 * seg + 0.12 * sin(t * 0.15 + 1.0);
        float m4 = 4.5 * seg + 0.12 * sin(t * 0.10 + 3.3);
        float w0 = exp(-sq((gx - m0) / bandW));
        float w1 = exp(-sq((gx - m1) / bandW)) * clamp(u.count - 1.0, 0.0, 1.0);
        float w2 = exp(-sq((gx - m2) / bandW)) * clamp(u.count - 2.0, 0.0, 1.0);
        float w3 = exp(-sq((gx - m3) / bandW)) * clamp(u.count - 3.0, 0.0, 1.0);
        float w4 = exp(-sq((gx - m4) / bandW)) * clamp(u.count - 4.0, 0.0, 1.0);
        float3 col = (k0 * w0 + k1 * w1 + k2 * w2 + k3 * w3 + k4 * w4) / (w0 + w1 + w2 + w3 + w4 + 1e-4);
        col = saturate3(col, 1.2);
        col = desat(col, u.sat);

        float edgeFade = ss(0.40, 0.24, abs(x));
        float a = core * edgeFade * u.bright;
        return float4(col * a, a);
    }
    """
}
