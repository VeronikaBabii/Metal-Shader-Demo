# Metal-Shader-Demo
Placing 3D model with RealityKit in AR scene, while adding light effects to a simple object with Metal shader.

Overview
The project focuses on rendering a simple 3D object within an AR space using custom shaders for lighting effects.
The initial plan was to apply a light effect to 3D models; however, due to complications in manipulating vertex data, the scope was reduced to a basic shape.

ARKit and RealityKit Integration
The project integrates ARKit and RealityKit for AR capabilities.
RealityKit handles the 3D object rendering.
ARKit facilitates the blending of digital content with the real world, including surface detection for object placement.

Metal Rendering and Custom Shaders
Metal is utilized for the shaders that process vertex information and implement custom lighting calculations.
Lighting effects, including attenuation and ambient influence, are calculated in the fragment shader, considering the light's position and intensity.

Note. Applying a shader to a more complex 3D model caused the entire screen to display a uniform purple color. (Will address later).
