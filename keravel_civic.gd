extends RefCounted

const GRANITE=Color("#9d988d")
const GRANITE_LIT=Color("#c2b7a2")
const GRANITE_DARK=Color("#625e56")
const LEAD=Color("#333945")
const OAK=Color("#594238")
const GLASS=[Color("#637da0"),Color("#42678a"),Color("#899987"),Color("#bb8a57"),Color("#8f5355")]

## A west-front treatment for the chapel. The near face is on +Z.
## Depths stay behind or close to the existing eaves. The base owns collision.
static func chapel_details(m,p:Vector3,width:float=6.5,depth:float=8.3125,height:float=6.5375):
	var facade=p+Vector3.BACK*(depth*.5)
	var scale_x=width/6.5
	var scale_y=height/6.5375
	var portal=facade+Vector3(0,0,.019)
	portal_details(m,portal,scale_x,scale_y)

	var upper=facade+Vector3(0,2.86*scale_y,.012)
	stone_bay(m,upper,1.20*scale_x,2.68*scale_y,true)
	for side in [-1.,1.]:
		var lateral=facade+Vector3(side*1.88*scale_x,1.04*scale_y,.014)
		stone_bay(m,lateral,.47*scale_x,3.61*scale_y,false)
		buttress(m,facade+Vector3(side*(width*.5-.31),0,-.055),scale_x,scale_y)

	for side in [-1.,1.]:
		course(m,facade,side*.97*scale_x,side*width*.5,.34*scale_y,GRANITE_DARK)
		course(m,facade,side*.97*scale_x,side*1.25*scale_x,2.68*scale_y,GRANITE)
		course(m,facade,side*2.51*scale_x,side*width*.5,2.68*scale_y,GRANITE)
	course(m,facade,-width*.5,width*.5,5.88*scale_y,GRANITE)
	var roof_height=width*.31
	var rose=facade+Vector3(0,height+roof_height*.42,.391)
	rose_window(m,rose,.41*scale_x)
	var pinnacle=facade+Vector3(0,height+roof_height+.02,.34)
	m.box(pinnacle+Vector3.UP*.10,Vector3(.35,.20,.29)*scale_x,GRANITE_DARK)
	m.box(pinnacle+Vector3.UP*.46,Vector3(.115,.72,.115)*scale_x,GRANITE_LIT)
	m.box(pinnacle+Vector3.UP*.54,Vector3(.41,.118,.119)*scale_x,GRANITE_LIT)

static func course(m,facade:Vector3,start:float,finish:float,y:float,color:Color):
	m.box(facade+Vector3((start+finish)*.5,y,.065),Vector3(absf(finish-start),.115,.15),color)

static func pointed_outline(half_width:float,height:float,spring:float)->Array[Vector2]:
	var result:Array[Vector2]=[Vector2(-half_width,0),Vector2(-half_width,spring)]
	var center=half_width*.68
	var radius=half_width+center
	var endpoint=acos(center/radius)
	var arc_height=sin(endpoint)*radius
	for i in range(1,7):
		var angle=endpoint*i/6.
		result.append(Vector2(center-cos(angle)*radius,spring+sin(angle)*radius/arc_height*(height-spring)))
	for i in range(5,-1,-1):
		var mirror=result[i+1]
		result.append(Vector2(-mirror.x,mirror.y))
	result.append(Vector2(half_width,0))
	return result

static func arch(m,p:Vector3,half_width:float,height:float,spring:float,band:float,depth:float):
	var inside=pointed_outline(half_width,height,spring)
	var outside=pointed_outline(half_width+band,height+band,spring)
	for i in range(inside.size()-1):
		var a=Vector3(inside[i].x,inside[i].y,depth)
		var b=Vector3(inside[i+1].x,inside[i+1].y,depth)
		var c=Vector3(outside[i+1].x,outside[i+1].y,depth)
		var d=Vector3(outside[i].x,outside[i].y,depth)
		var color=GRANITE.lerp(GRANITE_LIT,.13+.17*float(i%4))
		m.quad(p+a,p+b,p+c,p+d,color,Vector3.BACK)
		var ab=(inside[i]+inside[i+1])*.5
		var out=Vector3(-signf(ab.x),-0.5 if ab.y>spring else 0.,0)
		m.quad(p+a,p+b,p+b-Vector3.BACK*depth,p+a-Vector3.BACK*depth,color.darkened(.24),out)

static func portal_details(m,p:Vector3,sx:float,sy:float):
	var half_width=.67*sx
	var height=2.55*sy
	var spring=1.58*sy
	var outline=pointed_outline(half_width,height,spring)
	var center=p+Vector3(0,1.16*sy,.14)
	for i in range(outline.size()):
		var a=outline[i]
		var b=outline[(i+1)%outline.size()]
		m.face(center,p+Vector3(a.x,a.y,.14),p+Vector3(b.x,b.y,.14),OAK.darkened(.16),Vector3.BACK)
	arch(m,p,half_width,height,spring,.12*sx,.19)
	arch(m,p,half_width+.15*sx,height+.15*sy,spring,.16*sx,.24)
	for x in [-.43,-.22,0.,.22,.43]:
		var tip=spring+(height-spring)*(1.-absf(x)/.67)*.85
		m.box(p+Vector3(x*sx,tip*.5,.161),Vector3(.018,tip,.024),OAK.lightened(.12))
	for side in [-1.,1.]:
		for y in [.60,1.42]:
			m.box(p+Vector3(side*.37*sx,y*sy,.182),Vector3(.28*sx,.065*sy,.035),LEAD)
		m.rod(p+Vector3(side*.20*sx,1.02*sy,.174),p+Vector3(side*.20*sx,1.14*sy,.174),
			.034,.034,GRANITE_LIT,6)
	m.box(p+Vector3(0,.085,.179),Vector3(1.96*sx,.17,.235),GRANITE_DARK)

static func stone_bay(m,p:Vector3,half_width:float,height:float,divided:bool):
	var spring=height*.65
	var outline=pointed_outline(half_width,height,spring)
	var center=p+Vector3(0,height*.49,.072)
	for i in outline.size():
		var a=outline[i]
		var b=outline[(i+1)%outline.size()]
		m.face(center,p+Vector3(a.x,a.y,.072),p+Vector3(b.x,b.y,.072),GLASS[i%GLASS.size()],Vector3.BACK)
		m.rod(center+Vector3.BACK*.013,p+Vector3(a.x,a.y,.085),.021,.021,LEAD,4)
	arch(m,p,half_width,height,spring,.114,.18)
	m.box(p+Vector3(0,-.028,.105),Vector3(2.*half_width+.29,.12,.265),GRANITE_LIT)
	if divided:
		m.box(p+Vector3(0,height*.45,.132),Vector3(.094,height*.90,.082),GRANITE_LIT)
		for side in [-1.,1.]:
			m.rod(p+Vector3(side*half_width*.55,height*.39,.119),p+Vector3(0,height*.78,.119),
				.031,.03,GRANITE_LIT,5)

static func buttress(m,p:Vector3,sx:float,sy:float):
	var heights=[1.10,1.65,1.37,1.22]
	var widths=[.59,.49,.39,.30]
	var depths=[.54,.46,.36,.29]
	var y=0.
	for i in heights.size():
		var height=heights[i]*sy
		m.box(p+Vector3(0,y+height*.5,0),Vector3(widths[i]*sx,height,depths[i]),GRANITE.darkened(i*.024))
		y+=height
		m.box(p+Vector3(0,y-.09,0),Vector3((widths[i]+.095)*sx,.13,depths[i]+.10),GRANITE_LIT)
	var a=p+Vector3(-.17*sx,y,0)
	var b=p+Vector3(.17*sx,y,0)
	m.face(a+Vector3.BACK*.11,b+Vector3.BACK*.11,p+Vector3(0,y+.61*sy,.11),GRANITE_LIT,Vector3.BACK)

static func rose_window(m,p:Vector3,radius:float):
	var steps=16
	for i in steps:
		var a=Vector2.from_angle(TAU*i/steps)
		var b=Vector2.from_angle(TAU*(i+1)/steps)
		var x=Vector3(a.x,a.y,0)
		var y=Vector3(b.x,b.y,0)
		m.face(p,p+x*radius,p+y*radius,GLASS[(i+1)%GLASS.size()],Vector3.BACK)
		var lip=p+Vector3.BACK*.039
		m.quad(lip+x*radius,lip+y*radius,lip+y*(radius+.097),lip+x*(radius+.097),GRANITE_LIT,Vector3.BACK)
		if i%2==0:
			m.rod(lip,lip+x*radius,.027,.021,LEAD,4)
