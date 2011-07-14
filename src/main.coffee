container = document.createElement 'div'
document.body.appendChild container

camera = new THREE.FirstPersonCamera fov: 75, aspect: window.innerWidth / window.innerHeight, near: 1, far: 10000
camera.position.z = 200
camera.rotation.y = 0
camera.movementSpeed = 60
camera.lookSpeed = 0.08

scene = new THREE.Scene

light = new THREE.PointLight 0xffffff
light.position = camera.position
scene.addLight light


points = [
  new THREE.Vector3 0, 0, 0
  new THREE.Vector3 100, 0, 0
  new THREE.Vector3 100, 100, 0
  # new THREE.Vector3 100, 0, 0
  # new THREE.Vector3 200, 100, 0
  # new THREE.Vector3 200, 115, -100
  # new THREE.Vector3 200, 100, -200
  # new THREE.Vector3 100, 0, -200
  # new THREE.Vector3 0, 0, -200
  # new THREE.Vector3 0, 0, 0
]

line = new THREE.Geometry
mesh = new THREE.Geometry

spline = new THREE.Spline points
subs = points.length * 50

localToGlobal = (pos, t, nextT) ->
  if not t or not nextT
    return pos
  
  b = new THREE.Vector3
  b.cross t, nextT
  
  if b.length() is 0
    return pos.clone()
  
  b.normalize()
  b.addSelf(pos)
  
  material = new THREE.LineBasicMaterial color: 0x00ff00, opacity: 1, linewidth: 5
  geo = new THREE.Geometry
  geo.vertices.push(pos.clone(), b.clone())
  bline = new THREE.Line geo, material
  scene.addObject bline
  
  theta = Math.acos(t.dot(nextT))
  
  result = pos.clone()
  r = new THREE.Matrix4
  r.setRotationAxis(b,theta)
  r.multiplyVector3(result)
  
  result
  
tangentForPoint = (i) ->
  lastPos = spline.getPoint Math.max(i - 1, 0) / subs
  lastPos = new THREE.Vector3 lastPos.x, lastPos.y, lastPos.z
  nextPos = spline.getPoint Math.min(i + 1, subs) / subs
  nextPos = new THREE.Vector3 nextPos.x, nextPos.y, nextPos.z
  
  tangent = new THREE.Vector3
  tangent.sub(nextPos, lastPos)
  tangent.normalize()
  tangent

for i in [0..subs]
  index = i / subs
  pos = spline.getPoint index
  pos = new THREE.Vector3 pos.x, pos.y, pos.z
  
  line.vertices[i] = new THREE.Vertex pos.clone()
  
  if i > 0
    prevTan = tangentForPoint i - 1
    tan = tangentForPoint i
  else
    prevTan = null
    tan = null
  
  mesh.vertices[i*4] = new THREE.Vertex localToGlobal(new THREE.Vector3(pos.x, pos.y - 5, pos.z - 5), prevTan, tan)
  mesh.vertices[i*4+1] = new THREE.Vertex localToGlobal(new THREE.Vector3(pos.x, pos.y - 5, pos.z + 5), prevTan, tan)
  mesh.vertices[i*4+2] = new THREE.Vertex localToGlobal(new THREE.Vector3(pos.x, pos.y + 5, pos.z + 5), prevTan, tan)
  mesh.vertices[i*4+3] = new THREE.Vertex localToGlobal(new THREE.Vector3(pos.x, pos.y + 5, pos.z - 5), prevTan, tan)
  
  if i > 0
    mesh.faces.push new THREE.Face4 i*4-4, i*4, i*4+1, i*4-3 #bottom
    mesh.faces.push new THREE.Face4 i*4-3, i*4+1, i*4+2, i*4-2 #right
    mesh.faces.push new THREE.Face4 i*4-2, i*4+2, i*4+3, i*4-1 #top
    mesh.faces.push new THREE.Face4 i*4-1, i*4+3, i*4, i*4-4 #left
  
  # q = new THREE.Quaternion pos.x, pos.y, pos.z
  
  # geometry = new THREE.CubeGeometry 5, 5, 5
  # mesh = new THREE.Mesh geometry, material
  
  # mesh.position.x = pos.x
  # mesh.position.y = pos.y
  # mesh.position.z = pos.z
  
  # scene.addObject mesh

# draw line
material = new THREE.LineBasicMaterial color: 0xff0000, opacity: 1, linewidth: 5
scene.addObject new THREE.Line line, material

# draw mesh
mesh.computeCentroids()
mesh.computeFaceNormals()
material = new THREE.MeshLambertMaterial color:0xff0000, shading: THREE.SmoothShading, wireframe: yes
scene.addObject new THREE.Mesh mesh, material

renderer = new THREE.WebGLRenderer antialias: true
renderer.setSize window.innerWidth, window.innerHeight
container.appendChild renderer.domElement

stats = new Stats();
stats.domElement.style.position = 'absolute';
stats.domElement.style.top = '0px';
container.appendChild( stats.domElement );

animate = ->
  requestAnimationFrame animate, renderer.domElement
  render()
  stats.update()

render = ->
  # mesh.rotation.x += 0.01
  # mesh.rotation.y += 0.02
  
  renderer.render scene, camera

animate()

window.addEventListener 'resize', ->
  w = window.innerWidth
  h = window.innerHeight
  
  camera.aspect = w / h
  camera.updateProjectionMatrix()
  
  renderer.setSize w, h