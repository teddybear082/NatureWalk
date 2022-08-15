extends MeshInstance
class_name Chunk

var should_remove
var size
var noise
var pos_x
var pos_z

var vertex

var rng = RandomNumberGenerator.new()
var n

func _init(n,s,x,z):
	noise = n
	size = s
	pos_x = x
	pos_z = z 

func _ready():
	# initialize ground
	var array = ArrayMesh.new()
	var plane = PlaneMesh.new()
	var particals = Particles.new()
	var quad = QuadMesh.new()
	plane.size = Vector2(size,size)
	plane.subdivide_depth = size*2
	plane.subdivide_width = size*2
	
	# initialize Water
	var water = MeshInstance.new()
	water.set_mesh(plane)
	water.get_mesh().surface_set_material(0,preload("res://World/Water/water.material"))
	
	# initialize grass
	var grass = MultiMesh.new()
	grass.set_mesh(preload("res://World/Grass/grass_blade.obj"))
	grass.get_mesh().surface_set_material(0,preload("res://World/Grass/grass.material"))
	grass.set_transform_format(MultiMesh.TRANSFORM_3D)
	
	# initialize rock
	var rock = preload("res://World/Rock/Rock.tscn").instance()
	
	# initialize tree
	var tree = preload("res://World/Tree/Tree.tscn").instance()
	
	array.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, plane.get_mesh_arrays())
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(array, 0)
	
	
	grass.instance_count = mdt.get_vertex_count()
	for i in range(mdt.get_vertex_count()):
		vertex = mdt.get_vertex(i)
		n = noise.get_noise_2d(pos_x+vertex.x,pos_z+vertex.z) * 20
		vertex += Vector3(0,n,0)
		mdt.set_vertex(i, vertex)
		
		# mask by hight
		if n > 1:
			rng.randomize()
			var r = rng.randi_range(-90,90)
			grass.set_instance_transform(i, Transform(Basis().rotated(Vector3.UP,r),vertex+Vector3(rng.randf_range(-0.2,0.2),0,rng.randf_range(-0.2,0.2))))
			# place in middle
			if i == mdt.get_vertex_count()/2:
				rock.translation = vertex
				tree.translation = vertex
		else:
			grass.set_instance_transform(i, Transform().scaled(Vector3.ZERO))
	
	
	array.surface_remove(0)
	mdt.commit_to_surface(array)
	mesh = array
	
	# add material
	mesh.surface_set_material(0,preload("res://World/ground.material"))
	
	# add collision
	var shape = mesh.create_trimesh_shape()
	add_child(StaticBody.new())
	get_child(0).add_child(CollisionShape.new())
	get_child(0).get_child(0).set_shape(shape)
	
	# add water
	add_child(water)
	
	# add grass
	var multimesh = MultiMeshInstance.new()
	multimesh.set_multimesh(grass)
	multimesh.set_cast_shadows_setting(0)
	add_child(multimesh)
	
	# randomly add rock or tree
	rng.randomize()
	var r = rng.randi_range(1,10)
	if pos_x !=0 and pos_z != 0:
		if n > 1:
			if r < 3:
				rock.scale = Vector3.ONE*r
				rock.rotation = Vector3.ONE*r*20
				add_child(rock)
			else:
				tree.scale = Vector3.ONE*rng.randi_range(1,2)
				tree.rotation = Vector3.UP*r
				add_child(tree)
	
	#add fireflies
	quad.surface_set_material(0,preload("res://World/firefly.material"))
	particals.set_draw_pass_mesh(0,quad)
	particals.set_process_material(preload("res://World/fireflies.material"))
	particals.amount = 8
	particals.translation = vertex
	particals.amount = 16
	add_child(particals)
