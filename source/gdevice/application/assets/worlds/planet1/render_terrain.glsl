VERTEX:
#version 400
// =========================================================
//  _____         _              _____ _         _         
// |  |  |___ ___| |_ ___ _ _   |   __| |_ ___ _| |___ ___ 
// |  |  | -_|  _|  _| -_|_'_|  |__   |   | .'| . | -_|  _|
//  \___/|___|_| |_| |___|_,_|  |_____|_|_|__,|___|___|_|  
//
// Given gl_VertexID, turns a height-quartet into 
// a LOD blended vertex position (in model space).

uniform vec2  tileOffset;
uniform float kernelSize;
uniform sampler2D quartetsTU;
int tileSize = textureSize(quartetsTU, 0).x;

out vec3 position;

void main() 
{	
	// Model-space vertex position in plane XY
	vec2 p = vec2( gl_VertexID % tileSize, gl_VertexID / tileSize );		
	
	// Get the quartet
	vec4 qu	= textureLod( quartetsTU, (p.xy + 0.5)/tileSize, 0 );

	// Compute blend factor (with LOD+1, in [kernelSize-2, kernelSize-1])
	float blend = 0.0;		
	vec2 offset = tileOffset + p/(tileSize-1);
	float chebyshev = max(abs(offset.x), abs(offset.y));
	blend = smoothstep(kernelSize-2, kernelSize-1, chebyshev);	
	
	// Blend position with coarser vertex position.
	p = mix(p, p-mod(p,2), blend);
	
	// Blend height with coarser vertex height.
	float height = mix(mix(qu.x, qu.y, blend), mix(qu.z, qu.w, blend), blend);
	
	position = vec3(p/(tileSize-1), height);
}

CONTROL:
#version 400  
// ===========================================================================================================                                                                                                        
//   _____                 _ _     _   _            _____         _           _    _____ _         _         
//  |_   _|___ ___ ___ ___| | |___| |_|_|___ ___   |     |___ ___| |_ ___ ___| |  |   __| |_ ___ _| |___ ___ 
//    | | | -_|_ -|_ -| -_| | | .'|  _| | . |   |  |   --| . |   |  _|  _| . | |  |__   |   | .'| . | -_|  _|
//    |_| |___|___|___|___|_|_|__,|_| |_|___|_|_|  |_____|___|_|_|_| |_| |___|_|  |_____|_|_|__,|___|___|_|  
//                                                                                                           
// * Patch frustum culling 
// * Tessellation control of edges and big patches (including vertical) 
// * Displace mapping

uniform vec2  tileOffset;
uniform float kernelSize;
uniform int   Tessellator = 1;
uniform float tessellationFactor;
uniform float tessellationRange;
uniform mat4  ModelViewProjectionMatrix;
uniform float scale;
uniform float lod_factor = 100.0;   // TEMP
uniform vec2  viewport;             // TEMP

in vec3 position[];

out vec3 tPosition[];
layout(vertices = 4) out;

vec4 projectToNDS(vec3 position) {
   vec4 result = ModelViewProjectionMatrix * vec4(position, 1.0);
   result /= result.w; // Scale to [-1,+1]
   return result;
}

bool isOffScreen(vec4 ndsPosition) {
    //return (ndsPosition.z < -0.5) || any(lessThan(ndsPosition.xy, vec2(-1.0)) || greaterThan(ndsPosition.xy, vec2(1.0)));
    //return (ndsPosition.z < -1.0) || any(lessThan(ndsPosition.xy, vec2(-2.0)) || greaterThan(ndsPosition.xy, vec2(2.0)));
    //return (ndsPosition.z << -2.0) || any(lessThan(ndsPosition.xy, vec2(-4.0)) || greaterThan(ndsPosition.xy, vec2(4.0)));
	return ndsPosition.z < -2.0
		|| ndsPosition.x < -4.0 || ndsPosition.x > +4.0  
		|| ndsPosition.y < -4.0 || ndsPosition.y > +4.0;
}
    
vec2 projectToScreen(vec4 ndsPosition) {
	return (clamp(ndsPosition.xy, -1.3, 1.3) + 1.0) * (viewport.xy*0.5);
}

float computeTessellationLevel(vec2 ss0, vec2 ss1) {
	return clamp(distance(ss0, ss1)/lod_factor, 0, 1);
}

void main()
{
	if( gl_InvocationID == 0 ) {
		vec4 p0 = projectToNDS(position[0]);
		vec4 p1 = projectToNDS(position[1]);
		vec4 p2 = projectToNDS(position[2]);
		vec4 p3 = projectToNDS(position[3]);
	
        if(all(bvec4(isOffScreen(p0), isOffScreen(p1), isOffScreen(p2), isOffScreen(p3)))) {
            // Discard patch (late frustum culling).
            gl_TessLevelOuter[0] = 0;
            gl_TessLevelOuter[1] = 0;
            gl_TessLevelOuter[2] = 0;
            gl_TessLevelOuter[3] = 0;
            gl_TessLevelInner[0] = 0;
            gl_TessLevelInner[1] = 0;
        } else {
            // TODO: Fetch (and lod blend) gradient, submap, mixmap
            // TODO: Tessellation control for plane change, tessellation of edges and big patch (also vertical).
            
        //// TEMP
			vec2 ss0 = projectToScreen(p0);
			vec2 ss1 = projectToScreen(p1);
			vec2 ss2 = projectToScreen(p2);
			vec2 ss3 = projectToScreen(p3);

			float e0 = computeTessellationLevel(ss1, ss2);
			float e1 = computeTessellationLevel(ss0, ss1);
			float e2 = computeTessellationLevel(ss3, ss0);
			float e3 = computeTessellationLevel(ss2, ss3);
        ////
			vec4 ox = tileOffset.x + vec4( position[0].x, position[1].x, position[2].x, position[3].x );
			vec4 oy = tileOffset.y + vec4( position[0].y, position[1].y, position[2].y, position[3].y );
			vec4 d = sqrt( ox*ox + oy*oy ); 				
			d = 1.0 - smoothstep(0.0, tessellationFactor*(kernelSize-1), d);
			vec4 t = 1.0 + Tessellator * 63.0 * tessellationFactor * float(scale == 1.0) * d ;//* (e0+e1+e2+e3)/4; // TEMP
			t = mix(t.yxwz, t.zyxw, 0.5); 
            gl_TessLevelOuter[0] = t.x;
            gl_TessLevelOuter[1] = t.y;
            gl_TessLevelOuter[2] = t.z;
            gl_TessLevelOuter[3] = t.w;
            gl_TessLevelInner[0] = mix(t.y, t.z, 0.5);
            gl_TessLevelInner[1] = mix(t.x, t.w, 0.5);
        }
    }

	tPosition[gl_InvocationID] = position[gl_InvocationID];
}

EVALUATION:
#version 400        
// ====================================================================================================================                                                                                                      
//   _____                 _ _     _   _            _____         _         _   _            _____ _         _         
//  |_   _|___ ___ ___ ___| | |___| |_|_|___ ___   |   __|_ _ ___| |_ _ ___| |_|_|___ ___   |   __| |_ ___ _| |___ ___ 
//    | | | -_|_ -|_ -| -_| | | .'|  _| | . |   |  |   __| | | .'| | | | .'|  _| | . |   |  |__   |   | .'| . | -_|  _|
//    |_| |___|___|___|___|_|_|__,|_| |_|___|_|_|  |_____|\_/|__,|_|___|__,|_| |_|___|_|_|  |_____|_|_|__,|___|___|_|  
//                                                                                                                     
// Computes position, gradient, color, mixmap (of the new vertex)
// interpolating within the generated patch (gl_TessCoord.xy).
// (position is still in model space).
// NOTE: The height is displaced but it takes lots of fetches.

// UNIFORMS:
uniform sampler2D gradientsTU;
uniform sampler2D colorsTU;
uniform sampler2D mixmapsTU;
uniform float scale;
int tileSize = textureSize(mixmapsTU, 0).x;

// TEMP: These are necessary for Fog and Displacement:
    uniform mat4 ModelViewMatrix; //
    
// TEMP: These are necessary for Fog:
    uniform float fog_density = 0.0005; //

// TEMP: These are necessary for displacement:
    uniform sampler2D detailsTU;
    uniform sampler2D detailsDxTU;
    uniform sampler2D detailsDyTU;
    uniform float kernelSize; //
uniform float tessellationRange;
uniform float tessellationDisplacement; 
    
uniform vec4 defaultColorR;
uniform vec4 defaultColorG;
uniform vec4 defaultColorB;
uniform vec4 defaultColorA;

// INPUT:
layout(quads, fractional_odd_spacing, ccw) in;	
in vec3 tPosition[];

// OUTPUT:
out VertexData {
	vec4 position;
	vec4 gradient;
	vec4 color;
	vec4 mixmap;
} tVertex;
// gl_Position




////////////////////////////////////////////////////////////
// Common functions
//

vec4 noise(vec2 point) 
{		
    vec2 i = floor(point);
    vec2 f = fract(point);

	vec2 u = f*f*(3.0-2.0*f);  //f*f*f*(f*(6.0*f-15.0)+10.0);
	vec2 du = 6.0*f*(1.0-f);   //30.0*f*f*(f*(f-2.0)+1.0);
	
	const float WIDTH = 0.3137; // 13.0
    vec4 L = vec4(0.0, 1.0, WIDTH, WIDTH + 1.0);	
#if 0
    L = fract(43758.5453123 * sin(L + dot(i, L.yz)));
#else
    L = fract((L + dot(i, L.yz))*0.1731);
    L += L*(L + 1.0);
    L = fract(7.7771*L*L) - 0.5;
#endif
	L = vec4(L.x, L.y-L.x, L.z-L.x, L.x-L.y-L.z+L.w);
	return vec4(du*(L.yz + L.w*u.yx), L.x + L.y*u.x + L.z*u.y + L.w*u.x*u.y, 0.0 );
}

vec4 textureNoTileLod( sampler2D samp, in vec2 uv, float lodBias ) 
{
    float period = 16.0;
    vec2 p = fract(uv/period)*period;
    p = abs(p - vec2(period)/2.0);

    float k = noise(p*1.0).z;
    
    //vec2 duvdx = dFdx( uv );
    //vec2 duvdy = dFdy( uv );
    
    float l = k*3.17;
    float f = fract(l);
    
    float ia = floor(l+0.5);
    float ib = floor(l);
    f = min(f, 1.0-f)*2.0;  
    
    vec2 offa = sin(vec2(3.0,7.0)*ia);
    vec2 offb = cos(vec2(7.0,3.0)*ib);

    float v = 0.5;
    vec4 cola = textureLod( samp, uv + v*offa, lodBias); //duvdx, duvdy );
    vec4 colb = textureLod( samp, uv + v*offb, lodBias); //duvdx, duvdy );
    
    return mix( cola, colb, smoothstep(0.2, 0.8, f-0.1*dot(cola-colb, vec4(1.0))) );
}


vec3 getTriplanarWeightVector(vec3 N) 
{
    vec3 w = pow(abs(N), vec3(64.0));  
    return w / dot(w, vec3(1.0));
}

vec4 textureTriplanar(sampler2D detailsTU, in vec3 position, in vec3 weight, in float lodBias)
{
#if 1 
    return weight.x*textureLod(detailsTU, position.zy, lodBias) 
         + weight.y*textureLod(detailsTU, position.zx, lodBias) 
         + weight.z*textureLod(detailsTU, position.xy, lodBias);
#else
    return weight.x*textureNoTileLod(detailsTU, position.zy, lodBias) 
         + weight.y*textureNoTileLod(detailsTU, position.zx, lodBias) 
         + weight.z*textureNoTileLod(detailsTU, position.xy, lodBias);
#endif
}

// https://www.shadertoy.com/view/Ms3yzS
vec4 blendMixmap(vec4 mixmap) 
{
    const float MixmapBlending = 0.5; // 0.0 sharp, 0.5 smooth, 1.0 smoother
    float maxima = max(max(mixmap.x, mixmap.y), max(mixmap.z, mixmap.w));
    mixmap = max(mixmap - maxima + MixmapBlending, vec4(0.0));
    mixmap /= dot(mixmap, vec4(1.0));
    return mixmap;
}

vec4 blendColor(vec4 color, vec4 mixmap, float x1, float x2)
{    
    color = mix(color, defaultColorR, smoothstep(x1, x2, mixmap.r))
          + mix(color, defaultColorG, smoothstep(x1, x2, mixmap.g))
          + mix(color, defaultColorB, smoothstep(x1, x2, mixmap.b))
          + mix(color, defaultColorA, smoothstep(x1, x2, mixmap.a));
    return color/4.0;
}

// http://weber.itn.liu.se/~stegu/TNM084-2017/bumpmapping/bumpmapping.pdf
// Also check doBumpMap() in Desert Canyon (https://www.shadertoy.com/view/Xs33Df)
void displaceVertexAndRecomputeNormal(inout vec3 p, inout vec3 N, float H, vec3 dH)
{
    p = p + H*N;
    N = normalize( (1.0 + dot(dH,N))*N - dH );
}
////////////////////////////////////////////////////////////


void main()
{
	float u = gl_TessCoord.x;
    float v = gl_TessCoord.y;
    
    vec3 position = mix(mix(tPosition[1],tPosition[0],u), mix(tPosition[2],tPosition[3],u), v);
	vec2 p = (position.xy*(tileSize-1) + 0.5)/tileSize;
	vec4 gradient = textureLod(gradientsTU, p, 0); 
	vec4 color = textureLod(colorsTU,  p, 0); 
	vec4 mixmap	= textureLod(mixmapsTU, p, 0);
	vec2 coords = position.xy * scale;	// TODO needed?

    // Used for Displacement and also for Fog later.
    // TODO Compute at vertex shader (it's E vector).
    float povDistance = length((ModelViewMatrix * vec4(position,1)).xyz);
		
#if 1   // Displace position along the normal in LOD zero.
        // TODO: And compute the new normal.
        vec3 normal;
        vec3 dH = vec3(gradient.xy, 0.0);
	    float displacement = 1.0 - smoothstep(0.0, 1.0*tessellationRange*(kernelSize-1), povDistance);
	    if( displacement > 0.0 )// NOTE: Only within the 1st LOD (otherwise you get cracks).
           /*&& color.a == 0.0 )*/ // Only for non water surfaces
	    { 
	    	const float LodBias = 0.0;
	    	//normal = normalize(vec3(gradient.xy/scale, 1));
            
            float blurLevel = 2;
            vec3 weight = getTriplanarWeightVector(/*normal*/normalize(vec3(gradient.xy/scale, 1)));
            vec4 luma4 = textureTriplanar(detailsTU, position.xyz, weight, LodBias + blurLevel);
            vec4 mixmap = blendMixmap(mixmap + luma4);

            //float luma = 0.2;
            vec4 luma4Dx = textureTriplanar(detailsDxTU, position.xyz, weight, LodBias + blurLevel);
		    vec4 luma4Dy = textureTriplanar(detailsDyTU, position.xyz, weight, LodBias + blurLevel);

            displacement *= tessellationDisplacement;
            float H = displacement*dot(mixmap, luma4);
			dH = vec3(
			    dot(mixmap, luma4Dx),
			    dot(mixmap, luma4Dy),
			    displacement
			);

			//vec3 position1 = position.xyz;
			//vec3 normal1   = normal.xyz;
                normal = normalize(vec3(gradient.xy, 1));
            displaceVertexAndRecomputeNormal(position, normal, H, dH);
	    
	        color += 0.00000000001*blendColor(color, mixmap, 0.30, 1.6);
	    
/*	        vec4 details = pow(texture(detailsTU, coords.xy, +4.5), vec4(1.0));
		    
	        vec4 displacementWeights = vec4(0.120, 0.040, 0.030, 0.050);
	        float extrusion = dot(displacementWeights, mixmap);
	        float luma = extrusion * dot(details, mixmap);
	        luma = (luma - extrusion/2) * displacement;
            vec3 N = normalize(vec3(gradient.xy, 1));
		    position += luma * N;
            #if 0  // Re-adjusting gradient after displacement
                // FIX Discontinuity
		        gradient.xy += (1.0 + dot(luma*gradient.xy,N.xy))*N.xy - luma*gradient.xy;
            #endif 
            */
	    }
#endif  


	// Output vertex
	tVertex.position = vec4(coords, position.z,	povDistance ); // TODO: povDistance is not currently used down the pipeline
	tVertex.gradient = gradient;
            //vec4(dH.xy, gradient.zw);
            //vec4( normalize(vec3(normal.xy/normal.z, 1.0)).xy, gradient.zw );
    tVertex.color	 = color;
	tVertex.mixmap	 = mixmap;
    gl_Position = vec4(position, 1.0);
}


GEOMETRY:
#version 400     
// ===================================================================                                                          
//   _____                   _              _____ _         _         
//  |   __|___ ___ _____ ___| |_ ___ _ _   |   __| |_ ___ _| |___ ___ 
//  |  |  | -_| . |     | -_|  _|  _| | |  |__   |   | .'| . | -_|  _|
//  |_____|___|___|_|_|_|___|_| |_| |_  |  |_____|_|_|__,|___|___|_|  
//                                  |___|   
//                          
// Transforms from model space to world space.
// TODO: Insert detail.
// 
uniform mat3 NormalMatrix;
uniform mat4 ModelViewMatrix;
uniform mat4 ModelViewProjectionMatrix;
uniform vec4 Light0_position; //
uniform float scale; //

layout(triangles) in;
layout(triangle_strip, max_vertices = 3) out;
 
in VertexData {
	vec4 position;
	vec4 gradient;
	vec4 color;
	vec4 mixmap;
} tVertex[];

out VertexData {
	vec4 position;  // Position in model space
	vec4 gradient;  // Gradients (T0 and T1)
	vec4 color;
	vec4 mixmap;
	vec3 N0;        // TEMP?
	vec3 E;		    // Position in world space
	vec3 L;         // Light in world space
	vec3 barycentric;
} gVertex;
	
void main() 
{
	for(int i=0; i<gl_in.length(); i++) 
	{
		gVertex.position    = tVertex[i].position;
		gVertex.gradient	= tVertex[i].gradient; 
		gVertex.color		= tVertex[i].color;
		gVertex.mixmap		= tVertex[i].mixmap;
		
		gVertex.N0	= NormalMatrix * normalize(vec3(tVertex[i].gradient.zw, 1));
		gVertex.E	= (ModelViewMatrix * gl_in[i].gl_Position).xyz; // length of it, is povDistance
		gVertex.L	= (ModelViewMatrix * vec4(Light0_position.xy/scale, Light0_position.zw)).xyz;	// TODO precompute?

		gVertex.barycentric =	i == 0 ? vec3(1,0,0) : 
								i == 1 ? vec3(0,1,0) : 
										 vec3(0,0,1) ;
										 
		gl_Position	= ModelViewProjectionMatrix * gl_in[i].gl_Position;
		EmitVertex();
	}
	EndPrimitive();
}


FRAGMENT:
#version 400  
// ===================================================================                                                                
//   _____                           _      _____ _         _         
//  |   __|___ ___ ___ _____ ___ ___| |_   |   __| |_ ___ _| |___ ___ 
//  |   __|  _| .'| . |     | -_|   |  _|  |__   |   | .'| . | -_|  _|
//  |__|  |_| |__,|_  |_|_|_|___|_|_|_|    |_____|_|_|__,|___|___|_|  
//                |___|     
// 
// Parallax mapping, bump mapping, texture mapping, AO, 
// diffuse, specular, indirect light, atmospheric scattering, 
// post effects.
	 
// UNIFORMS:
uniform int Wireframe   = 0;
uniform int DebugMode   = 0; const int ColorView = 1, HeightBlendView = 2, NormalView = 3, LightView = 4;
uniform int Bumps       = 1; //const int BumpsNormal = 1, BumpsMicro = 2;
uniform int Tessellator	= 1; // TEMP 
uniform int Diffuse		= 1;
uniform int Specular	= 1;
uniform int Indirect	= 1;
uniform int Sky			= 1;	
uniform int Fresnel		= 1;
uniform int Shadows		= 1;
uniform int PBR			= 1;
uniform int Scattering	= 1;
uniform int Gamma		= 1;
uniform int Contrast	= 1;
uniform int Unsaturate	= 1;
uniform int Tint		= 1;
uniform int Vignetting	= 1;

uniform sampler2D detailsTU;
uniform sampler2D detailsDxTU;
uniform sampler2D detailsDyTU;

uniform float bump_intensity = 0.400;
uniform float tessellationDisplacement; // TEMP

uniform vec4 defaultColorR;
uniform vec4 defaultColorG;
uniform vec4 defaultColorB;
uniform vec4 defaultColorA;

//////////////////////////// ROCK GRIT BONE SAND
uniform vec4  specmap = vec4(1.0, 1.0, 2.0, 2.0);
uniform vec4  specpow = vec4(9.9, 5.0, 5.0, 5.0);

uniform vec2 viewport;
uniform mat4 InverseRotationProjection;
uniform vec4 Light0_position;
uniform float visibileDistance;
uniform float AbsoluteTime;

uniform mat3 NormalMatrix; //// TEMP ////
uniform float scale; // TEMP
	
// INPUT:
in VertexData {
	vec4 position; // Position in model space
    vec4 gradient; // Gradients (T0 and T1)
	vec4 color;
	vec4 mixmap;
	vec3 N0;       // TEMP
	vec3 E;        // Position in world space
	vec3 L;        // Light in world space
	vec3 barycentric;
} gVertex;
 
// OUTPUT:
out vec4 fragColor;


////////////////////////////////////////////////////////////
// Texture mapping
//

vec4 noise(vec2 point) 
{		
    vec2 i = floor(point);
    vec2 f = fract(point);

	vec2 u = f*f*(3.0-2.0*f);  //f*f*f*(f*(6.0*f-15.0)+10.0);
	vec2 du = 6.0*f*(1.0-f);   //30.0*f*f*(f*(f-2.0)+1.0);
	
	const float WIDTH = 0.3137; // 13.0
    vec4 L = vec4(0.0, 1.0, WIDTH, WIDTH + 1.0);	
#if 0
    L = fract(43758.5453123 * sin(L + dot(i, L.yz)));
#else
    L = fract((L + dot(i, L.yz))*0.1731);
    L += L*(L + 1.0);
    L = fract(7.7771*L*L) - 0.5;
#endif
	L = vec4(L.x, L.y-L.x, L.z-L.x, L.x-L.y-L.z+L.w);
	return vec4(du*(L.yz + L.w*u.yx), L.x + L.y*u.x + L.z*u.y + L.w*u.x*u.y, 0.0 );
}

vec4 textureNoTile( sampler2D samp, in vec2 uv, float lodBias ) // TODO remove lodBias
{
    float period = 16.0;
    vec2 p = fract(uv/period)*period;
    p = abs(p - vec2(period)/2.0);

    float k = noise(p*1.0).z;
    
    vec2 duvdx = dFdx( uv );
    vec2 duvdy = dFdy( uv );
    
    float l = k*3.17;
    float f = fract(l);
    
    float ia = floor(l+0.5);
    float ib = floor(l);
    f = min(f, 1.0-f)*2.0;
    
    vec2 offa = sin(vec2(3.0,7.0)*ia);
    vec2 offb = cos(vec2(7.0,3.0)*ib);

    float v = 0.5;
    vec4 cola = textureGrad( samp, uv + v*offa, duvdx, duvdy );
    vec4 colb = textureGrad( samp, uv + v*offb, duvdx, duvdy );
    
    return mix( cola, colb, smoothstep(0.2, 0.8, f-0.1*dot(cola-colb, vec4(1.0))) );
}

vec3 getTriplanarWeightVector(vec3 N) 
{
    vec3 w = pow(abs(N), vec3(64.0));  
    //w = max(w, 0.00001); // layering
    return w / dot(w, vec3(1.0));
}

vec4 textureTriplanar(sampler2D detailsTU, vec3 position, vec3 weight, float lodBias)
{
#if 1
    return weight.x*texture(detailsTU, position.zy, lodBias) 
         + weight.y*texture(detailsTU, position.zx, lodBias) 
         + weight.z*texture(detailsTU, position.xy, lodBias);
#else
    return weight.x*textureNoTile(detailsTU, position.zy, lodBias) 
         + weight.y*textureNoTile(detailsTU, position.zx, lodBias) 
         + weight.z*textureNoTile(detailsTU, position.xy, lodBias);
#endif
}

// https://www.shadertoy.com/view/Ms3yzS
vec4 blendMixmap(vec4 mixmap) 
{
    const float MixmapBlending = 0.5; // 0.0 sharp, 0.5 smooth, 1.0 smoother
    float maxima = max(max(mixmap.x, mixmap.y), max(mixmap.z, mixmap.w));
    mixmap = max(mixmap - maxima + MixmapBlending, vec4(0.0));
    mixmap /= dot(mixmap, vec4(1.0));
    return mixmap;
}

vec4 blendColor(vec4 color, vec4 mixmap, float x1, float x2)
{
    color = mix(color, defaultColorR, smoothstep(x1, x2, mixmap.r))
          + mix(color, defaultColorG, smoothstep(x1, x2, mixmap.g))
          + mix(color, defaultColorB, smoothstep(x1, x2, mixmap.b))
          + mix(color, defaultColorA, smoothstep(x1, x2, mixmap.a));
    return color/4.0;
}

// http://weber.itn.liu.se/~stegu/TNM084-2017/bumpmapping/bumpmapping.pdf
// Also check doBumpMap() in Desert Canyon (https://www.shadertoy.com/view/Xs33Df)
void displaceVertexAndRecomputeNormal(inout vec3 p, inout vec3 N, float H, vec3 dH)
{
    p = p + H*N;
    N = normalize( (1.0 + dot(dH,N))*N - dH );
}
////////////////////////////////////////////////////////////
	
// TODO The whole environment sphere texture should be precomputed when time (and location?) changes significantly (?)
////////////////////////////////////////////////////////////
// Ambient sampling
// TODO: precompute the sky with sun and clouds, so that you just sample with E.
vec3 sampleAmbient(vec3 E, vec3 L, vec3 sunColor, vec3 zenithColor, vec3 horizonColor, vec3 groundColor, float shadowing, float sunHaloWidth)
{
	float EdotL = max(dot(E,L),0.0);
    vec3 skyColor  = mix(zenithColor, horizonColor, pow(1.0-E.z, 4.0));
	skyColor = mix(skyColor, sunColor, shadowing*pow(EdotL, sunHaloWidth));		
	skyColor = mix(skyColor, groundColor, smoothstep(-0.1, 0.0, -E.z));
	return skyColor;
}


////////////////////////////////////////////////////////////
// Physically Based Rendering
//
// https://www.shadertoy.com/view/ld3SRr7
const float PI = 3.14159265;

// https://typhomnt.github.io/teaching/ray_tracing/pbr_intro/
float DistributionGGX(vec3 N, vec3 H, float roughness)
{
    float a      = roughness*roughness;
    float a2     = a*a;
    float NdotH  = max(dot(N, H), 0.0);
    float NdotH2 = NdotH*NdotH;
    float denom  = NdotH2*(a2 - 1.0) + 1.0;
    denom		 = PI * denom * denom;
    return a2 / denom;
}

float GeometrySchlickGGX(float NdotV, float roughness)
{
    float r = roughness + 1.0;
    float k = (r*r) / 8.0;
    return NdotV / (NdotV * (1.0 - k) + k);
}

float GeometrySmith(vec3 N, vec3 V, vec3 L, float roughness)
{
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx2  = GeometrySchlickGGX(NdotV, roughness);
    float ggx1  = GeometrySchlickGGX(NdotL, roughness);
    return ggx1 * ggx2;
}

vec3 fresnelSchlick(float cosTheta, vec3 F0)
{
    return F0 + (1.0 - F0)*pow(1.000001 - cosTheta, 5.0);
}

// https://typhomnt.github.io/teaching/ray_tracing/pbr_intro/
// https://learnopengl.com/PBR/Lighting
// TODO disentangle matColor and F0 
vec3 REFLECTANCE(vec3 L, vec3 E, vec3 N, vec3 matColor, vec3 F0, float roughness, float metallic)
{
	vec3 H = normalize(E + L);

    // cook-torrance brdf
    float NDF = DistributionGGX(N, H, roughness);
    float G   = GeometrySmith(N, E, L, roughness);
    vec3 F    = fresnelSchlick(max(dot(H, E), 0.0), F0); // Ks
    
    vec3 kD = (vec3(1.0) - F) * (1.0 - metallic);

    vec3 numerator    = NDF * G * F;
    float denominator = 4 * max(dot(N, E), 0.0) * max(dot(N, L), 0.0) + 0.00001;
    vec3 specular     = numerator / denominator;

    return (Diffuse*kD*matColor/PI + Specular*specular /* *reliefMap*/) * max(dot(N, L), 0.0);
}

// https://learnopengl.com/PBR/Lighting
// From: https://www.shadertoy.com/view/ld3SRr
// Other sources:
// - learnopengl: https://learnopengl.com/PBR/Lighting
// - filament: https://google.github.io/filament/Filament.html


////////////////////////////////////////////////////////////
// Tone mapping
//
vec3 tone(vec3 color, float t) 
{
    return smoothstep(0.0, 1.0, color/(color + t)*(1.3 + t));
    //return color/(color + t)*(1.0 + t);
}

float hash1(vec2 x) {
	return fract(sin(dot(x, vec2(12.9898, 78.233)))*43758.5453);
}
/*
// TEMP will be used for microbumps?
vec4 noise(vec2 point) 
{		
    vec2 i = floor(point);
    vec2 f = fract(point);

	vec2 u = f*f*(3.0-2.0*f);  //f*f*f*(f*(6.0*f-15.0)+10.0);
	vec2 du = 6.0*f*(1.0-f);   //30.0*f*f*(f*(f-2.0)+1.0);
	
    vec4 L = vec4(0.0, 1.0, 57.0, 1.0 + 57.0);	
#if 0
    L = fract(43758.5453123 * sin(L + dot(i, L.yz)));
#else
    L = fract((L + dot(i, L.yz))*0.1301);
    L += 1.17*L*(L + 17.11);
    L = fract(2.71*L*L) - 0.5;
#endif
	L = vec4(L.x, L.y-L.x, L.z-L.x, L.x-L.y-L.z+L.w);
	return vec4(du*(L.yz + L.w*u.yx), L.x + L.y*u.x + L.z*u.y + L.w*u.x*u.y, 0.0 );
}
*/
//here!!
////////////////
////////////////////////////////////////////////////////////
// Volumetric
//
struct Plane {vec3 origin; vec3 normal; };
struct Ray   {vec3 origin; vec3 direction; };
float intersect(Plane plane, Ray ray)
{
    float denominator = dot(plane.normal, ray.direction);
    float Epsilon = 0.00001;
    if(abs(denominator) > Epsilon) {
        vec3 D = plane.origin - ray.origin;
        float t = dot(D, plane.normal)/denominator;
        if(t > Epsilon) {
            return t;
        }
    }
    return -1.0; // There is no "negative distance", right?
}

	

void main()
{	
	//////////////////////
	// Texture generation
	//
	float vertexLuma = 0.2;
	float luma      = vertexLuma;
	vec3 normal     = normalize(vec3(gVertex.gradient.xy, 1));
	vec4 matColor   = gVertex.color; 
	vec4 mixmap     = gVertex.mixmap;

    float dist      = length(gVertex.E);
	float textureFadingFactor = clamp(dist/(0.90*visibileDistance), 0.0, 1.0);
	
	if( textureFadingFactor <= 1.0 )
	{
        const float LodBias = -0.666; // 0.0 smooth, -0.5 sharper
        vec3 weight = getTriplanarWeightVector( normalize(vec3(gVertex.gradient.xy/scale, 1)) );
        vec4 luma4 = textureTriplanar(detailsTU,  gVertex.position.xyz, weight, LodBias); 

        float a1 = 0.7, a2 = 1.2, // (1.0 - a1)*4,  // LOD0
              a3 = 0.2, a4 = 0.2, a5 = 0.2;         // LOD1
        float sand0 = 0.8, grit0 = 0.2;             // SAND and GRIT on LOD0
        vec4 l1,l2;
        if(Tessellator > 0.0) {
            //luma4 = 0.666*luma4 + 0.333*textureTriplanar(detailsTU, gVertex.position.xyz*32.0, weight, LodBias).rbaa;
            //luma4 = (luma4 + 0.5*textureTriplanar(detailsTU, gVertex.position.xyz*32.0, weight, LodBias).rbaa)/1.5;
            l1 = luma4;
            l2 = textureTriplanar(detailsTU, gVertex.position.xyz*32.0, weight, LodBias);

            l1 = a1*l1 + a2*l1*l2.rbaa; /* l1*(0.2 + 2.7*l2);*/
            l1.a = mix(l1.a, l2.a, sand0); // sand
            //l1.g = mix(l1.g, l2.g, grit0); // grit

            //luma4.rgba = max(l1.rgba, a3*l2.bgaa);
            luma4.r = l1.r > a3*l2.b ? l1.r : a4*l2.b;
            luma4.g = l1.g > a3*l2.g ? l1.g : a4*l2.g;
            luma4.b = l1.b > a3*l2.a ? l1.b : a4*l2.a;
            luma4.a = l1.a > a3*l2.a ? l1.a : a4*l2.a;
        }
            
        mixmap = blendMixmap(mixmap + luma4); // moveable to tessellator ?
        matColor  = blendColor(gVertex.color, mixmap, 0.30, 1.96); // moveable to tessellator ?
		
		// Graciously fade texture mapping out with distance.
		luma = mix( dot(mixmap, luma4), vertexLuma, textureFadingFactor);
		matColor = mix(matColor, gVertex.color, textureFadingFactor);

		if( Bumps > 0.0 ) 
	    {
            vec4 luma4Dx =  textureTriplanar(detailsDxTU, gVertex.position.xyz, weight, LodBias);
            vec4 luma4Dy =  textureTriplanar(detailsDyTU, gVertex.position.xyz, weight, LodBias);

            if(Tessellator > 0.0) {
		    	//luma4Dx = 0.666*luma4Dx + 0.333*textureTriplanar(detailsDxTU, gVertex.position.xyz*32.0, weight, LodBias + 0.0).rbaa;
		        //luma4Dy = 0.666*luma4Dy + 0.333*textureTriplanar(detailsDyTU, gVertex.position.xyz*32.0, weight, LodBias + 0.0).rbaa;
                //luma4Dx = (luma4Dx + 0.5*textureTriplanar(detailsDxTU, gVertex.position.xyz*32.0, weight, LodBias + 0.0).rbaa)/1.5;
		        //luma4Dy = (luma4Dy + 0.5*textureTriplanar(detailsDyTU, gVertex.position.xyz*32.0, weight, LodBias + 0.0).rbaa)/1.5;
                vec4 l1Dx = luma4Dx;
                vec4 l1Dy = luma4Dy;
                vec4 l2Dx = textureTriplanar(detailsDxTU, gVertex.position.xyz*32.0, weight, LodBias + 0.0);
                vec4 l2Dy = textureTriplanar(detailsDyTU, gVertex.position.xyz*32.0, weight, LodBias + 0.0);

                l1Dx = a1*l1Dx + a2*l1Dx*l2.rbaa + a2*l1*l2Dx.rbaa; 
                l1Dy = a1*l1Dy + a2*l1Dy*l2.rbaa + a2*l1*l2Dy.rbaa;
                l1Dx.a = mix(l1Dx.a, l2Dx.a, sand0); // sand
                l1Dy.a = mix(l1Dy.a, l2Dy.a, sand0); // sand
                //l1Dx.g = mix(l1Dx.g, l2Dx.g, grit0*2.0); // grit
                //l1Dy.g = mix(l1Dy.g, l2Dy.g, grit0*2.0); // grit

                l1Dx.r = l1.r > a3*l2.b ? l1Dx.r : a5*l2Dx.b;
                l1Dx.g = l1.g > a3*l2.g ? l1Dx.g : a5*l2Dx.g;
                l1Dx.b = l1.b > a3*l2.a ? l1Dx.b : a5*l2Dx.a;
                l1Dx.a = l1.a > a3*l2.a ? l1Dx.a : a5*l2Dx.a;
                l1Dy.r = l1.r > a3*l2.b ? l1Dy.r : a5*l2Dy.b;
                l1Dy.g = l1.g > a3*l2.g ? l1Dy.g : a5*l2Dy.g;
                l1Dy.b = l1.b > a3*l2.a ? l1Dy.b : a5*l2Dy.a;
                l1Dy.a = l1.a > a3*l2.a ? l1Dy.a : a5*l2Dy.a;

                luma4Dx = l1Dx;
                luma4Dy = l1Dy;
            }

            // Compute H and dH
            // NOTE: Height displacement is disabled here
            float H = 0.0; // Height alteration doesn't matter in bump mapping.
			vec3 dH = vec3(
			    dot(mixmap, luma4Dx),
			    dot(mixmap, luma4Dy),
			    0.0 //tessellationDisplacement // Dz doesn't matter because it's texture mapping, no relief here. 
                // TODO: But it can be useful to inject procedural bump mapping in here.
                //0.50*hash1(gVertex.position.xy*16)
                //noise(gVertex.position.xy*1.0)
			);
			
			// Energy adujustment across LODs (empiric).
			//float scale00 = 1 + 0.0000030*log(scale); 
			
			// Graciously fade bumps out with distance.
		    float _bump_intensity = mix(bump_intensity, 0.0, textureFadingFactor);
/*
            // TEMP microbumps
            vec2 bxy = gVertex.position.xy + gVertex.position.zz/16.0;
            vec3 b = 0.2*Contrast*_bump_intensity*noise(bxy*1024.0*4.0).xyz;
            H += b.z;
            dH.xy += b.xy;
*/			
			//H  *= _bump_intensity * scale00; 
			dH *= _bump_intensity;// * scale00;
			
			vec3 P = gVertex.position.xyz;
            displaceVertexAndRecomputeNormal(P, normal, H, dH);

            // TEMP microbumps
            //vec3 b = 0.2*Contrast*_bump_intensity*normalize(noise((gVertex.position.xy + gVertex.position.zz)*1024.0*4.0).xyz);
            //normal = normalize(normal + b);
		}
	}
	
	/////////////////////////
	// Lighting
	//
	
	// Model space
    vec2 ndcoords = gl_FragCoord.xy/viewport*2.0 - 1.0;
	vec3 E = normalize((InverseRotationProjection * vec4(ndcoords,0,1)).xyz);
	vec3 L = normalize(Light0_position.xyz);
	vec3 I = normalize(vec3(-L.x, -L.y, 0.0));
	vec3 N = normalize(vec3(normal.xy/scale, normal.z));
	vec3 N0 = normalize(vec3(gVertex.gradient.zw/scale, 1));
	
	// Ambient occluders
	float lfShadow = clamp(4.0*dot(N0,L), 1.0 - Shadows, 1.0);
	float occlusion = pow(luma, 1.0);
	float relief	= smoothstep(0.2, 0.7, luma);

	// Sampling ambient light
	float daylight		= smoothstep(0.0, 0.1, L.z);
	float sunHaloWidth  = mix(2, 30, smoothstep(0.0, 0.4, L.z));
	vec3 sunColor		= mix(vec3(0.80, 0.40, 0.20), vec3(1.00, 0.90, 0.75), smoothstep( 0.0, 0.3, L.z));
	vec3 zenithColor	= mix(vec3(0.01, 0.02, 0.04), vec3(0.35, 0.48, 0.60), smoothstep(-0.8, 0.0, L.z));
	vec3 horizonColor	= mix(vec3(0.02, 0.03, 0.04), sunColor,               smoothstep(-0.4, 0.5, L.z));
	vec3 groundColor	= vec3( dot( mix(0.03*zenithColor, 1.4*zenithColor,   smoothstep( 0.0, 0.4, L.z)), vec3(0.22,0.33,0.45)) );
	vec3 specularColor	= sampleAmbient(reflect(L,N), L, sunColor, zenithColor, horizonColor, groundColor, lfShadow, sunHaloWidth);
	vec3 fresnelColor	= sampleAmbient(reflect(E,N), L, sunColor, zenithColor, horizonColor, groundColor, lfShadow, sunHaloWidth);
	
	// Fresnel
	float F0		= dot(mixmap, specmap);
	float specPower	= dot(mixmap, specpow);
	float specular  = F0 * pow(max(0.0, dot(E, reflect(L, N))), specPower);
	float fresnel0   = pow(1.0 - abs(dot(E,N)), specPower);
	float fresnel   = mix(F0*fresnel0, F0 + fresnel0, 0.1); // 1.0 => pure Schlick's approximation
	
	vec3 light = vec3(0.0);
	
if( bool(PBR) ) 
{
	float metallic = 0.0;
	float roughness = 0.0;
	vec3 diffuseColor = matColor.rgb;
	
	vec3 F0 = mix(vec3(0.04), diffuseColor, metallic);	// Average F0 for dielectric materials
	
    //light += 0.00 * zenithColor * matColor.rgb * (1.0 - occlusion); // Ambient ?
    light += 2.00 * Diffuse  * occlusion * daylight * lfShadow * sunColor * REFLECTANCE(L, E, N, diffuseColor, F0, roughness, metallic);
    light += 0.14 * Indirect * occlusion * daylight * sunColor * REFLECTANCE(I, E, N, diffuseColor, F0, roughness, metallic);
    light += 0.01 * Sky		 * occlusion *			  zenithColor * N.z; //REFLECTANCE(vec3(0,0,-1), E, N, diffuseColor, F0, roughness, metallic);
    light += 0.01 * Fresnel  * relief	 * (fresnelColor - light) * fresnel;
} 
else 
{ 
	// This formulation is based on:
	// - a simplified model of GI where specular-fresnel-sky complement one another and an extra indirect source of light is added.
	// - the specular component is not masked out completely with lambertian (neither N.L or N0.L) and no conservation of energy is applied.
	// - Fresnel is applied with a tweaked formula that includes the Schlick approximation.

	// TODO: make input for the material: metallicity, roughness and diffuseColor
	// TODO: make input for the pixel: relief, AO, etc.. (TBD)

	// TODO ambient = 0.04 * (1.0-occlusion) * sunColor; ?
	light += 0.40 * Diffuse  * occlusion * daylight * lfShadow * sunColor * max(0.0, dot(N,L)) ;//* (1.0 - specular);
	light += 0.06 * Specular * relief	 * daylight * mix(0.2, 1.0, lfShadow) * specularColor * specular;//* max(0.0, dot(N,L));
	light += 0.01 * Indirect * occlusion * daylight * sunColor * max(0.0, dot(N,I)); 
	light += 0.02 * Sky      * occlusion *			  zenithColor * N.z;
	light += 0.02 * Fresnel  * relief	 * (fresnelColor - light) * fresnel;
}
    
    // Tone mapping
    vec3 color = tone(1.00*light*matColor.rgb, 0.1); 
/*
    // Volumetric
    Plane plane;
    plane.origin = vec3(gVertex.position.xy, 0.3);
    plane.normal = vec3(0,0,1);
    Ray ray; // = {vec3(), vec3()};
    ray.origin = vec3(gVertex.position.xyz); // ?
    ray.direction = E;
*/
	// Scattering
	if( Scattering > 0 ) {
		//dist = length(EE); //?
	    float EdotL = max(0.0, dot(E,L));
	    float scattering = smoothstep(+0.05, 0.5, L.z) * (1.0 - exp(-0.0200*dist)) * pow(EdotL, 8.0);
	    scattering = min(4.0*scattering, 0.1); // lens effect
		color += mix(lfShadow, 1.0, 0.7) * scattering * sunColor;
		color = mix(color, groundColor, vec3(0.98,1.00,1.09) * smoothstep(0.0, visibileDistance, dist /*+ 0.0*volumetric*/));
	}



	// Color tuning
	float gamma = Gamma > 0.0 ? 2*2.2 : 2*1.8;
	color = pow(color, vec3(1.0/gamma));	
    color = mix(color, color*color*(3.0-2.0*color), 0.4 * Contrast);
	color = mix(color, vec3(dot(color, vec3(0.299, 0.587, 0.114))), 0.2 * Unsaturate);
	color *= mix(vec3(1.0), vec3(1.06, 1.05, 1.00), 0.4 * Tint);	
	color *= mix(1.0, pow(2.0*(ndcoords.x*ndcoords.x-1.0)*(ndcoords.y*ndcoords.y-1), 0.20), 0.5 * Vignetting);

    // TEMP
	color += 0.00000000001 * Wireframe * Fresnel * Scattering * PBR * Sky * Gamma * Contrast * Unsaturate * Tint * Vignetting * NormalMatrix[0].x ;
	
	// Debug controls
   	if( DebugMode == ColorView ) {
	    color = 4.0 * color.rgb * occlusion;
	} else if( DebugMode == LightView ) {
		color = 4.0 * light;
	} else if( DebugMode == NormalView ) {
		color = normalize(vec3(normal.xy/scale, normal.z))*0.5 + 0.5;
	} 
	if( Wireframe > 0 ) {
	    // Wireframe
		vec3 d = fwidth(gVertex.barycentric);
		vec3 t = smoothstep(vec3(0.0), d*1.5, gVertex.barycentric);
		float edgeFactor = min(min(t.x, t.y), t.z);
		color = mix(pow(color.xyz,vec3(0.8)), pow(color.xyz,vec3(1.2)), edgeFactor);	    
	    // TileFrame   
	    vec2 p = fract(gVertex.position.xy/scale);
	    float m = min(min(p.x, p.y), min(1.0-p.x, 1.0-p.y));
	    color.gb -= 0.05*(1.0-smoothstep(0.0, 0.05, m)); 
	}

    // Banding removal
	color.xyz += 0.02*(-0.5 + hash1(ndcoords + fract(AbsoluteTime)));

	fragColor = vec4(color.rgb, 1.0);
}
