extends RefCounted
const Ink=preload("res://meshwork.gd")
const CREAM=Color("#efe1ba")
const RED=Color("#c2533d")
const DARK=Color("#243a43")
const WOOD=Color("#8a6244")
const LWOOD=Color("#c89c64")
const STONE=Color("#8c9794")
const METAL=Color("#445b60")
const GOLD=Color("#ffd36f")

static func tree(m,p:Vector3,s:float,style:int,seed_num:float):
	var trunk=Color("#705947")
	var leafy=[Color("#356653"),Color("#497e5f"),Color("#578767"),Color("#699370")]
	var bend=Vector3(.57,0,-.13)*s
	var b=p+Vector3.UP*2.45*s+bend
	m.rod(p,b,.27*s,.15*s,trunk,7)
	if style==0:
		var crown=b+Vector3(.42,1.08,-.16)*s
		m.rod(b,crown,.15*s,.08*s,trunk)
		for j in 4:
			var a=seed_num+j*2.22
			var aim=Vector3(cos(a)*1.34,.32+j*.17,sin(a)*1.34)*s
			m.rod(b-Vector3.UP*(.68-j*.08)*s,b+aim,.13*s,.06*s,trunk,5)
			m.blob(b+aim,Vector3(1.39,.72,1.25)*s,leafy[j],seed_num+j,7)
		m.blob(crown+Vector3.UP*.48*s,Vector3(1.76,.84,1.43)*s,leafy[2],seed_num,8)
	else:
		for j in 3:
			var w=(1.53-.30*j)*s
			m.column(p+bend*(.4+.23*j)+Vector3.UP*(1.25+j*.99)*s,(2.68-.2*j)*s,w,.03*s,leafy[j],7)

static func flowers(m,p:Vector3,s:float,v:int):
	var blossom=[Color("#c18aa2"),Color("#eed6a0"),Color("#e5b858"),Color("#b5b1cf")][v%4]
	for i in 5:
		var a=i*2.399+v
		var root=p+Vector3(cos(a),0,sin(a))*.3*s
		var head=root+Vector3(.12,.4+.16*sin(i+v),.02)*s
		m.rod(root,head,.025*s,.016*s,Color("#627d56"),4)
		m.blob(head,Vector3(.12,.09,.12)*s,blossom,a,4)

static func grass(m,p:Vector3,s:float,v:float):
	for i in 5:
		var a=v+i*2.4
		var foot=p+Vector3(cos(a)*.23,0,sin(a)*.23)*s
		var top=foot+Vector3(.16+.16*cos(a),.25+.34*abs(sin(a*5)),.15*sin(a))*s
		var side=Vector3(cos(a)*.1,0,sin(a)*.1)*s
		m.face(foot-side,foot+side,top,Color("#92a979") if i%2==0 else Color("#b0b883"),Vector3.UP)

static func roof(m,p:Vector3,w:float,h:float,d:float,col:Color):
	var a=p+Vector3(-w*.5,0,-d*.5)
	var b=p+Vector3(w*.5,0,-d*.5)
	var c=p+Vector3(0,h,-d*.5)
	var dz=Vector3.BACK*d
	m.quad(a,c,c+dz,a+dz,col,Vector3(-1,1,0))
	m.quad(b,c,c+dz,b+dz,col.lightened(.05),Vector3(1,1,0))
	m.face(a,b,c,CREAM,Vector3.FORWARD)
	m.face(a+dz,b+dz,c+dz,CREAM,Vector3.BACK)

static func hut(m,p:Vector3,sz:float=1.0,blue:bool=false):
	var w=4.5*sz
	var h=2.8*sz
	var d=5.6*sz
	var slate=Color("#45636a") if blue else Color("#ad5d48")
	m.box(p-Vector3.UP*.54,Vector3(w+.10,1.36,d+.10),Color("#8a8b7b"))
	m.box(p+Vector3.UP*(h/2-.1),Vector3(w,h+.2,d),Color("#d9c9a4"))
	m.box(p+Vector3.UP*.21,Vector3(w+.08,.43,d+.08),Color("#817e70"))
	roof(m,p+Vector3.UP*h,w+.62*sz,1.68*sz,d+.65*sz,slate)
	for side in [-1,1]:
		var front=p+Vector3(side*1.29*sz,1.6*sz,d*.5+.035)
		m.box(front,Vector3(.88*sz,1.07*sz,.10),CREAM)
		m.box(front+Vector3.BACK*.07,Vector3(.64*sz,.82*sz,.055),Color("#47676a"))
		m.box(front+Vector3.BACK*.11,Vector3(.05,.83*sz,.05),CREAM)
		m.box(front+Vector3.BACK*.12,Vector3(.65*sz,.06,.05),CREAM)
	m.box(p+Vector3(0,1.02*sz,d*.5+.05),Vector3(.9*sz,2.05*sz,.12),slate)
	m.box(p+Vector3(.32*sz,1.03*sz,d*.5+.13),Vector3(.085,.085,.06),GOLD)
	m.box(p+Vector3(1.0*sz,h+1.2*sz,-1.5*sz),Vector3(.65,2.15,.77)*sz,Color("#a28970"))
	m.box(p+Vector3(1.0*sz,h+2.28*sz,-1.5*sz),Vector3(.84,.22,.93)*sz,DARK)

static func lighthouse(m,p:Vector3):
	m.column(p-Vector3.UP*.5,1.1,3.18,3.02,Color("#808b85"),12)
	var tiers=[[.6,3.5,2.54,2.20,CREAM],[4.1,2.65,2.20,1.96,RED],[6.75,2.32,1.96,1.72,CREAM],[9.07,1.9,1.72,1.58,RED],[10.97,1.12,1.58,1.47,CREAM]]
	for t in tiers: m.column(p+Vector3.UP*t[0],t[1],t[2],t[3],t[4],14)
	for j in 4:
		var a=j*.72+.17
		var r=2.43-j*.22
		var q=p+Vector3(sin(a)*r,2.8+j*2.3,cos(a)*r)
		m.box(q,Vector3(.57,1.0,.19),CREAM,a)
		m.box(q+Vector3(sin(a),0,cos(a))*.104,Vector3(.39,.78,.13),DARK,a)
	m.column(p+Vector3.UP*12.02,.42,1.68,2.12,DARK,14)
	m.column(p+Vector3.UP*12.43,.18,2.13,2.13,CREAM,14)
	for i in 14:
		var a=TAU*i/14
		var b=TAU*(i+1)/14
		var q=p+Vector3(cos(a)*2,12.58,sin(a)*2)
		var r=p+Vector3(cos(b)*2,12.58,sin(b)*2)
		m.column(q,.73,.045,.045,DARK,4)
		m.rod(q+Vector3.UP*.72,r+Vector3.UP*.72,.045,.045,DARK,5)
	m.column(p+Vector3.UP*12.62,.23,1.26,1.26,Color("#759999"),8)
	m.column(p+Vector3.UP*12.81,1.29,.22,.22,DARK,8)
	for ring in 5:
		var r=.52+.19*sin(PI*ring/4.)
		m.column(p+Vector3.UP*(13.02+ring*.15),.115,r,r,Color("#dbbd89"),10)
	for i in 8:
		var a=TAU*i/8
		m.column(p+Vector3(cos(a)*1.29,12.62,sin(a)*1.29),1.64,.075,.075,DARK,5)
	m.column(p+Vector3.UP*14.22,.25,1.57,1.55,DARK,12)
	m.column(p+Vector3.UP*14.47,1.22,1.63,.15,RED,12)
	m.column(p+Vector3.UP*15.68,1.02,.085,.025,DARK,6)
	m.box(p+Vector3(0,1.68,2.45),Vector3(1.28,2.5,.25),DARK)
	m.box(p+Vector3(0,1.67,2.61),Vector3(.94,2.17,.09),Color("#ae754a"))
	for i in 3:
		m.box(p+Vector3(0,.12+i*.17,3.6-i*.4),Vector3(1.88,.25+i*.27,.56),STONE)

static func wreck(m,p:Vector3):
	# Exposed ribs and broken strakes of the old mail boat.
	for j in 9:
		var z=-4.8+j*1.17
		var width=1.1+1.15*sin(PI*j/9)
		for side in [-1,1]:
			var foot=p+Vector3(.17,.05,z)
			var elbow=p+Vector3(side*width*.81,.67,z+.1)
			var tip=p+Vector3(side*width,1.7+.55*sin(j*2.1+side),z+.22)
			m.rod(foot,elbow,.14,.13,WOOD,5)
			m.rod(elbow,tip,.13,.11,LWOOD,5)
			if j<8 and (side==1 or j%4!=0):
				var nextw=1.1+1.15*sin(PI*(j+1)/9)
				for k in 3:
					m.rod(p+Vector3(side*width*(.64+k*.12),.55+k*.39,z),p+Vector3(side*nextw*(.64+k*.12),.58+k*.39,z+1.17),.17,.17,RED if k==2 else WOOD,4)
	m.rod(p+Vector3(0,.1,-4.9),p+Vector3(.25,.26,5.2),.32,.23,DARK)
	m.rod(p+Vector3(0,.2,-2.1),p+Vector3(1.25,6.65,-2.7),.23,.105,WOOD)
	m.rod(p+Vector3(-2.1,4.9,-2.63),p+Vector3(2.35,4.48,-2.71),.1,.11,LWOOD)
	m.face(p+Vector3(-2.1,4.84,-2.63),p+Vector3(.7,4.55,-2.67),p+Vector3(-.32,2.46,-2.38),Color("#d7ae82"),Vector3.BACK)
	m.rod(p+Vector3(1.25,6.55,-2.7),p+Vector3(0,.7,4.6),.026,.026,DARK,4)

static func ruin(m,p:Vector3):
	for k in 4:
		for i in 6:
			if (i==0 or i==5 or k<2 or (i==1 and k==2)):
				m.box(p+Vector3(-3.0+i*1.09+.10*(k%2),.32+k*.61,-1.9+.12*sin(i+k)),Vector3(1.05,.58,1.05),STONE.darkened(.12*abs(sin(i+k))),.08*sin(i*3+k))
	for j in 2:
		var q=p+Vector3(-2.2+j*3.4,0,.3)
		m.column(q,2.9,.59,.48,Color("#777e72"),7)
		m.box(q+Vector3.UP*3,Vector3(1.15,.36,1.06),STONE)
	m.rod(p+Vector3(-2.57,3.27,.3),p+Vector3(1.56,3.34,.3),.23,.23,WOOD,6)
	m.column(p+Vector3(-.45,2.03,.3),.83,.53,.26,Color("#a9864c"),8)
	m.column(p+Vector3(-.45,2.84,.3),.47,.08,.08,DARK)

static func resource(m,typ:String):
	match typ:
		"wood":
			for i in 3:
				var a=i*.9+.19
				var d=Vector3(cos(a),.09,sin(a))
				var p=Vector3(.22*i-.16,.19+i*.08,.15*sin(i))
				m.rod(p-d*.88,p+d*.88,.18,.12,WOOD if i==1 else LWOOD,6)
				m.rod(p+d*.84,p+d*.90,.123,.122,Color("#ead39e"),6)
				m.rod(p,p+Vector3(.25,.49,.17),.08,.045,LWOOD,5)
		"stone":
			m.blob(Vector3(-.32,.38,.12),Vector3(.78,.59,.54),Color("#829697"),1.2)
			m.blob(Vector3(.48,.25,-.15),Vector3(.58,.40,.42),Color("#b7bdad"),2.8)
			m.blob(Vector3(.1,.17,.53),Vector3(.38,.23,.33),Color("#697e80"),2)
		"food":
			for i in 5:
				var a=i*2.4
				var p=Vector3(cos(a)*.41,.43+.13*sin(i),sin(a)*.39)
				m.blob(p,Vector3(.55,.46,.48),Color("#657e4e") if i%2==0 else Color("#798952"),i)
				for j in 3:
					var b=a+j*2.3
					m.blob(p+Vector3(cos(b)*.41,.21,sin(b)*.41),Vector3.ONE*.125,Color("#dd7961"),j,5)

static func build(m,typ:String):
	match typ:
		"fire":
			for i in 9:
				var a=TAU*i/9
				m.blob(Vector3(cos(a)*.72,.18,sin(a)*.72),Vector3(.33,.27,.31),STONE,i,6)
			for i in 4:
				var a=TAU*i/4+.44
				m.rod(Vector3(cos(a)*.70,.14,sin(a)*.70),Vector3(-cos(a)*.22,.75,-sin(a)*.22),.15,.105,WOOD,6)
			m.column(Vector3.UP*.13,.20,.53,.45,Color("#ed803b"))
		"bridge":
			for side in [-1,1]:
				for end in [-1,1]:
					m.column(Vector3(side*1.44,-8.5,end*1.48),8.96,.135,.13,WOOD,6)
				m.box(Vector3(side*1.14,-.28,0),Vector3(.23,.35,3.62),WOOD)
			for i in 8:
				m.box(Vector3(.04*sin(i*7),-.065,-1.57+i*.45),Vector3(3.32+.15*sin(i),.19,.423),LWOOD.darkened(.08*(i%3)),.012*sin(i*2))
		"shelter":
			for side in [-1,1]:
				for end in [-1,1]:
					m.rod(Vector3(side*1.58,.1,end*1.5),Vector3(0,2.5,end*1.5),.103,.08,WOOD)
			m.rod(Vector3(0,2.48,-1.87),Vector3(0,2.48,1.87),.11,.11,LWOOD)
			for side in [-1,1]:
				var a=Vector3(side*1.68,.17,-1.71)
				var b=Vector3(0,2.46,-1.71)
				m.quad(a,b,b+Vector3.BACK*3.42,a+Vector3.BACK*3.42,Color("#bc784f") if side==1 else Color("#c38a58"),Vector3(side,1,0))
				for e in [-1,1]:
					m.rod(Vector3(side*1.48,.46,e*1.68),Vector3(side*2.08,.03,e*1.96),.024,.024,CREAM,4)
			m.box(Vector3(0,.12,.34),Vector3(1.2,.24,2.0),Color("#687c64"))
		"trap":
			for i in 12:
				var a=TAU*i/12
				m.rod(Vector3(cos(a)*.72,0,sin(a)*.72),Vector3(cos(a)*.39,1.15,sin(a)*.39),.08,.058,LWOOD,5)
			for j in 3:
				var r=.68-.115*j
				for i in 12:
					var a=TAU*i/12
					var b=TAU*(i+1)/12
					m.rod(Vector3(cos(a)*r,.22+.34*j,sin(a)*r),Vector3(cos(b)*r,.22+.34*j,sin(b)*r),.045,.045,WOOD,4)
			m.rod(Vector3(.6,0,0),Vector3(.77,2.75,.03),.065,.05,WOOD)
			m.face(Vector3(.77,2.73,.03),Vector3(1.52,2.57,.07),Vector3(.77,2.32,.03),RED,Vector3.BACK)

static func chest(m,p:Vector3):
	m.box(p+Vector3.UP*.34,Vector3(1.33,.68,.83),Color("#ac7545"))
	m.box(p+Vector3.UP*.72,Vector3(1.40,.15,.90),LWOOD)
	for v in [-.45,.45]:
		m.box(p+Vector3(v,.43,0),Vector3(.12,.85,.92),METAL)
	m.box(p+Vector3(0,.5,.49),Vector3(.22,.24,.08),GOLD)

static func marine(m,p:Vector3):
	# Ribbed lobster buoys used as visual signposts along the tidal path.
	m.column(p,1.75,.075,.065,WOOD)
	m.column(p+Vector3.UP*.78,.56,.20,.25,CREAM)
	m.column(p+Vector3.UP*1.34,.34,.25,.12,RED)

static func signpost(m,p:Vector3,angle:float):
	m.column(p,2.2,.13,.11,WOOD,5)
	m.box(p+Vector3.UP*1.86,Vector3(1.55,.35,.16),LWOOD,angle)
	m.box(p+Vector3.UP*1.43,Vector3(1.15,.23,.13),CREAM,angle+.65)

static func vessel(m):
	for i in 11:
		var z=-3.8+i*.72
		var w=.46+1.07*sin(PI*i/11)
		m.box(Vector3(0,.24,z),Vector3(w*2,.61,.76),Color("#a74e38"))
		m.box(Vector3(0,.62,z),Vector3(w*2.05,.15,.76),CREAM)
	m.box(Vector3(0,1.16,.65),Vector3(1.7,1.18,2.2),CREAM)
	m.box(Vector3(0,1.56,.65),Vector3(1.74,.47,2.24),Color("#537b7e"))
	m.box(Vector3(0,1.86,.65),Vector3(2.05,.18,2.52),RED)
	m.column(Vector3(0,1.86,.35),1.55,.075,.05,DARK)
	m.column(Vector3(0,1.86,1.3),.77,.22,.18,RED)
