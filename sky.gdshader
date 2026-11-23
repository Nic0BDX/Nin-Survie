shader_type sky;
uniform float darkness=0.;
uniform float squall=0.;
uniform vec3 top : source_color = vec3(.27,.55,.68);
uniform vec3 horizon : source_color = vec3(.75,.83,.82);
uniform vec3 dusk : source_color=vec3(.63,.48,.55);
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,348.7)))*43871.236);}
float noise2(vec2 p){vec2 i=floor(p),f=fract(p); f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+1.),f.x),f.y);}
void sky(){
	vec3 d=EYEDIR;
	float h=max(d.y,0.);
	vec3 col=mix(horizon,top,smoothstep(-.11,.75,h));
	col=mix(col,mix(dusk,vec3(.065,.12,.20),smoothstep(0.,.74,h)),darkness*.88);
	vec2 p=d.xz/max(.055,h+.075);
	float n=noise2(p*vec2(.95,1.75)+vec2(TIME*.008,0.))*.61+noise2(p*3.9+TIME*.004)*.28+noise2(p*9.0)*.11;
	float cloud=smoothstep(.55,.65,n)*smoothstep(.008,.15,h);
	col=mix(col,mix(vec3(.94,.90,.76),vec3(.30,.38,.46),darkness),cloud*.78);
	float sun=dot(d,normalize(vec3(-.72,.34,-.66)));
	col+=vec3(.32,.19,.07)*pow(max(0.,sun),32.)*(1.-darkness);
	col=mix(col,vec3(1.,.90,.62),smoothstep(.997,.998,sun)*(1.-darkness));
	float star=step(.994,hash(floor(d.xz/max(.1,h)*330.)))*smoothstep(.15,.5,h);
	col+=star*darkness*.75;
	COLOR=mix(col,vec3(.28,.36,.41),squall*.48);
}
