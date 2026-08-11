const quadVSSource = `#version 300 es

out vec2 uv;

void main() {
  int u = (gl_VertexID % 2);
  int v = (gl_VertexID / 2);

  float x = float(u * 2 - 1);
  float y = float(v * 2 - 1);

  uv = vec2(u, v);

  gl_Position = vec4(x, y, 0.5, 1);
}
`;

const fsSource = `#version 300 es
  precision mediump float;

  in vec2 uv;

  out vec4 fragColor;

  void main() {
    fragColor = vec4(0.3, 0.1, 0.1 + 0.2 * uv.y, 1.0);
  }
`;

function loadShader(gl, type, source) {
  const shader = gl.createShader(type);

  gl.shaderSource(shader, source);
  gl.compileShader(shader);

  if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
    console.error(`Failed to compile shader: ${gl.getShaderInfoLog(shader)}`)
    gl.deleteShader(shader);
    return null;
  }

  return shader;
}

/** @typedef Pipeline
 * @property {object} gl
 * @property {object} program
 * @property {object} canvas
 * @property {object} uniformLocations
 * @property {object} uniformLocations.aspectRatio
 * @property {object} uniformLocations.globalTime
 */

/**
 *
 * @param {object} gl
 * @param {Pipeline} pipeline
 */
function render(pipeline, time) {

  pipeline.canvas.width = window.innerWidth;
  pipeline.canvas.height = window.innerHeight;

  const gl = pipeline.gl;

  gl.viewport(0, 0, pipeline.canvas.width, pipeline.canvas.height);

  gl.clearColor(0.1, 0.1, 0.2, 1.0);
  gl.clear(gl.COLOR_BUFFER_BIT);

  gl.useProgram(pipeline.program);
  gl.uniform1f(pipeline.uniformLocations.aspectRatio, window.visualViewport.width / window.visualViewport.height);
  gl.uniform1f(pipeline.uniformLocations.globalTime, time * 0.001)
  gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);

  requestAnimationFrame(time => render(pipeline, time));
}

/**
 * @param {string} vsSource - vertex shader source
 * @param {string} fsSource - fragment shader source
 * @returns {Pipeline} shaderInfo
 */
function load_shaders(vsSource, fsSource) {
  const canvas = document.querySelector("#shader");

  canvas.width = window.visualViewport.width;
  canvas.height = window.visualViewport.height;

  const gl = canvas.getContext("webgl2", { alpha: false });

  if (gl === null) return;

  const vertexShader = loadShader(gl, gl.VERTEX_SHADER, vsSource);
  const fragShader = loadShader(gl, gl.FRAGMENT_SHADER, fsSource);

  const shaderProgram = gl.createProgram();
  gl.attachShader(shaderProgram, vertexShader);
  gl.attachShader(shaderProgram, fragShader);
  gl.linkProgram(shaderProgram);

  if (!gl.getProgramParameter(shaderProgram, gl.LINK_STATUS)) {
    console.error(`Failed to create shader program: ${gl.getProgramInfoLog(shaderProgram)}`);
    return;
  }

  const pipeline = {
    gl: gl,
    canvas: canvas,
    program: shaderProgram,
    uniformLocations: {
      aspectRatio: gl.getUniformLocation(shaderProgram, "fAspectRatio"),
      globalTime: gl.getUniformLocation(shaderProgram, "fGlobalTime"),
    }
  }

  return pipeline;
}

const fsConcentric = fetch('/glsl/fs_concentric_swizzles.glsl').then(response => response.text());

fsConcentric.then(fs => load_shaders(quadVSSource, fs)).then(pipeline => render(pipeline));
