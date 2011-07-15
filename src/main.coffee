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
  new THREE.Vector3 200, 115, -100
  new THREE.Vector3 200, 100, -200
  new THREE.Vector3 100, 0, -200
  new THREE.Vector3 0, 0, -200
  new THREE.Vector3 0, 0, 0
]

line = new THREE.Geometry
mesh = new THREE.Geometry

spline = new THREE.Spline points
subs =  500
thickness = 5

addLine = (color, v1, v2) ->
  bLineMat = new THREE.LineBasicMaterial({ color: color, linewidth: 5 })
  bGeo = new THREE.Geometry()
  bGeo.vertices.push(new THREE.Vertex(v1), new THREE.Vertex(v2) )
  bLine = new THREE.Line(bGeo, bLineMat)
  scene.addObject(bLine)

frameRotation = (t, nextT) ->
  if not t or not nextT
    return (pos) ->
      pos
  
  b = new THREE.Vector3
  b.cross t, nextT
  
  b.normalize()
  
  r = new THREE.Matrix4
  theta = Math.acos(t.dot(nextT))
  
  r.setRotationAxis(b, theta)
  
  return (pos) ->
    r.multiplyVector3(pos)
    
    pos


tangentForPoint = (i) ->
  if i - 1 < 0
    return null
  prevPos = spline.getPoint Math.max(i - 1, 0) / subs
  prevPos = new THREE.Vector3 prevPos.x, prevPos.y, prevPos.z
  nextPos = spline.getPoint Math.min(i + 1, subs) / subs
  nextPos = new THREE.Vector3 nextPos.x, nextPos.y, nextPos.z
  
  tangent = new THREE.Vector3
  tangent.sub(nextPos, prevPos)
  tangent.normalize()
  tangent
  

prevPos = null
prevTan = null
tan = null
for i in [0..subs]
  index = i / subs
  pos = spline.getPoint index
  pos = new THREE.Vector3 pos.x, pos.y, pos.z
  
  line.vertices[i] = new THREE.Vertex pos.clone()
  
  if i > 0
    tan = tangentForPoint i
    rotate = frameRotation(prevTan, tan)
    
    for j in [0..3]
      vertex = mesh.vertices[(i-1)*4 + j].position.clone().subSelf(prevPos)
      mesh.vertices[i*4 + j] = new THREE.Vertex rotate(vertex).addSelf(pos)
      
    mesh.faces.push new THREE.Face4 i*4-4, i*4, i*4+1, i*4-3 #bottom
    mesh.faces.push new THREE.Face4 i*4-3, i*4+1, i*4+2, i*4-2 #right
    mesh.faces.push new THREE.Face4 i*4-2, i*4+2, i*4+3, i*4-1 #top
    mesh.faces.push new THREE.Face4 i*4-1, i*4+3, i*4, i*4-4 #left
  else
    mesh.vertices[i*4]   = new THREE.Vertex(new THREE.Vector3(0, -thickness, -thickness).addSelf(pos))
    mesh.vertices[i*4+1] = new THREE.Vertex(new THREE.Vector3(0, -thickness, thickness).addSelf(pos))
    mesh.vertices[i*4+2] = new THREE.Vertex(new THREE.Vector3(0, thickness, thickness).addSelf(pos))
    mesh.vertices[i*4+3] = new THREE.Vertex(new THREE.Vector3(0, thickness, -thickness).addSelf(pos))
  
  prevPos = pos
  prevTan = tan

# draw line
material = new THREE.LineBasicMaterial color: 0xff0000, opacity: 1, linewidth: 1
scene.addObject new THREE.Line line, material

# draw mesh
mesh.computeFaceNormals()
material = new THREE.MeshLambertMaterial color:0xff0000, shading: THREE.SmoothShading, wireframe: no
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