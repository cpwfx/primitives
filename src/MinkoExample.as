package {
	import aerys.minko.render.effect.lighting.*;
	import aerys.minko.render.*;
	import aerys.minko.scene.node.camera.*;
	import aerys.minko.scene.node.group.*;
	import aerys.minko.scene.node.light.*;
	import aerys.minko.type.math.*;
	import com.ideaskill.primitives.proxy.minko.Primitive;
	import com.ideaskill.primitives.UniformSphere;
	import flash.display.*;
	import flash.events.*;

	public class MinkoExample extends Sprite {

		public var view:Viewport;
		public var camera:TransformGroup;
		public var container:TransformGroup;
		public var scene:Group;

		public function MinkoExample () {
			addEventListener (Event.ADDED_TO_STAGE, onAddedToStage);			
		}

		public function onAddedToStage (e:Event):void {
			removeEventListener (Event.ADDED_TO_STAGE, onAddedToStage);

			view = new Viewport (8, stage.stageWidth, stage.stageHeight);
			view.defaultEffect = new LightingEffect;
			addChild (view);
			container = new TransformGroup;

			var cam:Camera = new Camera;

			var light1:PointLight = new PointLight (0xFFFFFF);
			light1.position.x = -900; light1.position.y = +900;
			var light2:PointLight = new PointLight (0x7F7F00);
			light2.position.x = +100; light2.position.y = -100;

			camera = new TransformGroup (cam, light1, light2);
			scene = new Group (camera, container);

			[Embed(source = 'checkerboard.jpg')] var Checkerboard:Class;

			// creating the primitive using engine-specific proxy
			var primitive:Primitive = new Primitive (new UniformSphere (50, 50));

			primitive.style.set (LightingStyle.LIGHTS_ENABLED, true);
			container.addChild (LoaderGroup.loadClass (Checkerboard) [0]).addChild (primitive);

			addEventListener (Event.ENTER_FRAME, onEnterFrame);
		}

		public function onEnterFrame (e:Event):void {
			var camRotX:Number = Math.PI * mouseY / stage.stageHeight;
			camera.transform.identity ().
				appendRotation (camRotX, ConstVector4.X_AXIS).
				setTranslation (0, +200 * Math.sin (camRotX), -200 * Math.cos (camRotX));
			container.transform.identity ().
				appendRotation ( -2 * Math.PI * mouseX / stage.stageWidth, ConstVector4.Z_AXIS);
			view.render (scene);
		}
	}
}