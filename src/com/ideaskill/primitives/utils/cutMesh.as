package com.ideaskill.primitives.utils {
	import com.ideaskill.primitives.MeshData;
	import flash.geom.Vector3D;
	
	/**
	 * Cuts mesh parts behind the plane. Does not remove orphan vertices.
	 */
	public function cutMesh (mesh:MeshData, point:Vector3D, normal:Vector3D, e:Number = 1e-5):MeshData {
		var front:MeshData = new MeshData ();
		
		front.vertices = mesh.vertices.slice ();
		front.vertexNormals = mesh.vertexNormals.slice ();
		front.vertexTangents = mesh.vertexTangents.slice ();
		front.uvs = mesh.uvs.slice ();
		
		var vN:Vector3D, vT:Vector3D;
		for (var p:int = 0, q:int = mesh.indices.length; p < q;	) {
			var i:int = mesh.indices[p++], i3:int = i * 3;
			var j:int = mesh.indices[p++], j3:int = j * 3;
			var k:int = mesh.indices[p++], k3:int = k * 3;
			var vi:Vector3D = new Vector3D (mesh.vertices[i3], mesh.vertices[i3 + 1], mesh.vertices[i3 + 2]);
			var vj:Vector3D = new Vector3D (mesh.vertices[j3], mesh.vertices[j3 + 1], mesh.vertices[j3 + 2]);
			var vk:Vector3D = new Vector3D (mesh.vertices[k3], mesh.vertices[k3 + 1], mesh.vertices[k3 + 2]);
			var idot:Number = point.subtract (vi).dotProduct (normal);
			var jdot:Number = point.subtract (vj).dotProduct (normal);
			var kdot:Number = point.subtract (vk).dotProduct (normal);
			if ((idot >= -e) && (jdot >= -e) && (kdot >= -e)) {
				// whole triangle behind - skip it
			} else if ((idot <= e) && (jdot <= e) && (kdot <= e)) {
				// whole triangle infront - copy it
				front.indices.push (i, j, k);
			} else {
				// cut sides
				var tij:Number = idot / vj.subtract (vi).dotProduct (normal), ij:int;
				var tjk:Number = jdot / vk.subtract (vj).dotProduct (normal), jk:int;
				var tki:Number = kdot / vi.subtract (vk).dotProduct (normal), ki:int;
				// one of sides must still remain uncut
				if ((1 - e <= tij) || (tij <= e)) {
					jk = interpolateVertexInMesh (front, j, k, tjk);
					ki = interpolateVertexInMesh (front, k, i, tki);
					if (kdot < e) {
						front.indices.push (jk, k, ki);
					} else {
						front.indices.push (j, jk, ki, j, ki, i);
					}
				} else if ((1 - e <= tjk) || (tjk <= e)) {
					ij = interpolateVertexInMesh (front, i, j, tij);
					ki = interpolateVertexInMesh (front, k, i, tki);
					if (idot < e) {
						front.indices.push (ki, i, ij);
					} else {
						front.indices.push (k, ki, ij, k, ij, j);
					}
				} else {
					ij = interpolateVertexInMesh (front, i, j, tij);
					jk = interpolateVertexInMesh (front, j, k, tjk);
					if (jdot < e) {
						front.indices.push (ij, j, jk);
					} else {
						front.indices.push (i, ij, jk, i, jk, k);
					}
				}
			}
		}
		return front;
	}
}


import com.ideaskill.primitives.MeshData;

/**
 * Lerp-based.
 */
function interpolateVertexInMesh (m:MeshData, i:int, j:int, t:Number):int {
	var i3:int = i * 3, j3:int = j * 3, t1:Number = 1 - t;
	m.vertices.push (m.vertices[i3] * t1 + m.vertices[j3] * t);
	m.vertices.push (m.vertices[i3 + 1] * t1 + m.vertices[j3 + 1] * t);
	m.vertices.push (m.vertices[i3 + 2] * t1 + m.vertices[j3 + 2] * t);
	var nx:Number = m.vertexNormals[i3] * t1 + m.vertexNormals[j3] * t;
	var ny:Number = m.vertexNormals[i3 + 1] * t1 + m.vertexNormals[j3 + 1] * t;
	var nz:Number = m.vertexNormals[i3 + 2] * t1 + m.vertexNormals[j3 + 2] * t;
	var nn:Number = Math.sqrt (nx * nx + ny * ny + nz * nz);
	m.vertexNormals.push (nx / nn, ny / nn, nz / nn);
	var tx:Number = m.vertexTangents[i3] * t1 + m.vertexTangents[j3] * t;
	var ty:Number = m.vertexTangents[i3 + 1] * t1 + m.vertexTangents[j3 + 1] * t;
	var tz:Number = m.vertexTangents[i3 + 2] * t1 + m.vertexTangents[j3 + 2] * t;
	var tn:Number = Math.sqrt (tx * tx + ty * ty + tz * tz);
	m.vertexTangents.push (tx / tn, ty / tn, tz / tn);
	var n:int = m.uvs.length / 2;
	var i2:int = i * 2, j2:int = j * 2;
	m.uvs.push (m.uvs[i2] * t1 + m.uvs[j2] * t);
	m.uvs.push (m.uvs[i2 + 1] * t1 + m.uvs[j2 + 1] * t);
	return n;
}