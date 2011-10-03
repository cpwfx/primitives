package {
	import away3d.containers.*;
	import away3d.lights.*;
	import away3d.materials.*;
	import com.ideaskill.primitives.proxy.away4.Primitive;
	import com.ideaskill.primitives.UniformSphere;
	import flash.display.*;
	import flash.events.*;

	public class Away4Example extends Sprite {

		public var view:View3D;
		public var camera:ObjectContainer3D;
		public var container:ObjectContainer3D;

		public function Away4Example () {
			addEventListener (Event.ADDED_TO_STAGE, onAddedToStage);			
		}

		public function onAddedToStage (e:Event):void {
			removeEventListener (Event.ADDED_TO_STAGE, onAddedToStage);

			view = new View3D; view.width = stage.stageWidth; view.height = stage.stageHeight;
			addChild (view);
			container = new ObjectContainer3D;
			view.scene.addChild (container);

			camera = new ObjectContainer3D;
			view.scene.addChild (camera);
			camera.addChild (view.camera); view.camera.z = 0;

			var light1:PointLight = new PointLight; light1.color = 0xFFFFFF;
			light1.x = -900; light1.y = +900; camera.addChild (light1);
			var light2:PointLight = new PointLight; light2.color = 0x7F7F00;
			light2.x = +100; light2.y = -100; camera.addChild (light2);

			[Embed(source = 'checkerboard.jpg')] var Checkerboard:Class;
			var texture:BitmapMaterial = new BitmapMaterial (Bitmap (new Checkerboard).bitmapData, true, true);

			texture.lights = [light1, light2];

			// creating the primitive using engine-specific proxy
			var primitive:Primitive = new Primitive (new UniformSphere (50, 50));

			primitive.material = texture;
			container.addChild (primitive);

			addEventListener (Event.ENTER_FRAME, onEnterFrame);
		}

		public function onEnterFrame (e:Event):void {
			camera.rotationX = 180 * mouseY / stage.stageHeight;
			camera.y = +200 * Math.sin (Math.PI * camera.rotationX / 180);
			camera.z = -200 * Math.cos (Math.PI * camera.rotationX / 180);
			container.rotationZ = -360 * mouseX / stage.stageWidth;
			view.render ();
		}
	}
}