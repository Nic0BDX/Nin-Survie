extends Node3D
const Ink=preload("res://meshwork.gd")
const Art=preload("res://art.gd")
var mat=Ink.palette()
var body=Node3D.new()
var head=Node3D.new()
var legs=[]
var arms=[]
var lamp:OmniLight3D
var shadow:MeshInstance3D
var stride=0.0
var facing=PI
var bell_pivot:Node3D
var outline:MeshInstance3D

func _ready():
	add_child(body)
	var slicker=Color("#e9ad3e")
	var honey=Color("#f1be54")
	var navy=Color("#304953")
	var sea=Color("#527e76")
	var leather=Color("#855a40")
	var m=Ink.new()
	m.column(Vector3(0,.65,0),.72,.36,.28,slicker,9)
	m.column(Vector3(0,1.27,-.005),.15,.29,.22,honey,9)
	m.column(Vector3(0,.67,0),.08,.372,.366,Color("#f5c557"),9)
	m.box(Vector3(0,.97,-.292),Vector3(.033,.48,.025),Color("#a87939"))
	for i in 3: m.box(Vector3(.044,.83+i*.15,-.30),Vector3(.048,.042,.035),Art.CREAM)
	m.box(Vector3(.208,.82,-.237),Vector3(.17,.13,.035),honey,-.44)
	m.box(Vector3(0,1.05,.29),Vector3(.45,.46,.22),leather)
	m.box(Vector3(0,1.18,.42),Vector3(.45,.19,.08),Color("#9f7953"))
	m.box(Vector3(0,1.10,.47),Vector3(.084,.14,.04),Art.GOLD)
	m.column(Vector3(0,1.32,0),.13,.265,.24,Art.RED,9)
	m.face(Vector3(.13,1.37,.15),Vector3(.22,1.31,.15),Vector3(.42,1.16,.46),Art.RED,Vector3.UP)
	body.add_child(m.node(mat))
	head.position=Vector3(0,1.51,-.04)
	body.add_child(head)
	m=Ink.new()
	m.blob(Vector3(0,.04,0),Vector3(.272,.29,.247),Color("#ca8f66"),.5,10)
	m.blob(Vector3(0,.055,-.236),Vector3(.072,.06,.07),Color("#cc8963"),2,7)
	for x in [-.106,.106]: m.box(Vector3(x,.09,-.225),Vector3(.045,.053,.032),Art.DARK)
	m.column(Vector3(0,.15,.004),.11,.293,.304,navy,12)
	m.blob(Vector3(0,.242,.022),Vector3(.295,.235,.266),sea,1,10)
	m.column(Vector3(0,.16,.003),.095,.302,.295,sea.lightened(.1),12)
	for i in 12:
		var a=TAU*i/12
		m.rod(Vector3(cos(a)*.296,.168,sin(a)*.296),Vector3(cos(a)*.292,.251,sin(a)*.292),.012,.012,sea.darkened(.1),4)
	m.blob(Vector3(.01,.466,.032),Vector3(.091,.078,.09),Art.CREAM,2,6)
	head.add_child(m.node(mat))
	for side in [-1,1]:
		var leg=Node3D.new()
		leg.position=Vector3(side*.146,.72,0)
		body.add_child(leg)
		legs.append(leg)
		m=Ink.new()
		m.rod(Vector3.ZERO,Vector3(0,-.46,0),.141,.116,navy,7)
		m.rod(Vector3(0,-.38,0),Vector3(0,-.62,0),.129,.113,Art.DARK)
		m.blob(Vector3(0,-.61,-.061),Vector3(.132,.102,.208),Art.DARK,0,7)
		m.box(Vector3(0,-.69,-.054),Vector3(.235,.045,.29),leather)
		leg.add_child(m.node(mat))
		var arm=Node3D.new()
		arm.position=Vector3(side*.285,1.28,0)
		body.add_child(arm)
		arms.append(arm)
		m=Ink.new()
		m.rod(Vector3.ZERO,Vector3(side*.104,-.379,-.045),.137,.1,honey,7)
		m.rod(Vector3(side*.104,-.34,-.045),Vector3(side*.106,-.421,-.047),.104,.101,navy,7)
		m.blob(Vector3(side*.106,-.442,-.058),Vector3(.102,.109,.091),Color("#ba825d"),1,6)
		if side==1:
			var q=Vector3(.12,-.45,-.11)
			m.rod(q,q+Vector3(0,-.08,-.24),.029,.029,Art.DARK,5)
			m.rod(q,q+Vector3(0,-.11,.03),.029,.029,Art.DARK,5)
			m.column(q+Vector3(0,-.34,-.12),.20,.127,.123,Color("#ffe181"),8)
			m.column(q+Vector3(0,-.385,-.12),.068,.142,.14,Art.DARK,8)
			m.column(q+Vector3(0,-.13,-.12),.057,.14,.09,Art.DARK,8)
			for k in 4:
				var a=TAU*k/4
				m.column(q+Vector3(cos(a)*.12,-.34,-.12+sin(a)*.12),.22,.016,.016,Art.DARK,4)
		arm.add_child(m.node(mat))
	lamp=OmniLight3D.new()
	lamp.light_color=Color("#ffba62")
	lamp.position=Vector3(.43,.94,-.25)
	lamp.omni_range=8.5
	lamp.omni_attenuation=1.6
	lamp.light_energy=.23
	add_child(lamp)

func pose(delta:float,speed:float,water:float,ring:float,night:float,t:float):
	var walk=min(speed/3.8,1.55)
	stride+=delta*(5.5+speed*1.4) if speed>.15 else delta*1.6
	var s=sin(stride)*min(1.0,walk)
	var swim=clampf((water-.65)/.8,0,1)
	body.position.y=abs(s)*.088+.025*sin(t*2.4)-swim*.13
	body.rotation.x=-.085*walk-.30*swim
	for i in 2:
		var side=-1 if i==0 else 1
		legs[i].rotation.x=lerpf(s*side*.65,-.8+side*s*.25,swim)
		arms[i].rotation.x=lerpf(-s*side*.57,-.85+side*s*.6,swim)
		arms[i].rotation.z=side*(.06+swim*.57)
	var pulse=sin(clampf(ring/.64,0,1)*PI)
	arms[1].rotation.x-=pulse*2.2
	arms[1].rotation.z+=pulse*.65
	head.rotation.y=.09*sin(t*.9)+.04*s
	rotation.y=lerp_angle(rotation.y,facing,1-exp(-delta*14))
	lamp.light_energy=.14+night*1.28+.04*sin(t*13.0)

static func spectre(material:Material)->Node3D:
	var root=Node3D.new()
	var m=Ink.new()
	var coat=Color("#386265")
	m.column(Vector3(0,.1,0),1.15,.38,.27,coat,7)
	for i in 6:
		var a=TAU*i/6
		m.face(Vector3(cos(a)*.37,.37,sin(a)*.37),Vector3(cos(a+.7)*.37,.37,sin(a+.7)*.37),Vector3(cos(a+.22)*.41,-.18+.07*sin(i),sin(a+.22)*.41),coat,Vector3(cos(a),0,sin(a)))
	m.blob(Vector3(0,1.4,0),Vector3(.30,.33,.26),Color("#7eaaa0"),.5)
	m.column(Vector3(0,1.57,0),.1,.36,.35,Art.DARK,8)
	m.column(Vector3(0,1.65,0),.14,.25,.18,Art.DARK,8)
	for side in [-1,1]:
		m.box(Vector3(side*.103,1.45,-.238),Vector3(.09,.047,.042),Color("#ddffb4"))
		m.rod(Vector3(side*.23,1.15,0),Vector3(side*.43,.62,-.16),.13,.10,coat,6)
		m.blob(Vector3(side*.43,.60,-.16),Vector3(.093,.12,.09),Color("#83a99b"),2,6)
	root.add_child(m.node(material))
	var glow=OmniLight3D.new()
	glow.light_color=Color("#92d8ad")
	glow.light_energy=.63
	glow.omni_range=3.8
	glow.position.y=1.25
	root.add_child(glow)
	return root
