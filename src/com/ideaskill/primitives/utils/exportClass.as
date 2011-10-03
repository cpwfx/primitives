package com.ideaskill.primitives.utils {
	import com.ideaskill.primitives.MeshData;

	/** Exports mesh data as standalone class. */
	public function exportClass (mesh:MeshData):String {
		return (
			"package {\n" +
			"\tpublic class Data {\n" +
			"\t\tpublic var indices:Vector.<uint> = new <uint> [" + mesh.indices + "];\n" +
			"\t\tpublic var uvs:Vector.<Number> = new <Number> [" + mesh.uvs + "];\n" +
			"\t\tpublic var vertices:Vector.<Number> = new <Number> [" + mesh.vertices + "];\n" +
			"\t\tpublic var vertexNormals:Vector.<Number> = new <Number> [" + mesh.vertexNormals + "];\n" +
			"\t\tpublic var vertexTangents:Vector.<Number> = new <Number> [" + mesh.vertexTangents + "];\n" +
			"\t}\n" +
			"}"
		);
	}
}