module Examples.CircleToSquare where

import Prelude
import Control.Monad.Eff
import Control.Monad.Eff.Console
import Control.Monad.Eff.Ref
import DOM
import Graphics.Three.Camera   as Camera
import Graphics.Three.Material as Material
import Graphics.Three.Object3D as Object3D
import Graphics.Three.Geometry as Geometry
import Graphics.Three.Renderer as Renderer
import Graphics.Three.Scene    as Scene
import Graphics.Three.Types
import Math (min, sin, pi, (%))

import Examples.Common


interval = 200.0
radius   = 50.0

initUniforms = {
        amount: {
             "type" : "f"
            , value : 0.0
        },
        radius: {
             "type" : "f"
            , value : radius
        }
    }

vertexShader :: String
vertexShader = """
    #ifdef GL_ES
    precision highp float;
    #endif

    uniform float amount;
    uniform float radius;

    float morph(in float p) {
        float eps = 0.1;
        float scale = radius*1.6;

        if (p < -eps) {
           return mix(p, -scale, amount); //TODO uniform width
        }
        if (p > eps) {
           return mix(p, scale, amount);
        }

        return 0.0;
    }

    void main() {
        vec3 pos = position;

        pos.x = morph(pos.x);
        pos.y = morph(pos.y);
        
        gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
    }
"""

fragmentShader :: String 
fragmentShader = """
    #ifdef GL_ES
    precision highp float;
    #endif

    void main() {
        gl_FragColor = vec4(1.0,0.0,0.0,1.0);
    }
"""

clamp :: Number -> Number
clamp n = min 1.0 $ max (0.0) n

--TODO square wave with ease functions

morphShape :: forall eff. Material.Shader -> Number -> Eff (trace :: CONSOLE, three :: Three | eff) Unit
morphShape ma n = do
    let a = (sin $ ((2.0 * pi) / interval) * (n % interval)) * 0.5 + 0.5
    Material.setUniform ma "amount" $ clamp a
    pure unit

render :: forall eff. Ref Number -> Context -> Material.Shader ->
                       Eff ( trace :: CONSOLE, ref :: REF, three :: Three | eff) Unit
render frame context mat = do
    
    modifyRef frame $ \f -> f + 1.0
    f <- readRef frame

    morphShape mat f

    renderContext context

main = do
    ctx@(Context c) <- initContext Camera.Orthographic
    frame           <- newRef 0.0
    material        <- Material.createShader {
                            uniforms: initUniforms
                            , vertexShader:   vertexShader
                            , fragmentShader: fragmentShader
                        }
    circle          <- Geometry.createCircle radius 32.0 0.0 (2.0 * pi)
    mesh            <- Object3D.createMesh circle material

    Scene.addObject c.scene mesh

    doAnimation $ render frame ctx material

