package com.ideaskill.primitives.proxy.away4 {
	import away3d.core.base.Geometry;
	import away3d.core.base.SubGeometry;
	import away3d.entities.Mesh;
	import com.ideaskill.primitives.MeshData;

	public class Primitive extends Mesh {

		public function Primitive (data:MeshData) {
			var g:Geometry = new Geometry;
			var s:SubGeometry = new SubGeometry;
			g.addSubGeometry (s);
			s.updateVertexData (data.vertices);
			s.updateVertexNormalData (data.vertexNormals);
			s.updateVertexTangentData (data.vertexTangents);
			s.updateIndexData (data.indices);
			s.updateUVData (data.uvs);
			super (null, g);
		}
	}
}