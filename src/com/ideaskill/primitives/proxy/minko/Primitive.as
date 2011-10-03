package com.ideaskill.primitives.proxy.minko {
	import aerys.minko.render.effect.basic.BasicStyle;
	import aerys.minko.scene.node.group.StyleGroup;
	import aerys.minko.scene.node.mesh.Mesh;
	import aerys.minko.type.enum.TriangleCulling;
	import aerys.minko.type.stream.format.VertexComponent;
	import aerys.minko.type.stream.format.VertexFormat;
	import aerys.minko.type.stream.IndexStream;
	import aerys.minko.type.stream.VertexStream;
	import aerys.minko.type.stream.VertexStreamList;
	import com.ideaskill.primitives.MeshData;

	public class Primitive extends StyleGroup {

		public function Primitive (data:MeshData) {

			// data needs to be mirrored for away
			data.mirrored = true;

			// however, minko also expects indices in different order
			style.set (BasicStyle.TRIANGLE_CULLING, TriangleCulling.FRONT);
			style.set (BasicStyle.NORMAL_MULTIPLIER, 1);

			var indices:IndexStream = new IndexStream (data.indices);
			var uvs:VertexStream = new VertexStream (data.uvs, new VertexFormat (VertexComponent.UV));
			var vertices:VertexStream = new VertexStream (data.vertices, VertexFormat.XYZ);
			var vertexNormals:VertexStream = new VertexStream (data.vertexNormals, new VertexFormat (VertexComponent.NORMAL));
			var vertexTangents:VertexStream = new VertexStream (data.vertexTangents, new VertexFormat (VertexComponent.TANGENT));

			addChild (new Mesh (new VertexStreamList (uvs, vertices, vertexNormals, vertexTangents), indices));
		}
	}
}