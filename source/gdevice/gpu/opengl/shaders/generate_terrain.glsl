COMPUTE:
#version 430
// ================================================================
//  _____                   _          _____ _         _         
// |     |___ _____ ___ _ _| |_ ___   |   __| |_ ___ _| |___ ___ 
// |   --| . |     | . | | |  _| -_|  |__   |   | .'| . | -_|  _|
// |_____|___|_|_|_|  _|___|_| |___|  |_____|_|_|__,|___|___|_|  
//                 |_|     

uniform vec2  offset;
uniform float size;
// TODO: Make uniforms (?)
#define RES 17      //17	// NOTE change also into gdevice_parameters.h
#define ZOOM 1.5    // Controls both domain and height scale, to keep proportions.
//const vec3 scale = vec3( vec2(0.005)*ZOOM, 50/ZOOM );
const vec3 scale = vec3( vec2(0.005)*ZOOM, 200/ZOOM );

layout (binding=0, rgba32f) uniform writeonly image2D quartetsIU;
layout (binding=1, rgba32f) uniform writeonly image2D gradientsIU;
layout (binding=2, rgba32f) uniform writeonly image2D colorsIU;
layout (binding=3, rgba32f) uniform writeonly image2D mixmapsIU;



//  _____     _         
// |   | |___|_|___ ___ 
// | | | | . | |_ -| -_|
// |_|___|___|_|___|___|
//
// https://www.shadertoy.com/view/WlfSzX
    
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


vec4 saturate(vec4 t, float z0, float z1);

vec4 triangle(in vec2 p, float pack = 0.12, float erode = 0.47)
{
    p = fract(p) - 0.5;
    
    // TODO: smooth edges instead of avoiding them.
    const float Epsilon = 0.0000001;
    vec2 dp = vec2(abs(p.x) >= 0.5-Epsilon || abs(p.x)<=Epsilon ? 0.0 : abs(p.x)/p.x, 
                   abs(p.y) >= 0.5-Epsilon || abs(p.y)<=Epsilon ? 0.0 : abs(p.y)/p.y);
                    
    vec4 a = vec4(dp, abs(p));
    vec4 t = a.z > a.w ? vec4(a.x, 0.0, a.z, 0.0) : vec4(0.0, a.y, a.w, 0.0); // maximum
    t = saturate(t, pack, erode);
    return t;
}
    

// Cheaper than Voronoi.
vec4 triangular(in vec2 point, float scale = 1.0, float pack = 0.12, float erode = 0.30 )
{
    mat2 R1 = mat2( -0.7373, -0.6755, +0.6755, -0.7373 ); // 137.5077 (Golden Angle)
    mat2 R2 = mat2( +0.3623, -0.9320, +0.9320, +0.3623 ); // 19.6439 (Ga/7)
    mat2 R3 = mat2( -0.7159, -0.6981, +0.6981, -0.7159 ); // 27.50154 (Ga/5)
  
    vec4 F1 = vec4(0.0, 0.0, 1.0, 0.0);
    vec4 F2 = vec4(0.0, 0.0, 1.0, 0.0);
    
    point *= scale;
    vec4 d = triangle(point, pack, erode); 
    if( d.z<F1.z ) { F2 = F1; F1 = d; } else if( d.z<F2.z ) F2 = d; 

    d = triangle(R1*point + R1[0], pack, erode); 
    d.xy *= R1;
    if( d.z<F1.z ) { F2 = F1; F1 = d; } else if( d.z<F2.z ) F2 = d; 

    d = triangle(R2*point + R2[0], pack, erode); 
    d.xy *= R2;
    if( d.z<F1.z ) { F2 = F1; F1 = d; } else if( d.z<F2.z ) F2 = d; 
  
    d = triangle(R3*point + R3[0], pack, erode);  
    d.xy *= R3;
    if( d.z<F1.z ) { F2 = F1; F1 = d; } else if( d.z<F2.z ) F2 = d; 
    
    d = vec4( 3.0*(F2-F1).xyz, 0.0 );
    d.xy *= scale; 
    return d;
}

//
// Noise algebra
//
const vec4 unit = vec4(0.0, 0.0, 1.0, 0.0);
vec4 noise(vec2 point, mat2 scale)  { vec4 n = noise(scale*point); n.xy *= scale; return n; }
vec4 noise(vec2 point, float scale) { vec4 n = noise(scale*point); n.xy *= scale; return n; }
vec4 bias(vec4 n, float offset )    { return n + offset * unit; }
vec4 multiply(vec4 n1, vec4 n2 )    { return vec4(n1.xy * n2.z + n2.xy * n1.z, n1.z * n2.z, n1.z * n2.w + n2.z*n1.w); }
//vec4 quotient(vec4 n1, vec4 n2)		{ return vec4((n1.xy * n2.z - n2.xy * n1.z)/(n2.z*n2.z),  n1.z/n2.z, 0.0); }	
vec4 lerp(vec4 a, vec4 n1, vec4 n2 ){ return multiply(vec4(0.0, 0.0, 1.0, 0.0)-a,n1) + multiply(a,n2); }
//vec4 power(vec4 n, float k)         { return vec4(k*pow(n.z, k-1.0)*n.xy, pow(n.z, k), k*pow(n.w, k+0.1)); }
vec4 power(vec4 n, float k)           { return vec4(k*pow(n.z, k-1.0)*n.xy, pow(n.z, k), n.w); }
vec4 maximum(vec4 n1, vec4 n2 )     { return n1.z > n2.z ? n1 : n2; }
vec4 minimum(vec4 n1, vec4 n2 )     { return n1.z < n2.z ? n1 : n2; }
vec4 saturate(vec4 n, float z1, float z2)   { return n.z < z1 ? z1*unit : n.z > z2 ? z2*unit : n; }
vec4 saturate(vec4 n)               { return saturate(n, 0.0, 1.0); }
//float converge(float x0, float x1, float x) { return 1.0/(x + 1.0/(x0-x1)) + x1; } 
vec4 saturate(vec4 n, vec4 a, vec4 b)     { return n.z < a.z ? a : n.z >= b.z ? vec4(-b.xy, b.zw) : n; }

vec4 smoothStep(float h0, float h1, vec4 n) { n = vec4(n.xy, n.z - h0, 0.0)/(h1 - h0); n = saturate(n, 0.0, 1.0); return multiply(multiply(n,n), bias(-2.0 * n, +3.0)); }
vec4 absolute(vec4 n, float zero)   { return n.z >= zero ? n : -n; }    
vec4 invert(vec4 n)                 { float z = 1.0/(n.z + 1.0); return vec4(-z*z*n.xy, z, 0.0); }
vec4 invert2(vec4 n)			    { return vec4(-n.xy, 1.0 - n.z, 0.0); }
vec4 minus(float t, vec4 n)         { return vec4(-n.xy, t - n.z, 0.0); }
vec4 tone(vec4 n, float t)			{ return smoothStep(0.0, 1.0, multiply(n, invert(bias(n,t))))*(1.0 + t); }


vec4 smoothFloor(vec4 n, float c) 
{
    vec4 a = vec4(n.xy, fract(n.z), 0.0);
    vec4 b = vec4(0.0, 0.0, floor(n.z), 0.0);
    return ((power(a,c) - power(invert2(a),c))/2.0) + b;
}

//  _____             _   _             _    _____                   _            _____     _   _         
// |   __|___ ___ ___| |_|_|___ ___ ___| |  | __  |___ ___ _ _ _ ___|_|___ ___   |     |___| |_|_|___ ___ 
// |   __|  _| .'|  _|  _| | . |   | .'| |  | __ -|  _| . | | | |   | | .'|   |  | | | | . |  _| | . |   |
// |__|  |_| |__,|___|_| |_|___|_|_|__,|_|  |_____|_| |___|_____|_|_|_|__,|_|_|  |_|_|_|___|_| |_|___|_|_|
//                                                                                                   

vec4 fbm(vec2 p, int octaves, 
    float amplitude = 1.0,
    float gain = 0.5,
    mat2 frequency = mat2(1.0,0.0,0.0,1.0),
    mat2 lacunarity = 2.03*mat2(0.8,-0.6,0.6,0.8) )
{
    vec4 signal = vec4(0.0);
    for( int i=0; i<octaves; i++ ) {
        signal += amplitude*noise(p, frequency);
		amplitude *= gain;
		frequency *= lacunarity;
    }
    return signal;
}
    
vec4 fbm_triangular(vec2 p, int octaves, 
        float pack = 0.12, float erode = 0.30,
    float gain = 0.5,
    mat2 frequency = mat2(1.0,0.0,0.0,1.0),
    mat2 lacunarity = 2.03*mat2(0.8,-0.6,0.6,0.8) )
{
    vec4 signal = vec4(0.0);
    float amplitude = 1.0;
    for( int i=0; i<octaves; i++ ) {
        signal += triangular(p, frequency, pack, erode);
		amplitude *= gain;
		frequency *= lacunarity;
    }
    return signal;
}
    
vec4 hybrid(vec2 point, int octaves, 
    inout vec4 signal, // = vec4(0.0), 
    inout vec4 weight, // = vec4(0.0, 0.0, 0.17, 0.0),
    inout float scale,
    inout float frequency)
{  
    float H = 0.11;             // 0.13 - The lower, the rougher
    float offset = 0.62;	    // The heigher, the rougher
    float lacunarity = 2.11;    // 2.00 - Decomposes bodies but increases spikes (?)
    float maxFrequency = 17.0;  // The lower, the rougher
    float maxWeight = 0.05;     // 1.00 - Low values reduce the spikes, reduce height, introduce artifacts
 				
    for(int i=0; i<octaves; i++) {
        vec4 noise = noise(point, scale);
        noise = bias(noise, offset) * pow(frequency, -H); 
        signal += weight; 
        weight = multiply(weight, noise);
        weight = minimum(weight, maxWeight*unit); 
        weight.w = dot(weight.xy, weight.xy);
        frequency = min(frequency*lacunarity, maxFrequency);
	    scale *= lacunarity;
	    //point += 0.001*scale;	
    }
    
    return signal;
}
                              
//   _____     _       _                   
//  |   __|_ _| |_ ___| |_ ___ ___ ___ ___ 
//  |__   | | | . |_ -|  _| .'|   |  _| -_|
//  |_____|___|___|___|_| |__,|_|_|___|___|
//     
                                 
struct Substance 
{
	vec4 color;
	vec4 mixmap;
};

// Mixing
Substance substanceMix(Substance s1, Substance s2, float a) {
    a = clamp(a, 0.0, 1.0);
    Substance substance;
    substance.color  = mix(s1.color,  s2.color,  a);
    substance.mixmap = mix(s1.mixmap, s2.mixmap, a);
    return substance;
}

// http://www.iquilezles.org/www/material/function2009/function2009.pdf
Substance substanceMix(Substance s1, Substance s2, float a, float b, float h,	
    float c = 0.20, float d = 0.80, float slope = 1.0) {
    float t = smoothstep(a + c*slope, b + d*slope, h);
    Substance substance;
    substance.color  = mix(s1.color,  s2.color,  t);
    substance.mixmap = mix(s1.mixmap, s2.mixmap, t);
    return substance;
}
	
Substance getSubstance(vec4 t, vec4 rock, vec4 dump)
{ 
	float slope = 1.0 - normalize(vec3(t.xy, 1.0)).z;
	float height = t.z;
	//float peak = t.w;

	float some = 0.5 + noise(t.xy, scale.x*10000).z;
	float meso = 1.0 - some;
	float less = pow(some, 2.0);
	float more = 1.0 - less;
	
	//Substance ERROR = {vec4(1.0, 0.0, 0.0, 0.0), vec4(1.0, 0.0, 0.0, 0.0)};
	//if( some<0.5 || some>1.0 )
	//    return ERROR;
	    

#if 1 // Single detail substances
    // ===================  Red   Green Blue  Spec  ===== Rock  Grit  Bran  Sand
	Substance ROCK = { vec4(0.36, 0.30, 0.26, 0.00), vec4(1.00, 0.00, 0.00, 0.00) };
    Substance GRIT = { vec4(0.46, 0.38, 0.35, 0.00), vec4(0.00, 1.00, 0.00, 0.00) };
    Substance BRAN = { vec4(0.34, 0.26, 0.22, 0.00), vec4(0.00, less, 1.2*some, 0.00) };
    Substance SAND = { vec4(0.72, 0.54, 0.43, 0.00), vec4(0.00, 0.00, 0.00, 1.1 + 0.2*more) }; 
#else // Testing
    Substance ROCK = { vec4(1.00, 0.00, 0.00, 0.00), vec4(1.0, 0.0, 0.0, 0.0) };
    Substance GRIT = { vec4(0.00, 1.00, 0.00, 0.00), vec4(0.0, 1.0, 0.0, 0.0) };
    Substance BRAN = { vec4(0.00, 0.00, 1.00, 0.00), vec4(0.0, 0.0, 1.0, 0.0) };
    Substance SAND = { vec4(1.00, 0.00, 0.00, 0.00), vec4(0.0, 0.0, 0.0, 1.0) }; 
#endif

    // Flow map
    vec2 d = t.xy/length(t.xy);
    float f = atan(d.y, d.x);
    f = (f + 3.14159265)/(2*3.14159265); // [0..1]
    f = pow(f, 2.0);
    f = (f*f - 5)*(f*11 + 3)/17;
    f = abs(fract(f) - 0.5)*2.0;

    // Sand on slopes and cobs on flow map.
    f = smoothstep(0.000, 0.920, f);

    Substance gritt =  { SAND.color, mix(SAND.mixmap, GRIT.mixmap, f) };

    Substance substance = 
        slope > 0.40 ? ROCK : 
        slope > 0.30 ? GRIT : 
        slope > 0.05 ? gritt :
        SAND;


#if 0  // Snow
    float h = smoothstep(0.20, 0.40, height );
    float e = smoothstep(1.0 - 0.5*h, 1.0 - 0.2*h, 1 - slope);
    float o = 0.4 + 0.6*smoothstep(0.0, 0.1, h*h);
    float s = h*e*o;
    //col = mix( col, 0.29*vec3(0.62,0.65,0.7), smoothstep( 0.1, 0.9, s ) );
    vec4 snow_color = 0.90*vec4(0.62, 0.65, 0.7, 0.0);
    vec4 snow_mixmap = SNOW;
    substance.color  = mix( substance.color,  snow_color,  0.0*smoothstep(0.01, 0.99, s) );
    substance.mixmap = mix( substance.mixmap, snow_mixmap, 0.0*smoothstep(0.41, 0.99, s) );
#endif


	return substance;
}

//                             
//   _____         _           
//  |  |  |___ ___| |_ ___ _ _ 
//  |  |  | -_|  _|  _| -_|_'_|
//   \___/|___|_| |_| |___|_,_|
//            
	
struct Vertex
{
	vec4 position;
	vec4 gradient;
	vec4 color;
	vec4 mixmap;
	
	vec4 coarserPosition;
	vec4 coarserGradient;
	vec4 coarserColor;
	vec4 coarserMixmap;
};

// Version with domain warping
vec4 terrain(vec4 U, vec4 V, int octaves, 
    inout vec4 signal,
    inout vec4 weight,
    inout float scale,
    inout float frequency)
{
    vec4 t = 1.0*hybrid(vec2(U.z, V.z), octaves, signal, weight, scale, frequency);

    // Chain rule.
    t.x = t.x*U.x + t.y*V.x;
    t.y = t.x*U.y + t.y*V.y;
    return t;
}

Vertex getVertex(ivec2 ij)
{		
	vec2 point = offset + vec2(ij)*size/(RES-1);
	point *= scale.xy; // NOTE: Must apply to gradient as well.

    int octaves = 13; 
    int lodOctaveBudget = int(octaves - 0.0*log2(size)); // TODO: enable
    int shadowfreq = int(lodOctaveBudget*0.40); // 0.40
    int spikesfreq = int(lodOctaveBudget*0.20); // 0.20
    int terrainFreq = lodOctaveBudget - shadowfreq - spikesfreq;

    vec4 signal = vec4(0.0);
    vec4 weight = vec4(0.0, 0.0, 0.17, 0.0);
    float ZOOM0 = 1.0;
    float scale0 = ZOOM0;
    float frequency = 0.73;
   
#if 1 
    // Domain warping  // NOTE: Must apply to gradient as well.
    float dwFrequency = 1.2; // 2.0
    float dwAmplitude = 0.2; // 1.0 // NOTE: Set to zero to disable
    vec4 dwPointU = dwAmplitude * fbm((point + 0.000)*dwFrequency, 4);
    vec4 dwPointV = dwAmplitude * fbm((point + 123.1)*dwFrequency, 4);
    dwPointU.xy *= dwFrequency;
    dwPointV.xy *= dwFrequency;
    dwPointU = vec4(dwPointU.xy + vec2(1.0, 0.0), dwPointU.z + point.x, 0.0);
    dwPointV = vec4(dwPointV.xy + vec2(0.0, 1.0), dwPointV.z + point.y, 0.0);
    vec2 dwPoint = vec2(dwPointU.z, dwPointV.z); 
    vec4 c0 = terrain(dwPointU, dwPointV, shadowfreq-1,   signal, weight, scale0, frequency);
    vec4 t0 = terrain(dwPointU, dwPointV, 1,              signal, weight, scale0, frequency);
    vec4 c1 = terrain(dwPointU, dwPointV, terrainFreq-1,  signal, weight, scale0, frequency);
    vec4 t1 = terrain(dwPointU, dwPointV, 1,              signal, weight, scale0, frequency);
#else
    vec4 c0 = hybrid(point, shadowfreq-1,   signal, weight, scale0, frequency);
    vec4 t0 = hybrid(point, 1,              signal, weight, scale0, frequency);
    vec4 c1 = hybrid(point, terrainFreq-1,  signal, weight, scale0, frequency);
    vec4 t1 = hybrid(point, 1,              signal, weight, scale0, frequency);
#endif

    // The domain scale is applied to gradient as well.
    t0.xy *= -scale.xy;
    t1.xy *= -scale.xy;
    
    // Height scale is applied to gradient but not to height yet
    // because I want height be somewhat normalized when computing the substance. 
    // That means: the substance is computed on correct steepness and on normalized height.
    t0.xy *= scale.z;
    t1.xy *= scale.z;
    
	
	
	// TEMP
	vec4 t01 = multiply(invert2(t0), power(multiply(t1-t0, invert2(t0)), 2.0)) * 50.0; // Great dump
	//vec4 t01 = t1-t0;
	
	float tr3scale = 19.0;
	float tr4scale = 13.0;
    vec4 tr3 = fbm_triangular( point*tr3scale, 3, 0.00, 0.47, 0.6) * vec4(tr3scale,  tr3scale, 1.0, 1.0);
    vec4 tr4 = fbm_triangular(-point*tr4scale, 3, 0.20, 0.38, 0.6) * vec4(-tr4scale, -tr4scale, 1.0, 1.0);  
    
    // Define spike range
    vec4 h0 = 0.011*unit;           
	vec4 h1 = h0 + 0.003*bias(tr4*0.6, +0.4);
	
	vec4 dump = t0 + saturate(t01, 0.0*unit, h0);
	vec4 rock = bias(saturate(t01, h0, h1), -h0.z);
	//vec4 spikes = bias(saturate(t01, h1, 0.016*unit), -h1.z);

	{
        // Add some plateaus on the rock
        float stepHeight = 723.0;
        float hardness = 6.0;
        rock = smoothFloor(rock*stepHeight, hardness)/stepHeight;
    }

    // Clamp the spikes and raise rocks
	t1 = dump + 3.0*rock; // + 0.0*multiply(rock, spikes);
	
	Substance substance = getSubstance(t1, rock/(h1-h0).z, dump/(t0+h0).z);
	

    t1.z *= scale.z; 
    
	vec4 position = t1; // Here only z is actually used.
    vec4 gradient = vec4(t1.xy, t0.xy) * size; // Applying tile domain scale to gradient.
    vec4 color    = substance.color;
    vec4 mixmap   = substance.mixmap;
    
    vec4 coarserPosition;
	vec4 coarserGradient;
	vec4 coarserColor;
	vec4 coarserMixmap;
	if( (ij.x % 2 + ij.y % 2) == 0 ) {
	    Substance substance = getSubstance(c1, rock, dump);
	    c1.z *= scale.z; 
	    coarserPosition = c1;
	    coarserGradient = vec4(c1.xy, c0.xy) * size;
	    coarserColor    = substance.color;
        coarserMixmap   = substance.mixmap;
	}

	return Vertex(  
		position,
		gradient, 
		color,
		mixmap,	
		coarserPosition,
		coarserGradient,
	    coarserColor,
	    coarserMixmap
	);
} 
                 
//            _     
//  _____ ___|_|___ 
// |     | .'| |   |
// |_|_|_|__,|_|_|_|
//                 
// Every execution generates a terrain quad.

layout( local_size_x = 9, local_size_y = 9 ) in; // Note: RES/2+1: 33 => 17, 17=>9

void main() 
{  
	ivec2 ij = ivec2(gl_GlobalInvocationID.xy) * 2;	
	
	ivec2 i0 = ij + ivec2(0,0);
	ivec2 i1 = ij + ivec2(1,0);
	ivec2 i2 = ij + ivec2(0,1);
	ivec2 i3 = ij + ivec2(1,1);
	
	Vertex v0 = getVertex(i0);
	Vertex v1 = getVertex(i1);
	Vertex v2 = getVertex(i2);
	Vertex v3 = getVertex(i3);
	
	//if( i0.x == 0 || i0.y == 0 ) v0.color *= 0.3; // To show tiles.
	imageStore( quartetsIU,	 i0, vec4(v0.position.z, v0.position.z, v0.position.z, v0.position.z));
	imageStore( gradientsIU, i0, v0.gradient);
	imageStore( colorsIU,    i0, v0.color);
	imageStore( mixmapsIU,   i0, v0.mixmap);
	 
	if(i1.x < RES-1) {	
		imageStore( quartetsIU,  i1, vec4(v1.position.z, v0.position.z, v1.position.z, v0.position.z));
		imageStore( gradientsIU, i1, v1.gradient);
		imageStore( colorsIU,    i1, v1.color);
		imageStore( mixmapsIU,   i1, v1.mixmap);
	}

	if(i2.y < RES-1) {
		imageStore( quartetsIU,  i2, vec4(v2.position.z, v2.position.z, v0.position.z, v0.position.z));
		imageStore( gradientsIU, i2, v2.gradient);
		imageStore( colorsIU,    i2, v2.color);
		imageStore( mixmapsIU,   i2, v2.mixmap);
	}
	
	if(i3.x < RES-1 && i3.y < RES-1) {
		imageStore( quartetsIU,  i3, vec4(v3.position.z, v2.position.z, v1.position.z, v0.position.z));
		imageStore( gradientsIU, i3, v3.gradient);
		imageStore( colorsIU,    i3, v3.color);
		imageStore( mixmapsIU,   i3, v3.mixmap);
	}
}
