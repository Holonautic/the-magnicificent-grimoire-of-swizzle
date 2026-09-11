#version 300 es

precision highp float;

uniform float fGlobalTime;
uniform float fAspectRatio;
uniform sampler2D texPreviousFrame;

in vec2 uv;

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

float edge(in vec2 p, in vec2 p0, in vec2 p1) {
  return (p.x - p0.x) * (p1.y - p0.y) - (p.y - p0.y) * (p1.x - p0.x);
}

struct Triangle {
  vec2[3] positions;
  vec3[3] colours;
  float[3] back_left_weight;
  float[3] back_right_weight;
  float[3] front_left_weight;
  float[3] front_right_weight;
  float[3] head_weight;
  float[3] tail_weight;
};

const int TRI_COUNT = 11;

const Triangle tris[TRI_COUNT] = Triangle[](
    //tail
    Triangle(
      vec2[3](
        vec2(-2.785, 1.043),
        vec2(-4.092, 0.780),
        vec2(-4.381, 0.022)
      ),
      vec3[3](
        vec3(0.510, 0.265, 0.768),
        vec3(0.408, 0.160, 0.757),
        vec3(0.437, 0.039, 0.757)
      ),
      float[3](0.488, 0.0, 0.0),
      float[3](0.488, 0.0, 0.0),
      float[3](0.012, 0.0, 0.0),
      float[3](0.012, 0.0, 0.0),
      float[3](0.0, 0.0, 0.0),
      float[3](0.0, 1.0, 1.0)
    ),
    //back leg back left
    Triangle(
      vec2[3](
        vec2(-2.715, 1.124),
        vec2(-1.613, 1.852),
        vec2(-1.996, 0.026)
      ),
      vec3[3](
        vec3(0.255, 0.132, 0.384),
        vec3(0.255, 0.132, 0.384),
        vec3(0.198, 0.033, 0.108)
      ),
      float[3](0.488, 0.488, 0.977),
      float[3](0.488, 0.488, 0.0),
      float[3](0.012, 0.012, 0.23),
      float[3](0.012, 0.012, 0.0),
      float[3](0.0, 0.0, 0.0),
      float[3](0.0, 0.0, 0.0)
    ),
    //back leg front left
    Triangle(
      vec2[3](
        vec2(-1.898, 0.280),
        vec2(-1.575, 1.863),
        vec2(-0.838, 1.459)
      ),
      vec3[3](
        vec3(0.315, 0.145, 0.208),
        vec3(0.187, 0.155, 0.453),
        vec3(0.255, 0.132, 0.384)
      ),
      float[3](0.910, 0.487, 0.165),
      float[3](0.067, 0.487, 0.165),
      float[3](0.022, 0.013, 0.335),
      float[3](0.002, 0.013, 0.335),
      float[3](0.0, 0.0, 0.0),
      float[3](0.0, 0.0, 0.0)
    ),

    //front leg left
    Triangle(
      vec2[3](
        vec2(-1.267, 0.906),
        vec2(-0.002, 0.003),
        vec2(-0.819, 1.409)
      ),
      vec3[3](
        vec3(0.172, 0.092, 0.255),
        vec3(0.185, 0.031, 0.100),
        vec3(0.086, 0.075, 0.379)
      ),
      float[3](0.531, 0.002, 0.170),
      float[3](0.142, 0.000, 0.170),
      float[3](0.189, 0.998, 0.330),
      float[3](0.138, 0.000, 0.330),
      float[3](0.0, 0.0, 0.0),
      float[3](0.0, 0.0, 0.0)
    ),
    //back leg back right
    Triangle(
      vec2[3](
        vec2(-2.715, 1.124),
        vec2(-1.613, 1.852),
        vec2(-1.996, 0.026)
      ),
      vec3[3](
        vec3(0.510, 0.265, 0.768),
        vec3(0.510, 0.265, 0.768),
        vec3(0.396, 0.067, 0.214)
      ),
      float[3](0.488, 0.488, 0.0),
      float[3](0.488, 0.488, 0.977),
      float[3](0.012, 0.012, 0.0),
      float[3](0.012, 0.012, 0.23),
      float[3](0.0, 0.0, 0.0),
      float[3](0.0, 0.0, 0.0)
    ),

    //back leg front right
    Triangle(
      vec2[3](
        vec2(-1.898, 0.280),
        vec2(-1.575, 1.863),
        vec2(-0.838, 1.459)
      ),
      vec3[3](
        vec3(0.629, 0.290, 0.415),
        vec3(0.373, 0.310, 0.906),
        vec3(0.510, 0.265, 0.768)
      ),
      float[3](0.070, 0.487, 0.165),
      float[3](0.906, 0.487, 0.165),
      float[3](0.002, 0.013, 0.335),
      float[3](0.022, 0.013, 0.335),
      float[3](0.0, 0.0, 0.0),
      float[3](0.0, 0.0, 0.0)
    ),

    //front leg right
    Triangle(
      vec2[3](
        vec2(-1.267, 0.906),
        vec2(-0.002, 0.003),
        vec2(-0.819, 1.409)
      ),
      vec3[3](
        vec3(0.510, 0.265, 0.768),
        vec3(0.396, 0.067, 0.214),
        vec3(0.510, 0.265, 0.768)
      ),
      float[3](0.142, 0.000, 0.170),
      float[3](0.531, 0.002, 0.170),
      float[3](0.138, 0.000, 0.330),
      float[3](0.189, 0.998, 0.330),
      float[3](0.0, 0.0, 0.0),
      float[3](0.0, 0.0, 0.0)
    ),
    //neck 1
    Triangle(
      vec2[3](
        vec2(-0.319, 0.663),
        vec2(-0.781, 1.425),
        vec2(0.393, 1.306)
      ),
      vec3[3](
        vec3(0.396, 0.067, 0.214),
        vec3(0.272, 0.439, 0.633),
        vec3(0.566, 0.149, 0.476)
      ),
      float[3](0.076, 0.174, 0.0),
      float[3](0.076, 0.174, 0.0),
      float[3](0.145, 0.326, 0.0),
      float[3](0.705, 0.326, 0.0),
      float[3](0.0, 0.0, 1.0),
      float[3](0.0, 0.0, 0.0)
    ),
    //neck 2
    Triangle(
      vec2[3](
        vec2(-0.781, 1.425),
        vec2(0.393, 1.306),
        vec2(0.465, 1.631)
      ),
      vec3[3](
        vec3(0.272, 0.439, 0.633),
        vec3(0.566, 0.149, 0.476),
        vec3(0.567, 0.223, 0.584)
      ),
      float[3](0.174, 0.0, 0.0),
      float[3](0.174, 0.0, 0.0),
      float[3](0.326, 0.0, 0.0),
      float[3](0.326, 0.0, 0.0),
      float[3](0.0, 1.0, 1.0),
      float[3](0.0, 0.0, 0.0)
    ),
    //head
    Triangle(
      vec2[3](
        vec2(0.502, 1.915),
        vec2(1.574, 1.343),
        vec2(0.323, 1.148)
      ),
      vec3[3](
        vec3(0.209, 0.636, 0.323),
        vec3(0.009, 0.723, 1.000),
        vec3(0.137, 0.636, 0.445)
      ),
      float[3](0.0, 0.0, 0.0),
      float[3](0.0, 0.0, 0.0),
      float[3](0.0, 0.0, 0.0),
      float[3](0.0, 0.0, 0.0),
      float[3](1.0, 1.0, 1.0),
      float[3](0.0, 0.0, 0.0)
    ),
    //ear
    Triangle(
      vec2[3](
        vec2(0.160, 1.868),
        vec2(0.447, 1.924),
        vec2(0.387, 1.661)
      ),
      vec3[3](
        vec3(0.209, 0.636, 0.323),
        vec3(0.009, 0.723, 1.000),
        vec3(0.137, 0.636, 0.445)
      ),
      float[3](0.0, 0.0, 0.0),
      float[3](0.0, 0.0, 0.0),
      float[3](0.0, 0.0, 0.0),
      float[3](0.0, 0.0, 0.0),
      float[3](1.0, 1.0, 1.0),
      float[3](0.0, 0.0, 0.0)
    )
  );

// http://www.jcgt.org/published/0009/03/02/
vec3 hash(uvec3 v) {
  v = v * 1664525u + 1013904223u;

  v.x += v.y * v.z;
  v.y += v.z * v.x;
  v.z += v.x * v.y;

  v ^= v >> 16u;

  v.x += v.y * v.z;
  v.y += v.z * v.x;
  v.z += v.x * v.y;

  return vec3(v) * (1.0 / float(0xffffffffu));
}

uvec3 uhash(uvec3 v) {
  v = v * 1664525u + 1013904223u;

  v.x += v.y * v.z;
  v.y += v.z * v.x;
  v.z += v.x * v.y;

  v ^= v >> 16u;

  v.x += v.y * v.z;
  v.y += v.z * v.x;
  v.z += v.x * v.y;

  return v;
}

//borrowing noise with derivatives from Inigo Quilez
//https://www.shadertoy.com/view/4dffRH
//thanks Inigo we would be nowhere without you <3
vec4 noised(in vec3 x)
{
  // grid
  uvec3 i = uvec3(floor(x));

  vec3 f = fract(x);

  // quintic interpolant
  vec3 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
  vec3 du = 30.0 * f * f * (f * (f - 2.0) + 1.0);

  // gradients
  vec3 ga = hash(i + uvec3(0, 0, 0));
  vec3 gb = hash(i + uvec3(1, 0, 0));
  vec3 gc = hash(i + uvec3(0, 1, 0));
  vec3 gd = hash(i + uvec3(1, 1, 0));
  vec3 ge = hash(i + uvec3(0, 0, 1));
  vec3 gf = hash(i + uvec3(1, 0, 1));
  vec3 gg = hash(i + uvec3(0, 1, 1));
  vec3 gh = hash(i + uvec3(1, 1, 1));

  // projections
  float va = dot(ga, f - vec3(0.0, 0.0, 0.0));
  float vb = dot(gb, f - vec3(1.0, 0.0, 0.0));
  float vc = dot(gc, f - vec3(0.0, 1.0, 0.0));
  float vd = dot(gd, f - vec3(1.0, 1.0, 0.0));
  float ve = dot(ge, f - vec3(0.0, 0.0, 1.0));
  float vf = dot(gf, f - vec3(1.0, 0.0, 1.0));
  float vg = dot(gg, f - vec3(0.0, 1.0, 1.0));
  float vh = dot(gh, f - vec3(1.0, 1.0, 1.0));

  // interpolations
  float k0 = va - vb - vc + vd;
  vec3 g0 = ga - gb - gc + gd;
  float k1 = va - vc - ve + vg;
  vec3 g1 = ga - gc - ge + gg;
  float k2 = va - vb - ve + vf;
  vec3 g2 = ga - gb - ge + gf;
  float k3 = -va + vb + vc - vd + ve - vf - vg + vh;
  vec3 g3 = -ga + gb + gc - gd + ge - gf - gg + gh;
  float k4 = vb - va;
  vec3 g4 = gb - ga;
  float k5 = vc - va;
  vec3 g5 = gc - ga;
  float k6 = ve - va;
  vec3 g6 = ge - ga;

  return vec4(va + k4 * u.x + k5 * u.y + k6 * u.z + k0 * u.x * u.y + k1 * u.y * u.z + k2 * u.z * u.x + k3 * u.x * u.y * u.z, // value
    ga + g4 * u.x + g5 * u.y + g6 * u.z + g0 * u.x * u.y + g1 * u.y * u.z + g2 * u.z * u.x + g3 * u.x * u.y * u.z + // derivatives
      du * (vec3(k4, k5, k6) +
          vec3(k0, k1, k2) * u.yzx +
          vec3(k2, k0, k1) * u.zxy +
          k3 * u.yzx * u.zxy));
}

vec3 hue_shift(vec3 color, float hue) {
  const vec3 k = vec3(0.57735, 0.57735, 0.57735);
  float cosAngle = cos(hue);
  return vec3(color * cosAngle + cross(k, color) * sin(hue) + k * dot(k, color) * (1.0 - cosAngle));
}

const float PI = radians(180.0);

void main(void)
{
  vec2 cuv = (uv - 0.5) * vec2(fAspectRatio, 1.) * 2.0;

  float noise_scale = 10.0;
  vec3 noise_1 = noised(vec3(noise_scale * cuv + vec2(100.0), fGlobalTime)).yzw;
  vec3 noise_2 = noised(vec3(noise_scale * cuv, fGlobalTime)).yzw;
  vec3 noise_curl = cross(noise_1, noise_2);

  vec2 puv = vec2(atan(cuv.y, cuv.x) / (2.0 * PI), length(cuv));

  float scale_adjust = (1.0 / 0.6) / fAspectRatio;

  puv.y *= scale_adjust;

  const float layer_height = 4.0;

  float layer = floor((puv.y) * layer_height + 1.0);

  puv.x *= (2.0 / layer_height) * layer;

  float walk_time = fGlobalTime * layer;

  puv.x -= 0.1 * walk_time / layer;

  puv = fract(puv * layer_height);

  vec2 scale = vec2(0.1, 0.3) * 1.5;

  vec3 colour = vec3(0.0);

  vec2 offset = vec2(0.65, 0.0);

  float back_leg_time = 2.0 * PI * walk_time / layer;
  float front_leg_time = 2.0 * PI * walk_time / layer - 0.5 * PI;

  float tail_offset = 0.0;
  const float WALK_SCALE = 0.3;
  float back_left_offset = max(WALK_SCALE * cos(back_leg_time), 0.0);
  float back_right_offset = max(-WALK_SCALE * cos(back_leg_time), 0.0);
  float front_left_offset = max(WALK_SCALE * cos(front_leg_time), 0.0);
  float front_right_offset = max(-WALK_SCALE * cos(front_leg_time), 0.0);
  float head_offset = 0.0;

  float front_fb = 0.07 * sin(front_leg_time);
  float back_fb = 0.07 * sin(back_leg_time);

  if (layer > 4.0) {
    for (int i = 0; i < TRI_COUNT; i++) {
      vec2[3] pos = vec2[3](
          tris[i].positions[0] * scale + offset,
          tris[i].positions[1] * scale + offset,
          tris[i].positions[2] * scale + offset
        );

      for (int j = 0; j < 3; j++) {
        pos[j] += tris[i].back_left_weight[j] * vec2(back_fb, back_left_offset)
            + tris[i].front_left_weight[j] * vec2(front_fb, front_left_offset)
            + tris[i].back_right_weight[j] * vec2(-back_fb, back_right_offset)
            + tris[i].front_right_weight[j] * vec2(-front_fb, front_right_offset)
            + tris[i].head_weight[j] * vec2(0.0, head_offset)
            + tris[i].tail_weight[j] * vec2(0.0, tail_offset);
      }

      float[3] e = float[3](
          edge(puv, pos[1], pos[2]) / edge(pos[0], pos[1], pos[2]),
          edge(puv, pos[2], pos[0]) / edge(pos[1], pos[2], pos[0]),
          edge(puv, pos[0], pos[1]) / edge(pos[2], pos[0], pos[1])
        );

      if (e[0] > 0.0 && e[1] > 0.0 && e[2] > 0.0) {
        //calculate barycentric coordinates
        colour = e[0] * tris[i].colours[0]
            + e[1] * tris[i].colours[1]
            + e[2] * tris[i].colours[2];
      }
    }

    colour = hue_shift(colour, fGlobalTime + layer);
  }

  vec2 tunnel = vec2(0.5);

  vec2 prev_uv = 1.01 * (uv - tunnel) + tunnel;

  const float FLAME_SPEED = 0.02;
  prev_uv += 0.1 * (noise_curl.yz * FLAME_SPEED + noise_curl.xy * FLAME_SPEED) / fAspectRatio;

  out_color = vec4(0.6 * colour, 1.0) + texture(texPreviousFrame, prev_uv) * 0.6;
  //out_color = vec4(colour, 1.0);
  //out_color = vec4(uv,0.0, 1.0);
}
