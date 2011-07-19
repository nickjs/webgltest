(function() {
  var Editor, KEY_MAP, Line, Scene, editor, frameRotation, i, index, j, line, material, mesh, points, pos, prevPos, prevTan, rotate, spline, subs, tan, tangentForPoint, thickness, vertex, wireframes;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
  }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  Line = (function() {
    function Line(color, v1, v2, scene) {
      this.material = new THREE.LineBasicMaterial({
        color: color,
        linewidth: 5
      });
      this.geometry = new THREE.Geometry;
      this.geometry.push(new THREE.Vertex(v1), new THREE.Vertex(v2));
      this.line = new THREE.Line(this.geometry, this.material);
      this.setScene(scene);
    }
    Line.prototype.setScene = function(scene) {
      return scene != null ? scene.addObject(this.line) : void 0;
    };
    return Line;
  })();
  KEY_MAP = {
    up: 38,
    down: 40,
    left: 37,
    right: 39,
    w: 87,
    a: 65,
    s: 83,
    d: 68,
    f: 70
  };
  Scene = (function() {
    Scene.prototype.createRenderer = function() {
      this.container = document.createElement('div');
      document.body.appendChild(this.container);
      this.renderer = new THREE.WebGLRenderer({
        antialias: true
      });
      this.renderer.setSize(window.innerWidth, window.innerHeight);
      this.container.appendChild(this.renderer.domElement);
      if (typeof Stats !== "undefined" && Stats !== null) {
        this.stats = new Stats();
        this.stats.domElement.style.position = 'absolute';
        this.stats.domElement.style.top = '0px';
        this.container.appendChild(this.stats.domElement);
      }
      return window.addEventListener('resize', function() {
        var h, w;
        w = window.innerWidth;
        h = window.innerHeight;
        this.camera.aspect = w / h;
        this.camera.updateProjectionMatrix();
        return this.renderer.setSize(w, h);
      });
    };
    Scene.prototype.render = function() {
      requestAnimationFrame(this.render, this.renderer.domElement);
      this.stats.update();
      return this.renderer.render(this.scene, this.camera);
    };
    function Scene() {
      this._keyUp = __bind(this._keyUp, this);;
      this.render = __bind(this.render, this);;      this.camera = new THREE.FirstPersonCamera({
        fov: 75,
        aspect: window.innerWidth / window.innerHeight,
        near: 1,
        far: 10000
      });
      this.camera.position.z = 200;
      this.camera.position.y = 50;
      this.camera.lon = -80;
      this.camera.movementSpeed = 60;
      this.camera.lookSpeed = 0.08;
      this.scene = new THREE.Scene;
      this.light = new THREE.PointLight(0xffffff);
      this.light.position = this.camera.position;
      this.scene.addLight(this.light);
    }
    Scene.prototype._keyUp = function(e) {
      var callback, callbacks, code, _i, _len, _ref, _results;
      code = e.keyCode;
      callbacks = (_ref = this._keyUps) != null ? _ref[code] : void 0;
      if (callbacks) {
        _results = [];
        for (_i = 0, _len = callbacks.length; _i < _len; _i++) {
          callback = callbacks[_i];
          _results.push(callback.call(this));
        }
        return _results;
      }
    };
    Scene.prototype.keyUp = function(code, callback) {
      var callbacks, downs;
      code = KEY_MAP[code];
      downs = this._keyUps || (this._keyUps = {});
      callbacks = downs[code] || (downs[code] = []);
      if (__indexOf.call(callbacks, callback) < 0) {
        callbacks.push(callback);
      }
      if (!this._keyUpListener) {
        return this._keyUpListener = document.addEventListener('keyup', this._keyUp);
      }
    };
    Scene.keyUp = function(code, callback) {
      return this.prototype.keyUp(code, callback);
    };
    Scene.prototype.addObject = function(object) {
      return this.scene.addObject(object);
    };
    return Scene;
  })();
  Editor = (function() {
    function Editor() {
      Editor.__super__.constructor.apply(this, arguments);
      this.gridMaterial = new THREE.MeshBasicMaterial({
        color: 0x555555,
        wireframe: true
      });
      this.grid = new THREE.Mesh(new THREE.PlaneGeometry(1000, 1000, 100, 100), this.gridMaterial);
      this.grid.rotation.x = -90 * Math.PI / 180;
      this.addObject(this.grid);
    }
    __extends(Editor, Scene);
    Editor.keyUp('f', function() {
      return console.log('f');
    });
    return Editor;
  })();
  editor = new Editor;
  editor.createRenderer();
  editor.render();
  wireframes = window.wireframes = [];
  points = [new THREE.Vector3(0, 0, 0), new THREE.Vector3(100, 0, 0), new THREE.Vector3(150, 100, 0), new THREE.Vector3(200, 115, -100), new THREE.Vector3(200, 100, -200), new THREE.Vector3(100, 0, -200), new THREE.Vector3(0, 0, -200), new THREE.Vector3(-70, 75, -200), new THREE.Vector3(0, 170, -210), new THREE.Vector3(70, 75, -220), new THREE.Vector3(0, 0, -220), new THREE.Vector3(-100, 0, -220), new THREE.Vector3(0, 0, 0)];
  line = new THREE.Geometry;
  mesh = new THREE.Geometry;
  spline = new THREE.Spline(points);
  subs = 500;
  thickness = 5;
  frameRotation = function(t, nextT) {
    var b, r, theta;
    if (!t || !nextT) {
      return function(pos) {
        return pos;
      };
    }
    b = new THREE.Vector3;
    b.cross(t, nextT);
    b.normalize();
    r = new THREE.Matrix4;
    theta = Math.acos(t.dot(nextT));
    r.setRotationAxis(b, theta);
    return function(pos) {
      r.multiplyVector3(pos);
      return pos;
    };
  };
  tangentForPoint = function(i) {
    var nextPos, prevPos, tangent;
    if (i - 1 < 0) {
      return null;
    }
    prevPos = spline.getPoint(Math.max(i - 1, 0) / subs);
    prevPos = new THREE.Vector3(prevPos.x, prevPos.y, prevPos.z);
    nextPos = spline.getPoint(Math.min(i + 1, subs) / subs);
    nextPos = new THREE.Vector3(nextPos.x, nextPos.y, nextPos.z);
    tangent = new THREE.Vector3;
    tangent.sub(nextPos, prevPos);
    tangent.normalize();
    return tangent;
  };
  prevPos = null;
  prevTan = null;
  tan = null;
  for (i = 0; 0 <= subs ? i <= subs : i >= subs; 0 <= subs ? i++ : i--) {
    index = i / subs;
    pos = spline.getPoint(index);
    pos = new THREE.Vector3(pos.x, pos.y, pos.z);
    line.vertices[i] = new THREE.Vertex(pos.clone());
    if (i > 0) {
      tan = tangentForPoint(i);
      rotate = frameRotation(prevTan, tan);
      for (j = 0; j <= 3; j++) {
        vertex = mesh.vertices[(i - 1) * 4 + j].position.clone().subSelf(prevPos);
        mesh.vertices[i * 4 + j] = new THREE.Vertex(rotate(vertex).addSelf(pos));
      }
      mesh.faces.push(new THREE.Face4(i * 4 - 4, i * 4, i * 4 + 1, i * 4 - 3));
      mesh.faces.push(new THREE.Face4(i * 4 - 3, i * 4 + 1, i * 4 + 2, i * 4 - 2));
      mesh.faces.push(new THREE.Face4(i * 4 - 2, i * 4 + 2, i * 4 + 3, i * 4 - 1));
      mesh.faces.push(new THREE.Face4(i * 4 - 1, i * 4 + 3, i * 4, i * 4 - 4));
    } else {
      mesh.vertices[i * 4] = new THREE.Vertex(new THREE.Vector3(0, -thickness, -thickness).addSelf(pos));
      mesh.vertices[i * 4 + 1] = new THREE.Vertex(new THREE.Vector3(0, -thickness, thickness).addSelf(pos));
      mesh.vertices[i * 4 + 2] = new THREE.Vertex(new THREE.Vector3(0, thickness, thickness).addSelf(pos));
      mesh.vertices[i * 4 + 3] = new THREE.Vertex(new THREE.Vector3(0, thickness, -thickness).addSelf(pos));
    }
    prevPos = pos;
    prevTan = tan;
  }
  material = new THREE.LineBasicMaterial({
    color: 0xff0000,
    opacity: 1,
    linewidth: 1
  });
  editor.addObject(new THREE.Line(line, material));
  mesh.computeFaceNormals();
  wireframes.push(material = new THREE.MeshLambertMaterial({
    color: 0xff0000,
    shading: THREE.SmoothShading,
    wireframe: true
  }));
  editor.addObject(new THREE.Mesh(mesh, material));
  editor.keyUp('f', function() {
    var w, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = wireframes.length; _i < _len; _i++) {
      w = wireframes[_i];
      _results.push(w.wireframe = !w.wireframe);
    }
    return _results;
  });
}).call(this);
