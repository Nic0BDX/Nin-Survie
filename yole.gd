extends RefCounted
## A clinker-built dinghy with a standing lug sail, modelled along local -Z.
const Ink=preload("res://meshwork.gd")
const Art=preload("res://art.gd")
static func draw(m):
	var stations=[[-2.28,.06,.69],[-1.76,.61,.52],[-1.05,.92,.45],[-.10,1.00,.40],[.82,.93,.40],[1.58,.73,.46],[1.86,.61,.50]]
	var hull=Color("#476d70")
	for j in range(stations.size()-1):
		var a=stations[j];var b=stations[j+1]
		for side in [-1,1]:
			var qa=Vector3(side*a[1],a[2],a[0]);var qb=Vector3(side*b[1],b[2],b[0])
			var ca=Vector3(side*a[1]*.76,.08,a[0]);var cb=Vector3(side*b[1]*.76,.08,b[0])
			var ka=Vector3(0,-.35,a[0]);var kb=Vector3(0,-.35,b[0])
			var out=Vector3(side,0,0)
			m.quad(ka,kb,cb,ca,hull.darkened(.16),out)
			m.quad(ca,cb,qb,qa,hull,out)
			m.rod(qa,qb,.06,.06,Art.CREAM,5)
			m.rod(ca,cb,.039,.039,Art.RED,4)
		m.quad(Vector3(-a[1]*.77,.105,a[0]),Vector3(a[1]*.77,.105,a[0]),Vector3(b[1]*.77,.105,b[0]),Vector3(-b[1]*.77,.105,b[0]),Art.WOOD,Vector3.UP)
	m.quad(Vector3(-.61,.5,1.86),Vector3(.61,.5,1.86),Vector3(.48,.07,1.86),Vector3(-.48,.07,1.86),hull,Vector3.BACK)
	for z in [-.77,.39,1.35]:
		m.box(Vector3(0,.38,z),Vector3(1.55 if z<1 else 1.30,.12,.31),Art.LWOOD)
	m.rod(Vector3(0,.08,-.7),Vector3(-.1,3.85,-.62),.09,.046,Art.WOOD,7)
	m.rod(Vector3(-.29,2.85,-1.55),Vector3(.27,3.58,.85),.055,.038,Art.LWOOD,6)
	var foot=Vector3(.07,.90,-.69)
	var clew=Vector3(.56,1.02,1.27)
	var top=Vector3(.26,3.54,.81)
	var peak=Vector3(-.27,2.82,-1.48)
	var belly=Vector3(.58,2.15,.06)
	var sail=Color("#c16449")
	m.face(foot,clew,belly,sail.lightened(.05),Vector3.RIGHT)
	m.face(clew,top,belly,sail,Vector3.RIGHT)
	m.face(top,peak,belly,sail.lightened(.09),Vector3.RIGHT)
	m.face(peak,foot,belly,sail.darkened(.05),Vector3.RIGHT)
	m.rod(foot,clew,.042,.032,Art.LWOOD,5)
	m.rod(Vector3(-.1,3.73,-.62),Vector3(0,.55,-2.18),.013,.013,Art.CREAM,4)
	m.rod(clew,Vector3(.74,.47,1.42),.018,.018,Art.CREAM,4)
	m.face(Vector3(-.1,3.81,-.62),Vector3(-.1,3.55,-.62),Vector3(.13,3.68,-.04),Art.GOLD,Vector3.RIGHT)
	m.box(Vector3(0,-.05,2.02),Vector3(.11,.86,.35),Art.LWOOD)
	m.rod(Vector3(0,.42,2.03),Vector3(-.14,.62,1.12),.047,.04,Art.WOOD,5)
