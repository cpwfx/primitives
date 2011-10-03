package com.ideaskill.primitives.proxy.alternativa8 {
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.resources.Geometry;
	import com.ideaskill.primitives.MeshData;

	public class Primitive extends Mesh {

		public function Primitive (data:MeshData) {
			// alternativa8 stores binormal direction in tangent.w
			var tangents3:Vector.<Number> = data.vertexTangents, n:int = tangents3.length;
			var tangents4:Vector.<Number> = new Vector.<Number> (4 * n / 3, true);
			for (var i:int = 0, j:int; i < n; ) {
				tangents4 [j++] = tangents3 [i++]; tangents4 [j++] = tangents3 [i++]; tangents4 [j++] = tangents3 [i++];
				tangents4 [j++] = 1;
			}

			geometry = new Geometry (n / 3);
			geometry.addVertexStream ([
				VertexAttributes.POSITION, VertexAttributes.POSITION, VertexAttributes.POSITION,
				VertexAttributes.TEXCOORDS[0], VertexAttributes.TEXCOORDS[0],
				VertexAttributes.NORMAL, VertexAttributes.NORMAL, VertexAttributes.NORMAL,
				VertexAttributes.TANGENT4, VertexAttributes.TANGENT4, VertexAttributes.TANGENT4, VertexAttributes.TANGENT4
			]);
			geometry.setAttributeValues (VertexAttributes.POSITION, data.vertices);
			geometry.setAttributeValues (VertexAttributes.TEXCOORDS[0], data.uvs);
			geometry.setAttributeValues (VertexAttributes.NORMAL, data.vertexNormals);
			geometry.setAttributeValues (VertexAttributes.TANGENT4, tangents4);
			geometry.indices = data.indices;

			calculateBoundBox ();
		}
	}
}