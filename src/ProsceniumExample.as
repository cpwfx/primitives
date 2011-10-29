package {
	import com.adobe.display.*;
	import com.adobe.scenegraph.*;
	import com.ideaskill.primitives.proxy.proscenium.Primitive;
	import com.ideaskill.primitives.UniformSphere;
	
	import flash.display.*;
	import flash.display3D.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;

	public class ProsceniumExample extends Sprite {

		public var instance:Instance3D;
		public var camera:SceneCamera;
		public var stage3D:Stage3D;

		public function ProsceniumExample () {
			addEventListener (Event.ADDED_TO_STAGE, onAddedToStage);			
		}

		public function onAddedToStage (e:Event):void {
			removeEventListener (Event.ADDED_TO_STAGE, onAddedToStage);

			stage3D = stage.stage3Ds [0];
			stage3D.addEventListener (Event.CONTEXT3D_CREATE, onContextCreate);
			stage3D.requestContext3D (Context3DRenderMode.AUTO);
		}

		public function onContextCreate (e:Event):void {
			stage3D.removeEventListener (Event.CONTEXT3D_CREATE, onContextCreate);

			instance = new Instance3D (stage3D.context3D);
			instance.configureBackBuffer (stage.stageWidth, stage.stageHeight, 2, true);

			camera = instance.scene.activeCamera;
			camera.aspect = stage.stageWidth / stage.stageHeight;

			var light:SceneLight = new SceneLight ();
			light.color = Color.fromUint (0xFFFFFF);
			light.kind = SceneLight.KIND_POINT;
			light.setPosition (0, +900, +900);
			camera.addChild (light);

			light = new SceneLight ();
			light.color = Color.fromUint (0x7F7F00);
			light.kind = SceneLight.KIND_POINT;
			light.setPosition (0, -100, -100);
			camera.addChild (light);

			[Embed(source = 'checkerboard.jpg')] var Checkerboard:Class;
			var texture:TextureMap = new TextureMap (Bitmap (new Checkerboard).bitmapData);
			
			var material:MaterialStandard = new MaterialStandard ();
			material.diffuseMap = texture;

			// creating the primitive using engine-specific proxy
			var primitive:SceneMesh = new Primitive (new UniformSphere (50, 50));

			primitive.applyMaterial (material);
			instance.scene.addChild (primitive);

			addEventListener (Event.ENTER_FRAME, onEnterFrame);
		}

		public function onEnterFrame (e:Event):void {
			var camRotX:Number = Math.PI * (1 - mouseY / stage.stageHeight);
			camera.identity ();
			camera.appendRotation (180 * (1 + camRotX / Math.PI), Vector3D.X_AXIS);
			camera.setPosition (0, 200 * Math.sin (camRotX), -200 * Math.cos (camRotX));
			with (camera.parent.getChildByIndex (1)) {
				identity ();
				appendRotation (-360 * mouseX / stage.stageWidth, Vector3D.Z_AXIS);
			}
			instance.render ();
		}
	}
}