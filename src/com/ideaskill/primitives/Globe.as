package com.ideaskill.primitives {
	/**
	 * Sphere mesh minimizing texture distortions for equirectangular map.
	 * Ported from earlier version of as3globe's GlobeMesh class.
	 * @see https://github.com/makc/as3globe
	 */
	public class Globe extends MeshData {

		/**
		 * Constructor.
		 * @param	R sphere radius.
		 * @param	N The number of triangles along globe equator (4+).
		 */
		public function Globe (R:Number, N:int) {
			verticesMap = [];

			// a number of rows in one hemisphere
			while (N < 2 * Math.sqrt (3)) N++;
			var m:Number = N / (2 * Math.sqrt (3));
			var M:int = int(m) + 1;

			// compute vertical compression coefficient k:
			// 1 + k + k^2 + ... + k^int(m) = m
			var k:Number, sum:Number, ka:Number = 0.1, kb:Number = 1.1;
			while (kb - ka > 1e-6) {
				k = 0.3 * ka + 0.7 * kb;
				sum = 1; for (var p:int = 1; p < M; p++) sum += Math.pow (k, p);
				if (sum > m) kb = k; else ka = k;				
			}

			// create mesh
			var lat_base:Number = 0;
			var lat_step:Number = 180 * Math.sqrt (3) / N;

			var latA:Number, lonA:Number;
			var latB:Number, lonB:Number;
			var latC:Number, lonC:Number;
			var latD:Number, lonD:Number;
			var latE:Number, lonE:Number;
			var latF:Number, lonF:Number;
			var latG:Number, lonG:Number;
			var latH:Number, lonH:Number;


			for (var i:int = 0; i < M; i++) {

				var dj:Number = (i % 2) * 0.5;

				for (var j:int = 0; j < N; j++) {

					// create vertices
					latA = lat_base;
					lonA = 360 * (j + dj) / N - 180;

					latB = (i < M - 1) ? (lat_base + lat_step) : 90;
					lonB = 360 * (j + dj + 0.5) / N - 180;

					latC = (i < M - 1) ? (lat_base + lat_step) : 90;
					lonC = 360 * (j + dj + 1.5) / N - 180;

					latD = lat_base;
					lonD = 360 * (j + dj + 1) / N - 180;

					latE = -lat_base;
					lonE = 360 * (j + dj) / N - 180;

					latF = (i < M - 1) ? -(lat_base + lat_step) : -90;
					lonF = 360 * (j + dj + 0.5) / N - 180;

					latG = (i < M - 1) ? -(lat_base + lat_step) : -90;
					lonG = 360 * (j + dj + 1.5) / N - 180;

					latH = -lat_base;
					lonH = 360 * (j + dj + 1) / N - 180;

					var vA:uint = getVertex (latA, lonA, R);
					var vB:uint = getVertex (latB, lonB, R);
					var vD:uint = getVertex (latD, lonD, R);
					var vE:uint = getVertex (latE, lonE, R);
					var vF:uint = getVertex (latF, lonF, R);
					var vH:uint = getVertex (latH, lonH, R);

					// create /\ faces
					indices.push (vB, vA, vD);
					indices.push (vE, vF, vH);

					// create \/ faces (uses C and G vertices)
					if (i < M - 1) {
						var vC:uint = getVertex (latC, lonC, R);
						var vG:uint = getVertex (latG, lonG, R);
						indices.push (vB, vD, vC);
						indices.push (vH, vF, vG);
					}
				}

				lat_base += lat_step;
				lat_step *= k;
			}

			verticesMap = null;

			// finally, normals and tangents
			var len:uint = vertices.length / 3;
			for (var a:uint = 0; a < len; a++) {
				var a3:uint = a * 3;

				var nx:Number = vertices [a3];
				var ny:Number = vertices [a3 + 1];
				var nz:Number = vertices [a3 + 2];
				var nn:Number = Math.sqrt (nx * nx + ny * ny + nz * nz);
				if (nn > 0) {
					nx /= nn; ny /= nn; nz /= nn;
				} else {
					nx = 1; // should not happen for R != 0
				}
				vertexNormals [a3] = nx;
				vertexNormals [a3 + 1] = ny;
				vertexNormals [a3 + 2] = nz;

				var longitude:Number = 2 * Math.PI * uvs [a * 2];
				vertexTangents [a3] =     -Math.sin (longitude);
				vertexTangents [a3 + 1] = -Math.cos (longitude);
				vertexTangents [a3 + 2] = 0;
			}
		}

		private var verticesMap:Array;

		private function getVertex (lat:Number, lon:Number, rad:Number):uint {
			// colatitude
			var phi:Number = +(90 - lat) * 0.01745329252;
			// azimuthal angle
			var the:Number = +(180 - lon) * 0.01745329252;
			// translate into XYZ coordinates
			var wx:Number = rad * Math.sin (the) * Math.sin (phi) * -1;
			var wy:Number = rad * Math.cos (the) * Math.sin (phi);
			var wz:Number = rad * Math.cos (phi) * -1;
			// equirectangular projection
			var wu:Number = 0.25 + lon / 360.0;
			var wv:Number = 0.5 + lat / 180.0;

			// location hash
			var cos:Number = 1 - lat * lat / 8100;
			var hash:uint = (lon * cos + 36 * (lat + 90)) / 10;

			// find existing vertex
			var vmap:Array = verticesMap [hash];
			if (vmap) {
				for each (var v:uint in vmap) {
					var v2:uint = v + v;
					var v3:uint = v + v2;
					var dx:Number = vertices [v3] - wx;
					var dy:Number = vertices [v3 + 1] - wy;
					var dz:Number = vertices [v3 + 2] - wz;
					var du:Number = uvs [v2] - wu;
					var dv:Number = uvs [v2 + 1] - wv;
					if (dx * dx + dy * dy + dz * dz + du * du + dv * dv < 1e-9) {
						return v;
					}
				}
			} else {
				verticesMap [hash] = vmap = [];
			}

			// none found
			var w:uint = uvs.length / 2;
			vertices.push (wx, wy, wz);
			uvs.push (wu, wv);
			vmap.push (w);
			return w;
		}
	}
}