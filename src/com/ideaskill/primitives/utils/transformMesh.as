package com.ideaskill.primitives.utils {
	import com.ideaskill.primitives.MeshData;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	/** Applies transformations to a mesh. */
	public function transformMesh (mesh:MeshData, matrix3D:Matrix3D, matrix2D:Matrix = null):void {
		var w:Vector.<Number> = mesh.vertices.concat ();
		matrix3D.transformVectors (mesh.vertices, w); mesh.vertices = w;

		var rotozoom:Matrix3D = matrix3D.clone ();
		rotozoom.position = new Vector3D;

		w = mesh.vertexNormals.concat ();
		rotozoom.transformVectors (mesh.vertexNormals, w); mesh.vertexNormals = w;

		w = mesh.vertexTangents.concat ();
		rotozoom.transformVectors (mesh.vertexTangents, w); mesh.vertexTangents = w;

		if (matrix2D) {
			for (var i:int = 0; i < mesh.uvs.length; i += 2) {
				var u:Number = mesh.uvs [i], v:Number = mesh.uvs [i + 1];
				mesh.uvs [i]     = u * matrix2D.a + v * matrix2D.b + matrix2D.tx;
				mesh.uvs [i + 1] = u * matrix2D.c + v * matrix2D.d + matrix2D.ty;
			}
		}
	}
}