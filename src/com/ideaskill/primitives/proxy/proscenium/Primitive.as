package com.ideaskill.primitives.proxy.proscenium {
	import com.adobe.scenegraph.MeshElement;
	import com.adobe.scenegraph.SceneMesh;
	import com.adobe.scenegraph.VertexFormat;
	import com.adobe.scenegraph.VertexFormatElement;
	import com.ideaskill.primitives.MeshData;
	import flash.display3D.Context3DVertexBufferFormat;

	public class Primitive extends SceneMesh {

		public function Primitive (data:MeshData) {
			super ();

			// proscenium requires vertex data to be interleaved
			var i:int = 0, j:int = 0, vertexData:Vector.<Number> = new <Number> [];
			while (i < data.uvs.length) {
				vertexData.push (
					data.uvs [i], data.uvs [i + 1],
					data.vertexNormals [j], data.vertexNormals [j + 1], data.vertexNormals [j + 2],
					data.vertexTangents [j], data.vertexTangents [j + 1], data.vertexTangents [j + 2],
					data.vertices [j], data.vertices [j + 1], data.vertices [j + 2]
				);
				i += 2;
				j += 3;
			}

			addElement (
				new MeshElement (
					new <Vector.<Number>> [vertexData],
					new <Vector.<uint>> [data.indices],
					new VertexFormat (
						new <VertexFormatElement> [
							new VertexFormatElement (
								VertexFormatElement.SEMANTIC_TEXCOORD,
								0, Context3DVertexBufferFormat.FLOAT_2,
								0, "texcoord"
							),
							new VertexFormatElement (
								VertexFormatElement.SEMANTIC_NORMAL,
								2, Context3DVertexBufferFormat.FLOAT_3,
								0, "normal"
							),
							new VertexFormatElement (
								VertexFormatElement.SEMANTIC_TANGENT,
								5, Context3DVertexBufferFormat.FLOAT_3,
								0, "tangent"
							),
							new VertexFormatElement (
								VertexFormatElement.SEMANTIC_POSITION,
								8, Context3DVertexBufferFormat.FLOAT_3,
								0, "position"
							)
						]
					)
				)
			);
		}
	}
}