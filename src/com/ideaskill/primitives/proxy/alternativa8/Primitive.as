package com.ideaskill.primitives.proxy.alternativa8 {
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.resources.Geometry;
	import com.ideaskill.primitives.MeshData;

	public class Primitive extends Mesh {

		public function Primitive (data:MeshData) {
			// mirror data for alternativa8
			var indices:Vector.<uint> = data.indices.slice ();
			var vertices:Vector.<Number> = data.vertices.slice ();
			var vertexNormals:Vector.<Number> = data.vertexNormals.slice ();

			for (var i:int = 0, n:int = vertices.length / 3; i < n; i++) {
				var i3:int = i * 3;
				vertices [i3] *= -1;
				vertexNormals [i3] *= -1;
			}

			for (i = 0, n = indices.length / 3; i < n; i++) {
				i3 = i * 3;
				var a:int = indices [i3];
				indices [i3] = indices [i3 + 1];
				indices [i3 + 1] = a;
			}

			// also, alternativa8 stores binormal direction in tangent.w
			var tangents3:Vector.<Number> = data.vertexTangents, j:int; n = tangents3.length
			var tangents4:Vector.<Number> = new Vector.<Number> (4 * n / 3, true);
			for (i = 0, j = 0; i < n; ) {
				tangents4 [j++] = -tangents3 [i++]; tangents4 [j++] = tangents3 [i++]; tangents4 [j++] = tangents3 [i++];
				tangents4 [j++] = 1;
			}

			geometry = new Geometry (n / 3);
			geometry.addVertexStream ([
				VertexAttributes.POSITION, VertexAttributes.POSITION, VertexAttributes.POSITION,
				VertexAttributes.TEXCOORDS[0], VertexAttributes.TEXCOORDS[0],
				VertexAttributes.NORMAL, VertexAttributes.NORMAL, VertexAttributes.NORMAL,
				VertexAttributes.TANGENT4, VertexAttributes.TANGENT4, VertexAttributes.TANGENT4, VertexAttributes.TANGENT4
			]);
			geometry.setAttributeValues (VertexAttributes.POSITION, vertices);
			geometry.setAttributeValues (VertexAttributes.TEXCOORDS[0], data.uvs);
			geometry.setAttributeValues (VertexAttributes.NORMAL, vertexNormals);
			geometry.setAttributeValues (VertexAttributes.TANGENT4, tangents4);
			geometry.indices = indices;

			calculateBoundBox ();
		}
	}
}