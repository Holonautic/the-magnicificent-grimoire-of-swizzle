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
        console.error(
            `Failed to compile shader: ${gl.getShaderInfoLog(shader)}`,
        );
        gl.deleteShader(shader);
        return null;
    }

    return shader;
}

/** @typedef Pipeline
 * @property {object} gl
 * @property {object} program
 * @property {object} canvas
 * @property {object} frameBuffer
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
    const gl = pipeline.gl;

    if (
        pipeline.canvas.width != window.innerWidth ||
        pipeline.canvas.height != window.innerHeight
    ) {
        //resize the canvas
        pipeline.canvas.width = window.innerWidth;
        pipeline.canvas.height = window.innerHeight;
        pipeline.previousFrame = create_texture_and_framebuffer(
            gl,
            window.innerWidth,
            window.innerHeight,
        );
    }

    const width = pipeline.canvas.width;
    const height = pipeline.canvas.height;

    gl.viewport(0, 0, width, height);

    gl.useProgram(pipeline.program);
    gl.uniform1f(
        pipeline.uniformLocations.aspectRatio,
        window.visualViewport.width / window.visualViewport.height,
    );
    gl.uniform1f(pipeline.uniformLocations.globalTime, time * 0.001);
    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, pipeline.previousFrame.backBuffer);
    gl.uniform1i(pipeline.uniformLocations.previousFrame, 0);
    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);

    gl.bindFramebuffer(gl.READ_FRAMEBUFFER, null);
    gl.bindFramebuffer(gl.DRAW_FRAMEBUFFER, pipeline.previousFrame.frameBuffer);
    gl.blitFramebuffer(
        0,
        0,
        width,
        height,
        0,
        0,
        width,
        height,
        gl.COLOR_BUFFER_BIT,
        gl.NEAREST,
    );
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);

    requestAnimationFrame((time) => render(pipeline, time));
}

function create_texture_and_framebuffer(gl, width, height) {
    const backBuffer = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, backBuffer);
    gl.texImage2D(
        gl.TEXTURE_2D,
        0,
        gl.RGBA,
        width,
        height,
        0,
        gl.RGBA,
        gl.UNSIGNED_BYTE,
        null,
    );
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);

    const frameBuffer = gl.createFramebuffer();
    gl.bindFramebuffer(gl.FRAMEBUFFER, frameBuffer);
    const attachmentPoint = gl.COLOR_ATTACHMENT0;
    gl.framebufferTexture2D(
        gl.FRAMEBUFFER,
        attachmentPoint,
        gl.TEXTURE_2D,
        backBuffer,
        0,
    );
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);

    return {
        backBuffer: backBuffer,
        frameBuffer: frameBuffer,
    };
}

/**
 * @param {string} vsSource - vertex shader source
 * @param {string} fsSource - fragment shader source
 * @returns {Pipeline} shaderInfo
 */
function create_pipeline(vsSource, fsSource) {
    const canvas = document.querySelector("#shader");

    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;

    const gl = canvas.getContext("webgl2", { alpha: false });

    if (gl === null) return;

    const vertexShader = loadShader(gl, gl.VERTEX_SHADER, vsSource);
    const fragShader = loadShader(gl, gl.FRAGMENT_SHADER, fsSource);

    const shaderProgram = gl.createProgram();
    gl.attachShader(shaderProgram, vertexShader);
    gl.attachShader(shaderProgram, fragShader);
    gl.linkProgram(shaderProgram);

    if (!gl.getProgramParameter(shaderProgram, gl.LINK_STATUS)) {
        console.error(
            `Failed to create shader program: ${gl.getProgramInfoLog(shaderProgram)}`,
        );
        return;
    }

    const previousFrame = create_texture_and_framebuffer(
        gl,
        canvas.width,
        canvas.height,
    );

    const pipeline = {
        gl: gl,
        canvas: canvas,
        program: shaderProgram,
        previousFrame: previousFrame,
        uniformLocations: {
            aspectRatio: gl.getUniformLocation(shaderProgram, "fAspectRatio"),
            globalTime: gl.getUniformLocation(shaderProgram, "fGlobalTime"),
            previousFrame: gl.getUniformLocation(
                shaderProgram,
                "texPreviousFrame",
            ),
        },
    };

    return pipeline;
}

const fsConcentric = fetch("/glsl/fs_concentric_swizzles.glsl").then(
    (response) => response.text(),
);

fsConcentric
    .then((fs) => create_pipeline(quadVSSource, fs))
    .then((pipeline) => render(pipeline));
