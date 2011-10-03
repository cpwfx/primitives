package com.ideaskill.primitives.utils {
	import com.ideaskill.primitives.MeshData;

	/**
	 * Exports mesh data in 3D Studio Max ASCII Export format.
	 * @see http://www.solosnake.com/main/ase.htm
	 */
	public function exportASE (mesh:MeshData):String {
		var name:String = getShortClassName (mesh);

		var ase:String =
			"*3DSMAX_ASCIIEXPORT 200\n" +
			"*COMMENT \"com.ideaskill.primitives\"\n" +
			"*GEOMOBJECT {\n" +
			"\t*NODE_NAME \"" + name + "\"\n" +
			"\t*NODE_TM {\n" +
			"\t\t*NODE_NAME \"" + name + "\"\n" +
			"\t\t*INHERIT_POS 0 0 0\n" +
			"\t\t*INHERIT_ROT 0 0 0\n" +
			"\t\t*INHERIT_SCL 0 0 0\n" +
			"\t\t*TM_ROW0 1.0000 0.0000 0.0000\n" +
			"\t\t*TM_ROW1 0.0000 1.0000 0.0000\n" +
			"\t\t*TM_ROW2 0.0000 0.0000 1.0000\n" +
			"\t\t*TM_ROW3 0.0000 0.0000 0.0000\n" +
			"\t\t*TM_POS 0.0000 0.0000 0.0000\n" +
			"\t\t*TM_ROTAXIS 0.0000 0.0000 0.0000\n" +
			"\t\t*TM_ROTANGLE 0.0000\n" +
			"\t\t*TM_SCALE 1.0000 1.0000 1.0000\n" +
			"\t\t*TM_SCALEAXIS 0.0000 0.0000 0.0000\n" +
			"\t\t*TM_SCALEAXISANG 0.0000\n" +
			"\t}\n" +
			"\t*MESH {\n" +
			"\t\t*TIMEVALUE 0\n" +
			"\t\t*MESH_NUMVERTEX " + (mesh.vertices.length / 3) + "\n" +
			"\t\t*MESH_NUMFACES " + (mesh.indices.length / 3) + "\n" +
			"\t\t*MESH_VERTEX_LIST {\n";

		var i:int;
		for (i = 0; i < mesh.vertices.length; ) {
			ase += "\t\t\t*MESH_VERTEX " + (i / 3) + " " +
				formatNumber (mesh.vertices [i++]) + " " +
				formatNumber (mesh.vertices [i++]) + " " +
				formatNumber (mesh.vertices [i++]) + "\n";
		}

		ase +=
			"\t\t}\n" +
			"\t\t*MESH_FACE_LIST {\n";

		for (i = 0; i < mesh.indices.length; ) {
			ase += "\t\t\t*MESH_FACE " + (i / 3) + ": A: " +
				mesh.indices [i++] + " B: " +
				mesh.indices [i++] + " C: " +
				mesh.indices [i++] + " AB: 1 BC: 1 CA: 1 *MESH_SMOOTHING 1 *MESH_MTLID 0\n";
		}

		ase +=
			"\t\t}\n" +
			"\t\t*MESH_NUMTVERTEX " + (mesh.uvs.length / 2) + "\n" +
			"\t\t*MESH_TVERTLIST {\n";

		for (i = 0; i < mesh.uvs.length; ) {
			ase += "\t\t\t*MESH_TVERT " + (i / 2) + " " +
				formatNumber (mesh.uvs [i++]) + " " +
				formatNumber (mesh.uvs [i++]) + " 0.0\n";
		}

		ase +=
			"\t\t}\n" +
			"\t\t*MESH_NUMTVFACES " + (mesh.indices.length / 3) + "\n" +
			"\t\t*MESH_TFACELIST {\n";

		for (i = 0; i < mesh.indices.length; ) {
			ase += "\t\t\t*MESH_TFACE " + (i / 3) + " " +
				mesh.indices [i++] + " " +
				mesh.indices [i++] + " " +
				mesh.indices [i++] + "\n";
		}

		ase +=
			"\t\t}\n" +
			"\t}\n" +
			"\}\n";

		return ase;
	}
}

import flash.utils.getQualifiedClassName;
function getShortClassName (value:*):String {
	var name:String = getQualifiedClassName (value);
	return name.substr (name.lastIndexOf (":") + 1);
}

function formatNumber (n:Number):String {
	var e:String = n.toExponential (6);
	var f:String = n.toFixed (6);
	if (e.length < f.length) {
		return e;
	}
	return f;
}