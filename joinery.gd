extends RefCounted
const A=preload("res://art.gd")
static func draw(m,k:String):
	var timber=Color("#896744")
	var planks=[Color("#c29763"),Color("#b98b5b"),Color("#d0a673")]
	var paint=Color("#708c84")
	if k=="floor":
		for x in [-1.53,1.53]:
			for z in [-1.53,1.53]:
				m.column(Vector3(x,-7.5,z),7.5,.16,.15,timber,7)
			m.box(Vector3(x,-.26,0),Vector3(.21,.34,3.6),timber)
		for i in 9:
			m.box(Vector3(0,-.053,-1.6+i*.4),Vector3(3.59,.15,.387),planks[i%3])
		for x in [-1.5,1.5]:
			for z in [-1.6,-.8,0,.8,1.6]:
				m.column(Vector3(x,.024,z),.014,.036,.036,A.METAL,5)
	elif k in ["wall","door"]:
		for x in [-1.72,1.72]:m.box(Vector3(x,1.33,0),Vector3(.17,2.66,.23),timber)
		m.box(Vector3(0,2.55,0),Vector3(3.6,.18,.24),timber)
		for i in 12:
			var x=-1.64+i*.298
			var open=k=="door" and abs(x)<.74
			var height=.49 if open else 2.45
			var bottom=1.96 if open else .025
			var col=paint.darkened((i%4)*.035) if i%4!=1 else paint.lightened(.054)
			m.box(Vector3(x,bottom+height*.5,0),Vector3(.282,height,.123),col)
		if k=="wall":
			m.box(Vector3(0,.42,-.085),Vector3(3.44,.14,.11),timber)
			m.rod(Vector3(-1.55,.46,-.16),Vector3(1.54,2.23,-.16),.069,.069,A.LWOOD,4)
		else:
			for x in [-.77,.77]:m.box(Vector3(x,.99,-.02),Vector3(.13,1.98,.24),A.LWOOD)
			m.box(Vector3(0,2.,0),Vector3(1.68,.16,.24),A.LWOOD)
	elif k=="roof":
		for x in [-1.68,1.68]:
			for z in [-1.66,1.66]:
				m.column(Vector3(x,0,z),2.62,.094,.087,timber,6)
			m.box(Vector3(x,2.58,0),Vector3(.16,.15,3.57),timber)
		for s in [-1,1]:
			var a=Vector3(s*1.97,2.54,-1.91);var b=Vector3(0,3.52,-1.91);var dz=Vector3(0,0,3.82)
			m.quad(a,b,b+dz,a+dz,Color("#8a6555") if s==1 else Color("#9e7460"),Vector3(s,1,0))
			for j in 5:
				var f=j/5.
				var e=a.lerp(b,f)
				m.rod(e,e+dz,.031,.031,Color("#b08a6c"),5)
		m.rod(Vector3(0,3.52,-1.95),Vector3(0,3.52,1.95),.09,.09,timber,6)
