package com.ideaskill.primitives {
	import flash.geom.Vector3D;
	/**
	 * Sphere with uniformly distributed vertices.
	 * 
	 * Rakhmanov, Saff and Zhou, "Minimal Discrete Energy on the Sphere",
	 * Mathematical Research Letters, Vol. 1 (1994), pp. 647-662.
	 * http://www.math.vanderbilt.edu/~esaff/texts/155.pdf
	 * 
	 * Bauer, Robert, "Distribution of Points on a Sphere with Application to Star Catalogs",
	 * Journal of Guidance, Control, and Dynamics, January-February 2000, vol.23 no.1 (130-137).
	 */
	public class UniformSphere extends MeshData {

		/**
		 * Constructor.
		 * @param	R sphere radius.
		 * @param	N number of vertices (3+); extra vertices will be added at UV seam.
		 * @param	Bauer use Bauer formula instead of Rakhmanov.
		 */
		public function UniformSphere (R:Number, N:int, Bauer:Boolean = false) {

			if (N < 3) N = 3;

			// generate directions
			for (var i:int = 1, j:int = 0; i <= N; i++) {
				var h:Number = (Bauer ? (2 * i -1) / N : 2 * (i -1) / (N -1)) -1;

				var phi:Number = Math.acos (h);
				var theta:Number = Math.sqrt (N * Math.PI) * phi;

				var r:Number = Math.sin (phi);
				vertexNormals [j++] = -r * Math.sin (theta);
				vertexNormals [j++] = -r * Math.cos (theta);
				vertexNormals [j++] = -1 * Math.cos (phi);
			}

			// scale vertices
			var len:int = N * 3;
			for (i = 0; i < len; i++) {
				vertices [i] = R * vertexNormals [i];
			}

			// create faces
			if (N == 4) {
				// patch the bug for N = 4 with Rakhmanov formula (TODO fix)
				indices.push (0, 1, 2, 0, 2, 3, 0, 3, 1, 3, 2, 1);

			} else {
				indices.push (0, 1, 2);

				var lastEdgeA:int = 0;
				var lastEdgeB:int = 2;
		
				var vA:Vector3D = new Vector3D;
				var vB:Vector3D = new Vector3D;
				var vA1:Vector3D = new Vector3D;
				var vB1:Vector3D = new Vector3D;

				while ((lastEdgeB < N - 1) || (lastEdgeA < N - 3)) {
					i = 3 * lastEdgeA;
					vA.x = vertices [i++]; vA.y = vertices [i++]; vA.z = vertices [i++];
					vA1.x = vertices [i++]; vA1.y = vertices [i++]; vA1.z = vertices [i++];
					i = 3 * lastEdgeB;
					vB.x = vertices [i++]; vB.y = vertices [i++]; vB.z = vertices [i++];
					if (lastEdgeB < N - 1) {
						vB1.x = vertices [i++]; vB1.y = vertices [i++]; vB1.z = vertices [i++];
					}

					var dotA:Number = vB.subtract (vA).dotProduct (vA1.subtract (vA));
					var dotB:Number = vB1.subtract (vB).dotProduct (vA.subtract (vB));

					var canIncA:Boolean = (lastEdgeA < lastEdgeB - 2) &&
						(lastEdgeA < N - 3) &&
						// only if B-A-A1 angle < 90° or at least B1-B-A angle
						((dotA > 0) || (dotA > dotB));

					var canIncB:Boolean = (vB1 != null) &&
						(lastEdgeB < N - 1) && 
						// only if B1-B-A angle < 90° or at least B-A-A1 angle
						((dotB > 0) || (dotB > dotA));

					if (!(canIncA || canIncB)) break;

					if (  canIncA && canIncB ) {
						// prefer shortest edge (TODO prefer convex shape)
						canIncA = (
							vB1.subtract (vA).lengthSquared > vA1.subtract (vB).lengthSquared
						);
					}

					if (canIncA) {
						// add face A-B-A1
						indices.push (lastEdgeA, lastEdgeB, lastEdgeA + 1);

						// inc A
						lastEdgeA++;
					} else {
						// add face A-B-B1
						indices.push (lastEdgeA, lastEdgeB, lastEdgeB + 1);

						// inc B
						lastEdgeB++;
					}
				}

				indices.push (N - 1, N - 2, N - 3);
			}

			// basic UVs
			uvs = new Vector.<Number> (2 * vertices.length / 3);
			for (i = 0, j = 0; i < len; ) {
				var x:Number = vertices [i++];
				var y:Number = vertices [i++];
				var z:Number = vertices [i++];
				r = 1e-5 + Math.sqrt (x * x + y * y);
				uvs [j++] = (Math.atan2 (y, -x) / Math.PI + 1) * 0.5;
				uvs [j++] = Math.atan2 (r, z) / Math.PI;
			}

			// adjust seam UVs (TODO fix the bug with extremely low N)
			len = indices.length;
			for (i = 0; i < len; ) {
				var a:int = indices [i++], a2:int = a * 2, a3:Number = a2 + a;
				var b:int = indices [i++], b2:int = b * 2, b3:Number = b2 + b;
				var c:int = indices [i++], c2:int = c * 2, c3:Number = c2 + c;

				// special case for poles (dont adjust at all, or adjust any vertex at opposite edge)
				if ((a == 0) || (a == N - 1)) {
					if (Math.abs (uvs[b2] - uvs[c2]) > 0.5) {
						adjustUAtSeam (b, i - 2, b2, c2);
					}
				} else
				if ((b == 0) || (b == N - 1)) {
					if (Math.abs (uvs[a2] - uvs[c2]) > 0.5) {
						adjustUAtSeam (a, i - 3, a2, c2);
					}
				} else
				if ((c == 0) || (c == N - 1)) {
					if (Math.abs (uvs[a2] - uvs[b2]) > 0.5) {
						adjustUAtSeam (a, i - 3, a2, b2);
					}
				} else {
					// (approximate) direction of U change
					var ux:Number = - (vertexNormals [a3 + 1] + vertexNormals [b3 + 1] + vertexNormals [c3 + 1]);
					var uy:Number = + (vertexNormals [a3] + vertexNormals [b3] + vertexNormals [c3]);

					vA.z = 0;
					vA.x = vertices [a3]; vA.y = vertices [a3 + 1]; vA.normalize ();
					var dota:Number = ux * vA.x + uy * vA.y;
					vA.x = vertices [b3]; vA.y = vertices [b3 + 1]; vA.normalize ();
					var dotb:Number = ux * vA.x + uy * vA.y;
					vA.x = vertices [c3]; vA.y = vertices [c3 + 1]; vA.normalize ();
					var dotc:Number = ux * vA.x + uy * vA.y;

					// find two edges that cross the seam
					var ab:Boolean = ((dota - dotb) * (uvs[a2] - uvs[b2]) > 0);
					var ac:Boolean = ((dota - dotc) * (uvs[a2] - uvs[c2]) > 0);
					var bc:Boolean = ((dotb - dotc) * (uvs[b2] - uvs[c2]) > 0);

					if (ab && ac) {
						adjustUAtSeam (a, i - 3, a2, b2);
					} else
					if (ab && bc) {
						adjustUAtSeam (b, i - 2, b2, c2);
					} else
					if (ac && bc) {
						adjustUAtSeam (c, i - 1, c2, a2);
					}
				}
			}

			// pole UVs
			for (i = 0; i < len; ) {
				a = indices [i++];
				b = indices [i++];
				c = indices [i++];

				if (a == 0) {
					calculatePoleUVs (0, i - 3, a, b, c);
				} else
				if (b == 0) {
					calculatePoleUVs (0, i - 2, b, a, c);
				} else
				if (c == 0) {
					calculatePoleUVs (0, i - 1, c, a, b);
				}

				if (a == N - 1) {
					calculatePoleUVs (1, i - 3, a, b, c);
				} else
				if (b == N - 1) {
					calculatePoleUVs (1, i - 2, b, a, c);
				} else
				if (c == N - 1) {
					calculatePoleUVs (1, i - 1, c, a, b);
				}
			}

			// finally, tangents
			len = vertices.length / 3;
			for (a = 0; a < len; a++) {
				a2 = a * 2; a3 = a2 + a;
				var longitude:Number = 2 * Math.PI * uvs [a2];
				vertexTangents [a3] =     -Math.sin (longitude);
				vertexTangents [a3 + 1] = -Math.cos (longitude);
				vertexTangents [a3 + 2] = 0;
			}
		}

		private function adjustUAtSeam (a:int, ia:int, a2:int, b2:int):void {
			a = indices [ia] = cloneVertexAndNormal (a);
			uvs [a * 2] = uvs [a2] + ((uvs [a2] > uvs [b2]) ? -1 : +1);
			uvs [a * 2 + 1] = uvs [a2 + 1];
		}

		private var originalPolesUsed:Vector.<Boolean> = new <Boolean> [false, false];
		private function calculatePoleUVs (pole:int, i:int, a:int, b:int, c:int):void {
			if (originalPolesUsed [pole]) {
				a = cloneVertexAndNormal (a); indices [i] = a;
			} else {
				originalPolesUsed [pole] = true;
			}
			uvs [2 * a] = 0.5 * (uvs [2 * b] + uvs [2 * c]);
			uvs [2 * a + 1] = pole;
		}

		private function cloneVertexAndNormal (i:int):int {
			var i3:int = i * 3, j:int = vertices.length / 3;
			vertices.push (vertices [i3], vertices [i3 + 1], vertices [i3 + 2]);
			vertexNormals.push (vertexNormals [i3], vertexNormals [i3 + 1], vertexNormals [i3 + 2]);
			return j;
		}
	}
}