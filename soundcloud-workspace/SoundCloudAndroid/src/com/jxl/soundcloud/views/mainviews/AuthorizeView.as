package com.jxl.soundcloud.views.mainviews
{
    import assets.Styles;
    import assets.flash.LoaderAnimation;
    
    import com.bit101.components.Component;
    import com.bit101.components.Label;
    import com.jxl.soundcloud.Constants;
    import com.jxl.soundcloud.components.InputText;
    import com.jxl.soundcloud.components.MenuInputText;
    import com.jxl.soundcloud.components.PushButton;
    import com.jxl.soundcloud.events.AuthorizeViewEvent;
    
    import flash.desktop.NativeApplication;
    import flash.display.DisplayObjectContainer;
    import flash.display.Graphics;
    import flash.display.StageOrientation;
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.LocationChangeEvent;
    import flash.events.MouseEvent;
    import flash.events.StageOrientationEvent;
    import flash.geom.Rectangle;
    import flash.globalization.NationalDigitsType;
    import flash.media.StageWebView;
    import flash.ui.Keyboard;

    [Event(name="codeSubmit", type="com.jxl.soundcloud.events.AuthorizeViewEvent")]
	[Event(name="abortAuthorization", type="com.jxl.soundcloud.events.AuthorizeViewEvent")]
	[Event(name="reloadAuthorize", type="com.jxl.soundcloud.events.AuthorizeViewEvent")]
	public class AuthorizeView extends Component
	{

		public static const STATE_MAIN:String = "mainState";
		public static const STATE_LOADING:String = "loadingState";
		
        public function get webView():StageWebView { return web; }
		
        private var web:StageWebView;
		
		public function AuthorizeView(parent:DisplayObjectContainer=null, xpos:Number=0, ypos:Number=0)
		{
			super(parent, xpos, ypos);

			
		}
		
		protected override function init():void
		{
			super.init();
			
			currentState = STATE_MAIN;
			setSize(Constants.WIDTH, Constants.HEIGHT);
			this.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			this.addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
			
			NativeApplication.nativeApplication.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}
		
		private function onKeyDown(event:KeyboardEvent):void
		{
			// don't handle unless you're actually showing
			if(stage == null) return;
			
			switch(event.keyCode)
			{
				case Keyboard.BACK:
					switch(currentState)
					{
						case STATE_LOADING:
							event.preventDefault();
							dispatchEvent(new AuthorizeViewEvent(AuthorizeViewEvent.ABORT_AUTHORIZE));
							break;
						
						case STATE_MAIN:
						default:
							// zee goggles, zey do nuffing!
							break;
					}
					break;
			}
		}

        private function onAddedToStage(event:Event):void
        {
            web.stage = stage;
        }

        private function onRemovedFromStage(event:Event):void
        {
            web.stage = null;
        }

        public function loadURL(url:String):void
        {
            web.loadURL(url);
        }
		
		public function refresh():void
		{
			if(web)
				web.reload();
		}
		
		public function hide():void
		{
			visible = false;
			web.stage = null;
		}
		
		public function show():void
		{
			visible = true;
			if(stage)
				web.stage = stage;
		}

        public function destroy():void
        {
			NativeApplication.nativeApplication.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			
            this.removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
            this.removeEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);

            web.removeEventListener(Event.COMPLETE, onLocationChange);
			web.removeEventListener(ErrorEvent.ERROR, onURLError);
            web.removeEventListener(LocationChangeEvent.LOCATION_CHANGE, onLocationChange);
            web.stop();
            web.dispose();
            web = null;
        }

		protected override function addChildren():void
		{
			super.addChildren();

            web = new StageWebView();
            web.addEventListener(Event.COMPLETE, onLocationChange);
            web.addEventListener(ErrorEvent.ERROR, onURLError);
			web.addEventListener(LocationChangeEvent.LOCATION_CHANGE, onLocationChange);
		}
		
		private function onLocationChange(event:Event):void
		{
			var location:String;
			
			if(event is LocationChangeEvent)
			{
				location = LocationChangeEvent(event).location;
			}
			else
			{
				location = web.location;
			}
			
			
			var search:String 		= "oauth_verifier=";
			var ver:String 			= location;
			var startIndex:int 		= ver.lastIndexOf(search);
			if(startIndex != -1)
			{
				ver = ver.substr(startIndex + search.length, location.length);
				var evt:AuthorizeViewEvent 	= new AuthorizeViewEvent(AuthorizeViewEvent.CODE_SUBMITTED);
				evt.code					= ver;
				dispatchEvent(evt);
			}
		}

        private function onURLError(event:ErrorEvent):void
        {
            Debug.log("AuthorizeView::onURLError: " + event);
        }
		
		public override function draw():void
		{
			super.draw();

			var g:Graphics;
			var targetY:Number;
			
			web.viewPort = new Rectangle(0, 0, width, height);
			
			g = graphics;
			g.clear();
			g.beginFill(0xFFFFFF);
			g.drawRect(0, 0, width, height);
			
			g.lineStyle(6, 0x666666);
			g.drawRect(web.viewPort.x,  web.viewPort.y,  web.viewPort.width, web.viewPort.height);
			
			
			g.endFill();
		}
	}
}