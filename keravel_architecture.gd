extends RefCounted

const Art=preload("res://art.gd")
const OAK=Color("#554035")
const SLATE=Color("#405362")
const GRANITE=Color("#92928b")
const STONE_SHADOW=Color("#666d6b")
const GLASS=Color("#b2935f")

static func arch_ring(m,p:Vector3,width:float,height:float,depth:float,color:Color):
	var radius=width*.5
	var spring=height-radius
	for side in [-1.,1.]:
		m.box(p+Vector3(side*(radius+.13),spring*.5,0),Vector3(.26,spring,depth),color)
	for i in 9:
		var a=float(i)*PI/9.
		var b=float(i+1)*PI/9.
		var outer=radius+.24
		var pts=[
			Vector3(cos(a)*radius,spring+sin(a)*radius,depth*.5),
			Vector3(cos(b)*radius,spring+sin(b)*radius,depth*.5),
			Vector3(cos(b)*outer,spring+sin(b)*outer,depth*.5),
			Vector3(cos(a)*outer,spring+sin(a)*outer,depth*.5),
		]
		var shade=color.lightened(.035*(i%3))
		m.quad(p+pts[0],p+pts[1],p+pts[2],p+pts[3],shade,Vector3.BACK)
		m.quad(p+pts[0]-Vector3.BACK*depth,p+pts[1]-Vector3.BACK*depth,p+pts[2]-Vector3.BACK*depth,p+pts[3]-Vector3.BACK*depth,shade,Vector3.FORWARD)
		m.quad(p+pts[0],p+pts[1],p+pts[1]-Vector3.BACK*depth,p+pts[0]-Vector3.BACK*depth,shade.darkened(.19),Vector3.DOWN)

static func window(m,p:Vector3,width:float,height:float,shutters:bool,lit:bool):
	m.box(p,Vector3(width+.14,height+.15,.12),OAK)
	m.box(p+Vector3.BACK*.07,Vector3(width,height,.065),GLASS if lit else Color("#405259"))
	m.box(p+Vector3.BACK*.12,Vector3(.058,height,.055),OAK)
	m.box(p+Vector3.BACK*.12,Vector3(width,.055,.055),OAK)
	m.box(p+Vector3(0,-height*.55,.14),Vector3(width+.28,.12,.27),GRANITE)
	if shutters:
		for side in [-1.,1.]:
			var q=p+Vector3(side*(width*.69+.12),0,.08)
			m.box(q,Vector3(width*.34,height,.15),Color("#5a6a59"))
			for y in [-height*.28,height*.15]:
				m.box(q+Vector3(0,y,.088),Vector3(width*.34,.079,.06),OAK)

static func roof_tiles(m,p:Vector3,width:float,depth:float,rise:float,color:Color,detailed:bool):
	Art.roof(m,p,width,rise,depth,color)
	m.rod(p+Vector3(0,rise+.045,-depth*.5),p+Vector3(0,rise+.045,depth*.5),.085,.085,color.darkened(.23),5)
	if not detailed: return
	for side in [-1.,1.]:
		for course in range(1,6):
			var t=course/6.
			var x=side*width*.5*(1.-t)
			var y=rise*t+.036
			m.rod(p+Vector3(x,y,-depth*.5),p+Vector3(x,y,depth*.5),.026,.024,color.darkened(.16),4)
			if course%2==0:
				for tile in 5:
					var z=(tile/5.-.45)*depth
					m.rod(p+Vector3(x,y,z),p+Vector3(x-side*width/16.,y+rise/8.,z),.018,.013,color.lightened(.055),4)

static func house(m,p:Vector3,width:float,depth:float,height:float,finish:Color,roof:Color,style:int,detailed:bool,bare_front:bool=false):
	var storeys=1 if height<4.1 else 2
	m.box(p+Vector3.UP*.33,Vector3(width+.24,1.28,depth+.24),GRANITE)
	m.box(p+Vector3.UP*height*.5,Vector3(width,height,depth),finish)
	var rise=width*(.31+float(style%3)*.041)
	roof_tiles(m,p+Vector3.UP*height,width+.67,depth+.75,rise,roof,detailed)
	if bare_front: return
	var facade=p+Vector3.BACK*(depth*.5+.027)
	var back=p+Vector3.FORWARD*(depth*.5+.027)
	var timber=style%4==0 or style%4==2
	var framing=OAK if timber else GRANITE
	for side in [-1.,1.]:
		m.box(facade+Vector3(side*(width*.5-.095),height*.53,.02),Vector3(.19,height*.94,.18),framing)
		m.box(back+Vector3(side*(width*.5-.095),height*.53,-.04),Vector3(.19,height*.94,.15),framing)
		if detailed:
			for course in range(1,5):
				var y=course*height/5.
				m.box(facade+Vector3(side*(width*.5-.21),y,.08),Vector3(.39,.19,.18),GRANITE.lightened(.055*(course%2)))
	var door_h=minf(2.18,height*.67)
	m.box(facade+Vector3(0,door_h*.49,.07),Vector3(1.12,door_h,.13),OAK)
	for plank in [-.35,-.12,.12,.35]:
		m.box(facade+Vector3(plank,door_h*.50,.149),Vector3(.02,door_h*.9,.018),OAK.darkened(.21))
	m.box(facade+Vector3(.29,door_h*.44,.21),Vector3(.091,.085,.087),Color("#bb9453"))
	m.box(facade+Vector3(0,.09,.42),Vector3(1.43,.18,.78),STONE_SHADOW)
	if style%4==1: arch_ring(m,facade+Vector3.BACK*.14,1.16,door_h,.22,GRANITE)
	else: m.box(facade+Vector3(0,door_h,.096),Vector3(1.35,.18,.23),framing)
	for floor in storeys:
		var y=1.8+floor*(height*.41)
		if y>height-.48: continue
		for side in [-1.,1.]:
			window(m,facade+Vector3(side*width*.29,y,0),minf(.86,width*.17),.96,detailed,style%3!=1)
			if detailed and floor==0:
				var center=facade+Vector3(side*width*.29,y-.61,.19)
				m.box(center,Vector3(.79,.175,.21),Art.WOOD)
				for j in 3:
					m.blob(center+Vector3((j-1)*.20,.075,.035),Vector3(.13,.112,.1),Color("#a76253"),j,5)
	if timber:
		m.box(facade+Vector3.UP*(height*.62),Vector3(width,.15,.13),OAK)
		m.box(facade+Vector3.UP*(height-.18),Vector3(width,.17,.16),OAK)
		for side in [-1.,1.]:
			m.rod(facade+Vector3(side*width*.45,height-.23,.1),facade+Vector3(side*width*.19,height*.64,.1),.075,.075,OAK,4)
	m.box(p+Vector3(width*.22,height+rise*.68,-depth*.2),Vector3(.68,1.85,.73),GRANITE.darkened(.22))
	m.box(p+Vector3(width*.22,height+rise*.68+.92,-depth*.2),Vector3(.85,.17,.86),STONE_SHADOW)
	if detailed and style%3!=0:
		var dormer=facade+Vector3.UP*(height+.56)
		m.box(dormer,Vector3(width*.22,1.04,.33),finish)
		window(m,dormer+Vector3.BACK*.2,.56,.58,false,true)
		roof_tiles(m,dormer+Vector3.UP*.52,width*.27,.61,.46,roof.darkened(.11),false)

static func tower(m,p:Vector3,radius:float,height:float,roofed:bool):
	m.column(p-Vector3.UP*.35,1.01,radius*1.20,radius,GRANITE,12)
	m.column(p+Vector3.UP*.6,height-.6,radius,radius*.91,GRANITE,12)
	for y in [.34,.69,.96]:
		m.column(p+Vector3.UP*(height*y),.18,radius*.97,radius,STONE_SHADOW,12)
	for a in [0.,PI*.5,PI,PI*1.5]:
		var d=Vector3(sin(a),0,cos(a))
		m.box(p+Vector3.UP*(height*.67)+d*radius*.94,Vector3(.27,1.17,.13),OAK,a)
	if roofed:
		m.column(p+Vector3.UP*height,height*.44,radius*1.07,.04,SLATE,12)
		m.rod(p+Vector3.UP*height*1.43,p+Vector3.UP*height*1.65,.063,.022,OAK,5)
	else:
		m.column(p+Vector3.UP*height,.34,radius*1.04,radius*1.04,STONE_SHADOW,12)
		for i in 10:
			var a=TAU*i/10.
			m.box(p+Vector3(sin(a)*radius*.86,height+.47,cos(a)*radius*.86),Vector3(.56,.65,.48),GRANITE,a)

static func pier_prop(m,p:Vector3):
	for x in [-1.,1.]:
		m.column(p+Vector3(x*.7,-.9,0),1.45,.14,.13,OAK,6)
	m.box(p+Vector3(0,.22,0),Vector3(1.17,.59,.83),Art.LWOOD)
	for x in [-.44,.44]:
		m.box(p+Vector3(x,.24,0),Vector3(.081,.63,.89),OAK)

static func canopy(m,p:Vector3,color:Color):
	for x in [-1.46,1.46]:
		for z in [-1.11,1.11]:
			m.box(p+Vector3(x,1.27,z),Vector3(.116,2.56,.116),OAK)
	for i in 7:
		var x=-1.48+(i+.5)*.424
		m.box(p+Vector3(x,2.43,0),Vector3(.434,.12,2.48),color if i%2==0 else Color("#dfd2ae"))
	m.box(p+Vector3(0,.8,.23),Vector3(2.62,.13,.86),Art.LWOOD)
	for i in 5:
		m.blob(p+Vector3(-.92+i*.45,.94,.33),Vector3(.15,.15,.18),Color("#8b9a64") if i%2==0 else Color("#b77a53"),i,5)
