extends RefCounted
## Small flat-shaded mesh builder. All static details in a patch share one draw call.
var vertices := PackedVector3Array()
var normals := PackedVector3Array()
var colors := PackedColorArray()

func face(a:Vector3,b:Vector3,c:Vector3,paint:Color,out:Vector3):
	var normal=(b-a).cross(c-a).normalized()
	if normal.dot(out)<0.0:
		normal=-normal
	else:
		var swap=b
		b=c
		c=swap
	vertices.append_array(PackedVector3Array([a,b,c]))
	normals.append_array(PackedVector3Array([normal,normal,normal]))
	colors.append_array(PackedColorArray([paint,paint,paint]))

func quad(a:Vector3,b:Vector3,c:Vector3,d:Vector3,paint:Color,out:Vector3):
	face(a,b,c,paint,out)
	face(a,c,d,paint,out)

func box(p:Vector3,size:Vector3,paint:Color,yaw:float=0.0):
	var basis=Basis(Vector3.UP,yaw)
	var x=basis.x*size.x*.5
	var y=Vector3.UP*size.y*.5
	var z=basis.z*size.z*.5
	quad(p-x+y-z,p+x+y-z,p+x+y+z,p-x+y+z,paint,y)
	quad(p-x-y-z,p+x-y-z,p+x-y+z,p-x-y+z,paint,-y)
	quad(p-x-y-z,p-x+y-z,p-x+y+z,p-x-y+z,paint,-x)
	quad(p+x-y-z,p+x+y-z,p+x+y+z,p+x-y+z,paint,x)
	quad(p-x-y-z,p+x-y-z,p+x+y-z,p-x+y-z,paint,-z)
	quad(p-x-y+z,p+x-y+z,p+x+y+z,p-x+y+z,paint,z)

func rod(a:Vector3,b:Vector3,ra:float,rb:float,paint:Color,n:int=7):
	var axis=(b-a).normalized()
	if axis.length_squared()<.5: return
	var ref=Vector3.UP if abs(axis.y)<.9 else Vector3.FORWARD
	var u=axis.cross(ref).normalized()
	var v=axis.cross(u).normalized()
	for i in n:
		var p=u*cos(TAU*i/n)+v*sin(TAU*i/n)
		var q=u*cos(TAU*(i+1)/n)+v*sin(TAU*(i+1)/n)
		quad(a+p*ra,a+q*ra,b+q*rb,b+p*rb,paint,p+q)
		if ra>.001: face(a,a+p*ra,a+q*ra,paint,-axis)
		if rb>.001: face(b,b+p*rb,b+q*rb,paint,axis)

func column(p:Vector3,height:float,r0:float,r1:float,paint:Color,n:int=8):
	rod(p,p+Vector3.UP*height,r0,r1,paint,n)

func blob(p:Vector3,s:Vector3,paint:Color,seed_num:float=0.0,n:int=7):
	var rings=[]
	for j in 3:
		var ring=[]
		var radii=[.78,1.0,.69]
		var levels=[-.64,-.03,.65]
		for i in n:
			var a=TAU*i/n+seed_num*.24+j*.24
			var wob=1+.12*sin(i*4.79+j*1.73+seed_num*3.16)
			ring.append(p+Vector3(cos(a)*s.x*radii[j]*wob,s.y*(levels[j]+.12*sin(a*3+seed_num)),sin(a)*s.z*radii[j]*wob))
		rings.append(ring)
	for i in n:
		var k=(i+1)%n
		face(p-Vector3.UP*s.y,rings[0][i],rings[0][k],paint,Vector3.DOWN)
		face(p+Vector3.UP*s.y,rings[2][i],rings[2][k],paint,Vector3.UP)
		for j in 2:
			var outward=(rings[j][i]-p)/s
			quad(rings[j][i],rings[j][k],rings[j+1][k],rings[j+1][i],paint,outward)

func mesh(material:Material=null)->ArrayMesh:
	var result=ArrayMesh.new()
	if vertices.is_empty(): return result
	var data=[]
	data.resize(Mesh.ARRAY_MAX)
	data[Mesh.ARRAY_VERTEX]=vertices
	data[Mesh.ARRAY_NORMAL]=normals
	data[Mesh.ARRAY_COLOR]=colors
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,data)
	if material: result.surface_set_material(0,material)
	return result

func node(material:Material)->MeshInstance3D:
	var instance=MeshInstance3D.new()
	instance.mesh=mesh(material)
	return instance

static func palette()->StandardMaterial3D:
	var m=StandardMaterial3D.new()
	m.vertex_color_use_as_albedo=true
	m.vertex_color_is_srgb=false
	m.roughness=.96
	m.cull_mode=BaseMaterial3D.CULL_DISABLED
	return m
