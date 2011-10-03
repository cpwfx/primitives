package com.ideaskill.primitives {
	public class MeshData {
		public var indices:Vector.<uint> = new <uint> [];
		public var uvs:Vector.<Number> = new <Number> [];
		public var vertices:Vector.<Number> = new <Number> [];
		public var vertexNormals:Vector.<Number> = new <Number> [];
		public var vertexTangents:Vector.<Number> = new <Number> [];

		// mirroring hack,
		// will be here until away fix their Mirror and minko gets mirror mesh modifier
		private var _mirrored:Boolean;
		public function get mirrored ():Boolean { return _mirrored; }
		public function set mirrored (m:Boolean):void {
			if (m != _mirrored) {

				for (var i:int = 0, n:int = vertices.length / 3; i < n; i++) {
					var i3:int = i * 3;
					vertices [i3] *= -1;
					vertexNormals [i3] *= -1;
					vertexTangents [i3] *= -1;
				}

				for (i = 0, n = indices.length / 3; i < n; i++) {
					i3 = i * 3;
					var a:int = indices [i3];
					indices [i3] = indices [i3 + 1];
					indices [i3 + 1] = a;
				}

				_mirrored = m;
			}
		}
	}
}
