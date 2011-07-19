class Line
  constructor: (color, v1, v2, scene) ->
    @material = new THREE.LineBasicMaterial color: color, linewidth: 5
    
    @geometry = new THREE.Geometry
    @geometry.push new THREE.Vertex(v1), new THREE.Vertex(v2)
    
    @line = new THREE.Line @geometry, @material
    @setScene scene
  
  setScene: (scene) ->
    scene?.addObject @line

KEY_MAP = {
  up: 38, down: 40, left: 37, right: 39
  w: 87, a: 65, s: 83, d: 68
  f: 70
}

class Scene
  createRenderer: ->
    @container = document.createElement 'div'
    document.body.appendChild @container

    @renderer = new THREE.WebGLRenderer antialias: true
    @renderer.setSize window.innerWidth, window.innerHeight
    @container.appendChild @renderer.domElement

    if Stats?
      @stats = new Stats();
      @stats.domElement.style.position = 'absolute';
      @stats.domElement.style.top = '0px';
      @container.appendChild @stats.domElement

    window.addEventListener 'resize', ->
      w = window.innerWidth
      h = window.innerHeight
      
      @camera.aspect = w / h
      @camera.updateProjectionMatrix()
      
      @renderer.setSize w, h

  render: =>
    requestAnimationFrame @render, @renderer.domElement
    do @stats.update

    @renderer.render @scene, @camera

  constructor: ->
    @camera = new THREE.FirstPersonCamera fov: 75, aspect: window.innerWidth / window.innerHeight, near: 1, far: 10000
    @camera.position.z = 200
    @camera.position.y = 50
    @camera.lon = -80
    @camera.movementSpeed = 60
    @camera.lookSpeed = 0.08

    @scene = new THREE.Scene

    @light = new THREE.PointLight 0xffffff
    @light.position = @camera.position
    @scene.addLight @light
  
  _keyUp: (e) =>
    code = e.keyCode
    callbacks = @_keyUps?[code]
    if callbacks
      for callback in callbacks
        callback.call @

  keyUp: (code, callback) ->
    code = KEY_MAP[code]
    downs = @_keyUps ||= {}
    callbacks = downs[code] ||= []
    callbacks.push(callback) if callback not in callbacks
    
    if not @_keyUpListener
      @_keyUpListener = document.addEventListener 'keyup', @_keyUp
  
  @keyUp: (code, callback) ->
    @::keyUp code, callback
  
  addObject: (object) ->
    @scene.addObject object

class Editor extends Scene
  constructor: ->
    super
    
    @gridMaterial = new THREE.MeshBasicMaterial color: 0x555555, wireframe: true
    @grid = new THREE.Mesh new THREE.PlaneGeometry(1000, 1000, 100, 100), @gridMaterial
    @grid.rotation.x = - 90 * Math.PI / 180
    @addObject @grid
  
  @keyUp 'f', -> console.log 'f'

editor = new Editor
editor.createRenderer()
editor.render()

wireframes = window.wireframes = []

points = [
  new THREE.Vector3 0, 0, 0
  new THREE.Vector3 100, 0, 0
  new THREE.Vector3 150, 100, 0
  new THREE.Vector3 200, 115, -100
  new THREE.Vector3 200, 100, -200
  new THREE.Vector3 100, 0, -200
  new THREE.Vector3 0, 0, -200
  new THREE.Vector3 -70, 75, -200
  new THREE.Vector3 0, 170, -210
  new THREE.Vector3 70, 75, -220
  new THREE.Vector3 0, 0, -220
  new THREE.Vector3 -100, 0, -220
  new THREE.Vector3 0, 0, 0
]

line = new THREE.Geometry
mesh = new THREE.Geometry

spline = new THREE.Spline points
subs =  500
thickness = 5

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
editor.addObject new THREE.Line line, material

# draw mesh
mesh.computeFaceNormals()
wireframes.push material = new THREE.MeshLambertMaterial color:0xff0000, shading: THREE.SmoothShading, wireframe: yes
editor.addObject new THREE.Mesh mesh, material

editor.keyUp 'f', -> w.wireframe = !w.wireframe for w in wireframes
