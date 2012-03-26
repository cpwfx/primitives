package com.ideaskill.primitives.csg {
	import com.ideaskill.primitives.MeshData;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	/**
	 * Constructive Solid Geometry (CSG).
	 * 
	 * Holds a binary space partition tree representing a 3D solid. Two solids can
	 * be combined using the union(), subtract(), and intersect() methods.
	 * 
	 * @author Evan Wallace, under MIT license
	 * @author makc AS3 port
	 * @see https://github.com/evanw/csg.js
	 */
	public class CSG {

		private var root:Node;

		private function meshToPolygons (mesh:MeshData):Vector.<Polygon> {
			var n:int = mesh.indices.length / 3;
			var polygons:Vector.<Polygon> = new Vector.<Polygon> (n);
			for (var i:int = 0; i < n; i++) {
				var vertices:Vector.<Vertex> = new Vector.<Vertex> (3);
				for (var j:int = 0; j < 3; j++) {
					var v:Vertex = new Vertex;
					var k:int = mesh.indices [i * 3 + j], k2:int = k + k, k3:int = k2 + k;
					v.x = mesh.vertices [k3];
					v.y = mesh.vertices [k3 + 1];
					v.z = mesh.vertices [k3 + 2];
					v.u = mesh.uvs [k2];
					v.v = mesh.uvs [k2 + 1];
					v.nx = mesh.vertexNormals [k3];
					v.ny = mesh.vertexNormals [k3 + 1];
					v.nz = mesh.vertexNormals [k3 + 2];
					v.tx = mesh.vertexTangents [k3];
					v.ty = mesh.vertexTangents [k3 + 1];
					v.tz = mesh.vertexTangents [k3 + 2];
					vertices [j] = v;
				}
				polygons [i] = new Polygon (vertices);
			}
			return polygons;
		}

		public function toMesh ():MeshData {
			var seenPoly:Dictionary = new Dictionary (true);
			var polygons:Vector.<Polygon> = new <Polygon> [], poly:Polygon;
			var min:Vector3D = new Vector3D (+Number.MAX_VALUE, +Number.MAX_VALUE, +Number.MAX_VALUE);
			var max:Vector3D = new Vector3D (-Number.MAX_VALUE, -Number.MAX_VALUE, -Number.MAX_VALUE);
			for each (poly in root.allPolygons ()) {
				var source:Polygon = poly.merge ();
				if (seenPoly [source] != true) {
					seenPoly [source] = true;
					source.updateBounds (min, max);
					polygons.push (source);
				}
			}
			
			// precompute: to use foo / max.x instead of foo * base / (max.x - min.x)
			var vertexHashBase:Number = 100;
			max.decrementBy (min); max.scaleBy (1 / vertexHashBase);
			
			var i:int, j:int, k:int;
			var mesh:MeshData = new MeshData ();
			var vertex:Vertex;
			var vertexCache:Object = {};
			var vertices:Vector.<Vertex> = new <Vertex> [];
			for each (poly in polygons) {
				// vmap: maps poly.vertices to var vertices
				var vmap:Vector.<int> = new Vector.<int> (poly.vertices.length, true);
				for (i = 0; i < poly.vertices.length; i++) {
					vertex = poly.vertices [i];
					var vx:int = (vertex.x - min.x) / max.x;
					var vy:int = (vertex.y - min.y) / max.y;
					var vz:int = (vertex.z - min.z) / max.z;
					var hash:int = vertexHashBase * (vertexHashBase * vx + vy) + vz;
					var bucket:Vector.<int> = vertexCache [hash] as Vector.<int>;
					if (bucket) {
						var notFound:Boolean = true;
						for (j = 0; j < bucket.length; j++) {
							k = bucket [j];
							if (vertices [k].equals (vertex)) {
								notFound = false; vmap [i] = k; break;
							}
						}
						if (notFound) {
							k = vertices.length;
							vmap [i] = k; vertices.push (vertex);
							bucket.push (k);
						}
					} else {
						k = vertices.length;
						vmap [i] = k; vertices.push (vertex);
						vertexCache [hash] = new <int> [k];
					}
				}
				
				var triangles:Vector.<Vector.<int>> = poly.triangulate ();
				for each (var tri:Vector.<int> in triangles) {
					mesh.indices.push (vmap [tri [0]], vmap [tri [1]], vmap [tri [2]]);
				}
			}
			
			mesh.vertices.length = 3 * vertices.length;
			mesh.vertexNormals.length = mesh.vertices.length;
			mesh.vertexTangents.length = mesh.vertices.length;
			mesh.uvs.length = 2 * vertices.length;

			for (i = 0; i < vertices.length; i++) {
				vertex = vertices [i];
				j = 3 * i;
				mesh.vertices [j] = vertex.x;
				mesh.vertexNormals [j] = vertex.nx;
				mesh.vertexTangents [j] = vertex.tx;
				j++;
				mesh.vertices [j] = vertex.y;
				mesh.vertexNormals [j] = vertex.ny;
				mesh.vertexTangents [j] = vertex.ty;
				j++;
				mesh.vertices [j] = vertex.z;
				mesh.vertexNormals [j] = vertex.nz;
				mesh.vertexTangents [j] = vertex.tz;
				j = 2 * i;
				mesh.uvs [j] = vertex.u;
				mesh.uvs [j + 1] = vertex.v;
			}
			
			// after wasting memory generously I'm suddenly being paranoid
			seenPoly = null; polygons.length = 0; vertices.length = 0; vertexCache = null;
			
			return mesh;
		}

		/**
		 * Construct a CSG solid from a MeshData instance.
		 */
		public function CSG (mesh:MeshData) {
			if (mesh == null) return;
			root = new Node;
			root.build (meshToPolygons (mesh));
		}

		private function clone ():CSG {
			var bsp:CSG = new CSG (null);
			bsp.root = this.root.clone ();
			return bsp;
		}

		/**
		 * Return a new CSG solid representing space in either this solid or in the
		 * solid bsp. Neither this solid nor the solid bsp are modified.
		 */
		public function union (bsp:CSG):CSG {
			var a:CSG = this.clone(), b:CSG = bsp.clone();
			a.root.clipTo(b.root);
			b.root.clipTo(a.root);
			b.root.invert();
			b.root.clipTo(a.root);
			b.root.invert();
			a.root.build(b.root.allPolygons());
			return a;
		}

		/**
		 * Return a new CSG solid representing space in this solid but not in the
		 * solid bsp. Neither this solid nor the solid bsp are modified.
		 */
		public function subtract (bsp:CSG):CSG {
			var a:CSG = this.clone(), b:CSG = bsp.clone();
			a.root.invert();
			a.root.clipTo(b.root);
			b.root.clipTo(a.root);
			b.root.invert();
			b.root.clipTo(a.root);
			b.root.invert();
			a.root.build(b.root.allPolygons());
			a.root.invert();
			return a;
		}

		/**
		 * Return a new CSG solid representing space both this solid and in the
		 * solid bsp. Neither this solid nor the solid bsp are modified.
		 */
		public function intersect (bsp:CSG):CSG {
			var a:CSG = this.clone(), b:CSG = bsp.clone();
			a.root.invert();
			b.root.clipTo(a.root);
			b.root.invert();
			a.root.clipTo(b.root);
			b.root.clipTo(a.root);
			a.root.build(b.root.allPolygons());
			a.root.invert();
			return a;
		}

		/**
		 * Return a new CSG solid with solid and empty space switched. This solid is
		 * not modified.
		 */
		public function inverse ():CSG {
			var bsp:CSG = this.clone();
			bsp.root.invert();
			return bsp;
		}
	}
}

/**
 * Represents a vertex of a polygon.
 */
class Vertex {
	public var x:Number;
	public var y:Number;
	public var z:Number;
	public var u:Number;
	public var v:Number;
	public var nx:Number;
	public var ny:Number;
	public var nz:Number;
	public var tx:Number;
	public var ty:Number;
	public var tz:Number;
	
	public function equals (vertex:Vertex, e:Number = 1e-5):Boolean {
		return (
			(Math.abs (x - vertex.x) < e) &&
			(Math.abs (y - vertex.y) < e) &&
			(Math.abs (z - vertex.z) < e) &&
			(Math.abs (u - vertex.u) < e) &&
			(Math.abs (v - vertex.v) < e) &&
			(Math.abs (nx - vertex.nx) < e) &&
			(Math.abs (ny - vertex.ny) < e) &&
			(Math.abs (nz - vertex.nz) < e) &&
			(Math.abs (tx - vertex.tx) < e) &&
			(Math.abs (ty - vertex.ty) < e) &&
			(Math.abs (tz - vertex.tz) < e)
		);
	}

	public function interpolate (other:Vertex, t:Number):Vertex {
		var v:Vertex = new Vertex;

		lerp (this.x, this.y, this.z, other.x, other.y, other.z, t);
		v.x = lx; v.y = ly; v.z = lz;

		lerp (this.u, this.v, 0, other.u, other.v, 0, t);
		v.u = lx; v.v = ly;

		slerp (this.nx, this.ny, this.nz, other.nx, other.ny, other.nz, t);
		v.nx = sx; v.ny = sy; v.nz = sz;

		slerp (this.tx, this.ty, this.tz, other.tx, other.ty, other.tz, t);
		v.tx = sx; v.ty = sy; v.tz = sz;

		// orthogonalize t to n
		cross (v.tx, v.ty, v.tz, v.nx, v.ny, v.nz);
		cross (v.nx, v.ny, v.nz,   cx,   cy,   cz);
		var L:Number = Math.sqrt (cx * cx + cy * cy + cz * cz);
		v.tx = cx / L; v.ty = cy / L; v.tz = cz / L;

		return v;
	}
	
	public function clone ():Vertex {
		var c:Vertex = new Vertex;
		c.x = x; c.y = y; c.z = z;
		c.u = u; c.v = v;
		c.nx = nx; c.ny = ny; c.nz = nz;
		c.tx = tx; c.ty = ty; c.tz = tz;
		return c;
	}
	
	public function flip ():Vertex {
		var c:Vertex = clone ();
		c.nx = -nx; c.ny = -ny; c.nz = -nz;
		c.tx = -tx; c.ty = -ty; c.tz = -tz;
		return c;
	}

	private var cx:Number;
	private var cy:Number;
	private var cz:Number;
	private function cross (x1:Number, y1:Number, z1:Number, x2:Number, y2:Number, z2:Number):void {
		cx = y1 * z2 - z1 * y2;
		cy = z1 * x2 - x1 * z2;
		cz = x1 * y2 - y1 * x2;
	}

	private var lx:Number;
	private var ly:Number;
	private var lz:Number;
	private function lerp (x1:Number, y1:Number, z1:Number, x2:Number, y2:Number, z2:Number, t:Number):void {
		var t1:Number = 1 - t;

		lx = x1 * t1 + x2 * t;
		ly = y1 * t1 + y2 * t;
		lz = z1 * t1 + z2 * t;
	}

	private var sx:Number;
	private var sy:Number;
	private var sz:Number;
	private function slerp (x1:Number, y1:Number, z1:Number, x2:Number, y2:Number, z2:Number, t:Number):void {
		var t1:Number = 1 - t;

// hack until proper fix TODO
L1 = Math.sqrt (x1 * x1 + y1 * y1 + z1 * z1);
L2 = Math.sqrt (x2 * x2 + y2 * y2 + z2 * z2);
Lt = t1 * L1 + t * L2;
lerp (x1, y1, z1, x2, y2, z2, t);
Lt /= Math.sqrt (lx * lx + ly * ly + lz * lz);
sx = lx * Lt; sy = ly * Lt; sz = lz * Lt;
return;


		// projection plane
		var ax:Number, ay:Number, az:Number, bx:Number, by:Number, bz:Number;
		cross (x1, y1, z1, x2, y2, z2);
		var d:Number = cx * cx + cy * cy + cz * cz;
		if (d == 0) {
			ax = 1; ay = 0; az = 0;
			if ((x1 != 0) || (y1 != 0)) {
				bx = 0; by = 1; bz = 0;
			} else {
				bx = 0; by = 0; bz = 1;
			}
		} else {
			if ((cx != 0) || (cy != 0)) {
				ax = -cy; ay = +cx; az = 0;
			} else {
				ax = -cz; ay = 0; az = +cx;
			}
			cross (cx, cy, cz, ax, ay, az);
			bx = cx; by = cy; bz = cz;
		}

		// lengths
		var La:Number = Math.sqrt (ax * ax + ay * ay + az * az);
		var Lb:Number = Math.sqrt (bx * bx + by * by + bz * bz);

		// projection
		var a1:Number = (ax * x1 + ay * y1 + az * z1) / La;
		var b1:Number = (bx * x1 + by * y1 + bz * z1) / Lb;
		var a2:Number = (ax * x2 + ay * y2 + az * z2) / La;
		var b2:Number = (bx * x2 + by * y2 + bz * z2) / Lb;

		// lengths (should be mostly equal)
		var L1:Number = Math.sqrt (a1 * a1 + b1 * b1);
		var L2:Number = Math.sqrt (a2 * a2 + b2 * b2);

		// angles
		var p1:Number = Math.atan2 (a1, b1); if (p1 < 0) p1 += 2 * Math.PI;
		var p2:Number = Math.atan2 (a2, b2); if (p2 < 0) p2 += 2 * Math.PI;

		// interpolate
		var pt:Number = p1 * t1 + p2 * t;
		d = p1 - p2; if ((d > Math.PI) || (d < -Math.PI)) pt += Math.PI;

		var Lt:Number = L1 * t1 + L2 * t;

		// back to vector, 2D
		var at:Number = Lt * Math.sin (pt);
		var bt:Number = Lt * Math.cos (pt);

		// finally, 3D
		sx = ax * at + bx * bt;
		sy = ay * at + by * bt;
		sz = az * at + bz * bt;
	}
}

import flash.geom.Vector3D;

/**
 * Represents a plane in 3D space.
 */
class Plane extends Vector3D {
	public function Plane (x:Number, y:Number, z:Number, w:Number = 0) {
		super (x, y, z, w);
	}

	override public function clone ():Vector3D {
		return new Plane (x, y, z, w);
	}

	/**
	 * The tolerance used by splitPolygon() to decide if a
	 * point is on the plane.
	 */
	static public const EPSILON:Number = 1e-5;

	static private const COPLANAR:int = 0;
	static private const FRONT:int = 1;
	static private const BACK:int = 2;
	static private const SPANNING:int = 3;

	static public function fromPoints (a:Vertex, b:Vertex, c:Vertex):Plane {
		var bax:Number = b.x - a.x, cax:Number = c.x - a.x;
		var bay:Number = b.y - a.y, cay:Number = c.y - a.y;
		var baz:Number = b.z - a.z, caz:Number = c.z - a.z;

		var p:Plane = new Plane (
			bay * caz - baz * cay,
			baz * cax - bax * caz,
			bax * cay - bay * cax
		);

		p.normalize (); p.w = p.x * a.x + p.y * a.y + p.z * a.z;

		return p;
	}

	public function flip ():void {
		x = -x; y = -y; z = -z; w = -w;
	}

	/**
	 * Split polygon by this plane if needed, then put the polygon or polygon
	 * fragments in the appropriate lists.
	 */
	public function splitPolygon (polygon:Polygon, coplanarFront:Vector.<Polygon>, coplanarBack:Vector.<Polygon>, front:Vector.<Polygon>, back:Vector.<Polygon>):void {
		// Classify each point as well as the entire polygon into one of the above
		// four classes.
		var polygonType:int = 0;
		var types:Vector.<int> = new <int> [];
		for (var i:int = 0; i < polygon.vertices.length; i++) {
			var vi:Vertex = polygon.vertices [i];
			var t:Number = x * vi.x + y * vi.y + z * vi.z - w;
			var type:int = (t < -EPSILON) ? BACK : (t > EPSILON) ? FRONT : COPLANAR;
			polygonType |= type;
			types.push (type);
		}

		// Put the polygon in the correct list, splitting it when necessary.
		switch (polygonType) {
			case COPLANAR:
				var list:Vector.<Polygon> = (dotProduct (polygon.plane) > 0) ? coplanarFront : coplanarBack;
				list.push (polygon);
				break;
			case FRONT:
				front.push (polygon);
				break;
			case BACK:
				back.push (polygon);
				break;
			case SPANNING:
				var f:Vector.<Vertex> = new <Vertex> [], b:Vector.<Vertex> = new <Vertex> [];
				for (i = 0; i < polygon.vertices.length; i++) {
					var j:int = (i + 1) % polygon.vertices.length;
					var ti:int = types [i], tj:int = types [j];
					vi = polygon.vertices [i]; var vj:Vertex = polygon.vertices [j];
					if (ti != BACK) f.push (vi);
					if (ti != FRONT) b.push ((ti != BACK) ? vi.clone() : vi);
					if ((ti | tj) == SPANNING) {
						t = (w - x * vi.x - y * vi.y - z * vi.z) / (x * (vj.x - vi.x) + y * (vj.y - vi.y) + z * (vj.z - vi.z));
						var v:Vertex = vi.interpolate (vj, t);
						f.push (v);
						b.push (v.clone());
					}
				}
				if (f.length >= 3) front.push (new Polygon (f, polygon));
				if (b.length >= 3) back.push (new Polygon (b, polygon));
				break;
		}
	}
}

/**
 * Represents a convex polygon.
 */
class Polygon {
	private var source:Polygon;
	private var a:Polygon;
	private var b:Polygon;
	
	public function dispose ():void {
		if (source) {
			var ref:Polygon = source;
			if (ref.a) {
				ref.a.source = null; ref.a = null;
			}
			if (ref.b) {
				ref.b.source = null; ref.b = null;
			}
		}
		
		vertices.length = 0; vertices = null;
		plane = null;
	}
	
	public function merge ():Polygon {
		/* does not work :(
		   TODO find out what's wrong with this
		if (source && source.a && source.b) {
			return source.merge ();
		}
		*/
		return this;
	}

	public var vertices:Vector.<Vertex>;
	public var plane:Plane;

	public function Polygon (vertices:Vector.<Vertex>, source:Polygon = null) {
		this.vertices = vertices;
		
		if (source) {
			this.source = source;
			if (source.a) {
				source.b = this;
			} else {
				source.a = this;
			}
		}
		
		this.plane = Plane.fromPoints (vertices[0], vertices[1], vertices[2]);
	}
	
	public function updateBounds (min:Vector3D, max:Vector3D):void {
		for each (var v:Vertex in vertices) {
			if (v.x < min.x) min.x = v.x;
			if (v.y < min.y) min.y = v.y;
			if (v.z < min.z) min.z = v.z;
			if (v.x > max.x) max.x = v.x;
			if (v.y > max.y) max.y = v.y;
			if (v.z > max.z) max.z = v.z;
		}
	}
	
	public function clone ():Polygon {
		var n:int = vertices.length;
		var v2:Vector.<Vertex> = new Vector.<Vertex> (n);
		for (var i:int = 0; i < n; i++) v2 [i] = vertices [i].clone ();
		return new Polygon (v2);
	}

	public function flip ():void {
		var n:int = vertices.length;
		var v2:Vector.<Vertex> = new Vector.<Vertex> (n);
		for (var i:int = 0; i < n; i++) {
			v2 [n - 1 - i] = vertices [i].flip (); // clones the vertex, too
		}
		vertices = v2;
		plane.flip ();
	}

	public function triangulate ():Vector.<Vector.<int>> {
		var polygons:Vector.<Vector.<int>> = new <Vector.<int>> [];
		var i:int = 0, j:int = vertices.length - 1, done:Boolean;
		do {
			i++;
			if (i < j) {
				polygons.push (new <int> [i - 1, i, j]);
			} else {
				done = true;
			}

			j--;
			if (i < j) {
				polygons.push (new <int> [j, j + 1, i]);
			} else {
				done = true;
			}
		} while (!done);
		return polygons;
	}
}


/**
 * Holds a node in a BSP tree. A BSP tree is built from a collection of polygons
 * by picking a polygon to split along. That polygon (and all other coplanar
 * polygons) are added directly to that node and the other polygons are added to
 * the front and/or back subtrees. This is not a leafy BSP tree since there is
 * no distinction between internal and leaf nodes.
 */
class Node {
	public var plane:Plane;
	public var front:Node;
	public var back:Node;
	public var polygons:Vector.<Polygon> = new <Polygon> [];

	public function clone ():Node {
		var node:Node = new Node ();
		
		// short version of https://github.com/evanw/csg.js/commit/f76b8ef16c817fd80092955fed7bcddf4a2df5d1 fix
		var polys:Vector.<Polygon> = allPolygons ();
		for (var i:int = 0; i < polys.length; i++) {
			polys [i] = polys [i].clone ();
		}
		node.build (polys);
		
		return node;
	}

	/**
	 * Convert solid space to empty space and empty space to solid space.
	 */
	public function invert ():void {
		for (var i:int = 0; i < this.polygons.length; i++) {
			this.polygons[i].flip ();
		}
		this.plane.flip ();
		if (this.front) this.front.invert ();
		if (this.back) this.back.invert ();
		var temp:Node = this.front;
		this.front = this.back;
		this.back = temp;
	}

	/**
	 * Recursively remove all polys in polygons vector that are inside this BSP tree.
	 */
	public function clipPolygons (polygons:Vector.<Polygon>):Vector.<Polygon> {
		if (!this.plane) return polygons.slice();
		var front:Vector.<Polygon> = new <Polygon> [],
			back:Vector.<Polygon> = new <Polygon> [];
		for (var i:int = 0; i < polygons.length; i++) {
			this.plane.splitPolygon (polygons[i], front, back, front, back);
		}
		if (this.front) front = this.front.clipPolygons (front);
		if (this.back) back = this.back.clipPolygons (back);
		else {
			for (i = 0; i < back.length; i++) {
				back [i].dispose ();
			}
			back.length = 0;
		}
		return front.concat (back);
	}

	/**
	 * Remove all polygons in this BSP tree that are inside the other BSP tree.
	 */
	public function clipTo (bsp:Node):void {
		this.polygons = bsp.clipPolygons (this.polygons);
		if (this.front) this.front.clipTo (bsp);
		if (this.back) this.back.clipTo (bsp);
	}

	/**
	 * Return a list of all polygons in this BSP tree.
	 */
	public function allPolygons ():Vector.<Polygon> {
		var polygons:Vector.<Polygon> = this.polygons.slice ();
		if (this.front) polygons = polygons.concat (this.front.allPolygons ());
		if (this.back) polygons = polygons.concat (this.back.allPolygons ());
		return polygons;
	}

	/**
	 * Build a BSP tree out of polygons. When called on an existing tree, the
	 * new polygons are filtered down to the bottom of the tree and become new
	 * nodes there. Each set of polygons is partitioned using the first polygon
	 * (no heuristic is used to pick a good split).
	 */
	public function build (polygons:Vector.<Polygon>):void {
		if (!polygons.length) return;
		if (!this.plane) this.plane = polygons[0].plane.clone () as Plane;
		var front:Vector.<Polygon> = new <Polygon> [],
			back:Vector.<Polygon> = new <Polygon> [];
		for (var i:int = 0; i < polygons.length; i++) {
			this.plane.splitPolygon (polygons[i], this.polygons, this.polygons, front, back);
		}
		if (front.length) {
			if (!this.front) this.front = new Node ();
			this.front.build (front);
		}
		if (back.length) {
			if (!this.back) this.back = new Node ();
			this.back.build (back);
		}
	}
}