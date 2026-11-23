shader_type spatial;
render_mode cull_disabled, unshaded, world_vertex_coords;
uniform sampler2D relief : filter_linear, repeat_disable;
uniform vec2 atlas_origin = vec2(-120.0,-100.0);
uniform vec2 atlas_size = vec2(240.0,200.0);
uniform float tide = 0.0;
uniform float darkness = 0.0;
uniform float squall = 0.0;
uniform vec3 deep : source_color = vec3(0.10,0.37,0.44);
uniform vec3 shallow : source_color = vec3(0.32,0.65,0.64);
uniform vec3 foam : source_color = vec3(0.86,0.91,0.78);
varying vec3 wp;
float hash(vec2 p){return fract(sin(dot(p,vec2(41.7,279.3)))*43758.53);}
float noise2(vec2 p){vec2 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+1.0),f.x),f.y);}
void vertex(){
	float wave=sin(VERTEX.x*.40+VERTEX.z*.27+TIME*1.34)*.047+sin(VERTEX.z*.53-TIME*1.1)*.031;
	VERTEX.y+=wave*(1.0+squall*1.65);
	wp=VERTEX;
}
void fragment(){
	vec2 uv=(wp.xz-atlas_origin)/atlas_size;
	float bed=texture(relief,clamp(uv,vec2(0.0),vec2(1.0))).r*32.0-12.0;
	float depth=max(0.,wp.y-bed);
	float rip=noise2(wp.xz*.23+TIME*.067);
	float w=sin(wp.z*1.4+wp.x*.36+2.8*rip+TIME*1.3);
	vec3 color=mix(shallow,deep,smoothstep(.25,7.5,depth));
	color*=.94+.08*rip+.025*w;
	float band=sin(depth*8.2+TIME*1.6+rip*3.);
	float edge=(1.-smoothstep(.10,.40+.12*rip,depth))*.84;
	float surf=smoothstep(.63,1.,band)*(1.-smoothstep(.2,1.35,depth))*.75;
	float sparkle=smoothstep(.91,.99,w)*smoothstep(.49,.73,rip)*.26;
	color=mix(color,foam,clamp(edge+surf+sparkle,0.,.95));
	color=mix(color,color*vec3(.35,.52,.70),darkness*.83);
	color=mix(color,vec3(.18,.29,.31),squall*.22);
	ALBEDO=color;
}
