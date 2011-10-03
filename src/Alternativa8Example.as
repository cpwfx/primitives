package {
	import alternativa.engine3d.core.*;
	import alternativa.engine3d.lights.*;
	import alternativa.engine3d.materials.*;
	import alternativa.engine3d.objects.*;
	import alternativa.engine3d.resources.*;
	import com.ideaskill.primitives.Globe;
	import com.ideaskill.primitives.UniformSphere;
	import com.ideaskill.primitives.proxy.alternativa8.Primitive;
	import flash.display.*;
	import flash.events.*;

	public class Alternativa8Example extends Sprite {

		public var camera:Camera3D;
		public var stage3D:Stage3D;

		public function Alternativa8Example () {
			addEventListener (Event.ADDED_TO_STAGE, onAddedToStage);			
		}

		public function onAddedToStage (e:Event):void {
			removeEventListener (Event.ADDED_TO_STAGE, onAddedToStage);

			stage3D = stage.stage3Ds [0];
			stage3D.addEventListener (Event.CONTEXT3D_CREATE, onContextCreate);
			stage3D.requestContext3D ();
		}

		public function onContextCreate (e:Event):void {
			stage3D.removeEventListener (Event.CONTEXT3D_CREATE, onContextCreate);

			camera = new Camera3D (1, 1000);
			camera.view = new View (stage.stageWidth, stage.stageHeight);
			Object3D (new Object3D).addChild (camera);
			addChild (camera.view);

			var light:OmniLight = new OmniLight (0xFFFFFF, 0, 3000);
			light.x = -900; light.y = -900; camera.addChild (light);
			light = new OmniLight (0x7F7F00, 0, 1000);
			light.x = +100; light.y = +100; camera.addChild (light);

			[Embed(source = 'checkerboard.jpg')] var Checkerboard:Class;
			var texture:BitmapTextureResource = new BitmapTextureResource (Bitmap (new Checkerboard).bitmapData);
			var normals:BitmapTextureResource = new BitmapTextureResource (new BitmapData (1, 1, false, 0x7F7FFF));

			// creating the primitive using engine-specific proxy
			var primitive:Primitive = new Primitive (new Globe (50, 10));
			//var primitive:Primitive = new Primitive (new UniformSphere (50, 50));

			primitive.addSurface (new StandardMaterial (texture, normals), 0, primitive.geometry.numTriangles);
			camera.parent.addChild (primitive);

			var wires:WireFrame = WireFrame.createEdges (primitive, 0xFF00);
			wires.scaleX = wires.scaleY = wires.scaleZ = 1.005;
			primitive.addChild (wires);

			var resources:Vector.<Resource> = camera.parent.getResources (true);
			for each (var resource:Resource in resources) resource.upload (stage3D.context3D);

			addEventListener (Event.ENTER_FRAME, onEnterFrame);
		}

		public function onEnterFrame (e:Event):void {
			camera.rotationX = -Math.PI * mouseY / stage.stageHeight;
			camera.y = +200 * Math.sin (camera.rotationX);
			camera.z = -200 * Math.cos (camera.rotationX);
			camera.parent.getChildAt (1).rotationZ = 2 * Math.PI * mouseX / stage.stageWidth;
			camera.render (stage3D);
		}
	}
}