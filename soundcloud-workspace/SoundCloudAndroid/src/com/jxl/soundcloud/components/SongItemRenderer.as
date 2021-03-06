package com.jxl.soundcloud.components
{
    import assets.Styles;
    import assets.flash.LoadingProgress;
    import assets.flash.PlaybackProgress;
    
    import com.bit101.components.Component;
    import com.bit101.components.Label;
    import com.jxl.debug.debug_mizznax;
    import com.jxl.soundcloud.events.SongEvent;
    import com.jxl.soundcloud.vo.SongVO;
    
    import flash.debugger.enterDebugger;
    import flash.display.Bitmap;
    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.display.Graphics;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.display.StageOrientation;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.text.AntiAliasType;
    import flash.text.TextField;
    

    [Event(name="play", type="com.jxl.soundcloud.events.SongEvent")]
	[Event(name="stop", type="com.jxl.soundcloud.events.SongEvent")]
    [Event(name="seekClicked", type="com.jxl.soundcloud.events.SongEvent")]
	public class SongItemRenderer extends Component implements IItemRenderer
	{

        [Embed(source="/assets/images/song-background.jpg")]
        private static var BackgroundImage:Class;

        [Embed(source="/assets/images/waveform-background.jpg")]
        private static var WaveformBackgroundImage:Class;

        private var background:Bitmap;
		private var songImage:ImageLoader;
        private var waveFormBackground:Bitmap;
        private var waveFormImage:ImageLoader;
		private var playButton:PlayPauseButton;
		private var songNameLabel:TextField;
        private var songTimeLabel:Label;
        private var loadingProgress:LoadingProgress;
        private var playbackProgress:PlaybackProgress;
        private var seekClicker:Sprite;
		private var playButtonHitState:Sprite;
		private var debugShape:Shape;

		private var _data:*;
		private var songVO:SongVO;
		private var dataDirty:Boolean = false;
        private var pooledProgress:Number;

		public function get data():* { return _data; }
		public function set data(value:*):void
		{
			if(value !== songVO)
			{
				if(songVO)
				{
					songVO.removeEventListener("playingChanged", onPlayingChanged);
	                songVO.removeEventListener("currentTimeChanged", onCurrentTimeChanged);
	                songVO.removeEventListener("downloadProgressChanged", onDownloadProgressChanged);
					songVO = null;
				}
				_data = value;
				if(_data && _data is SongVO)
				{
					songVO = _data as SongVO;
					songVO.addEventListener("playingChanged", onPlayingChanged, false, 0, true);
	                songVO.addEventListener("currentTimeChanged", onCurrentTimeChanged, false, 0, true);
	                songVO.addEventListener("downloadProgressChanged", onDownloadProgressChanged, false, 0, true);
				}
				dataDirty = true;
				invalidateProperties();
			}
		}
		
		
		public function SongItemRenderer(parent:DisplayObjectContainer=null, xpos:Number=0, ypos:Number=0)
		{
			super(parent, xpos, ypos);
		}
		
		protected override function init():void
		{
			super.init();
			this.setSize(456, 138);
		}
		
		private function cacheIt(obj:DisplayObject, cache:Boolean=true):void
		{
			obj.cacheAsBitmap = cache;
			if(cache)
			{
				obj.cacheAsBitmapMatrix = new Matrix();
			}
			else
			{
				obj.cacheAsBitmapMatrix = null;
			}
		}
		
		override protected function addChildren():void
		{
			super.addChildren();

            background = new BackgroundImage() as Bitmap;
            addChild(background);
			
			songImage = new ImageLoader();
			addChild(songImage);
			songImage.scaleContent = true;
			
			playButton = new PlayPauseButton();
			addChild(playButton);
			playButton.addEventListener(MouseEvent.CLICK, onPlay);
			
			songNameLabel = new TextField();
			songNameLabel.multiline = songNameLabel.wordWrap = true;
			songNameLabel.selectable = songNameLabel.mouseEnabled = songNameLabel.tabEnabled = false;
			addChild(songNameLabel);
            songNameLabel.defaultTextFormat = Styles.SONG_TITLE;
            songNameLabel.embedFonts = true;
            songNameLabel.antiAliasType = AntiAliasType.ADVANCED;
			//songNameLabel.border = true;
			//songNameLabel.borderColor = 0xFF0000;

            waveFormBackground = new WaveformBackgroundImage() as Bitmap;
            //addChild(waveFormBackground);

            loadingProgress = new LoadingProgress();
            addChild(loadingProgress);

            waveFormImage = new ImageLoader();
            addChild(waveFormImage);
            waveFormImage.scaleContent = true;
            waveFormImage.maintainAspectRatio = false;

            playbackProgress = new PlaybackProgress();
            addChild(playbackProgress);

            seekClicker = new Sprite();
            addChild(seekClicker);
            seekClicker.mouseChildren = false;
            seekClicker.mouseEnabled = true;
            seekClicker.buttonMode = true;
            seekClicker.addEventListener(MouseEvent.MOUSE_DOWN, onSongSeekClick);

            songTimeLabel = new Label(this);
            songTimeLabel.textField.defaultTextFormat = Styles.SONG_TIME;
            songTimeLabel.textField.embedFonts = true;
            songTimeLabel.textField.antiAliasType = AntiAliasType.ADVANCED;
			
			playButtonHitState = new Sprite();
			playButtonHitState.mouseEnabled = false;
			playButton.hitArea = playButtonHitState;
			addChild(playButtonHitState);
			playButtonHitState.visible = false;
			
			debugShape = new Shape();
			addChild(debugShape);
			
			setBitmapCached(true);
		}
		
		protected override function commitProperties():void
		{
			super.commitProperties();
			
			if(dataDirty)
			{
				dataDirty = false;
				if(songVO)
				{
					songImage.source 			= songVO.artworkURL;
					songNameLabel.text 			= songVO.title;
                    waveFormImage.source        = songVO.waveformURL;
                    updateSongTime();
				}
				else
				{
					songImage.source			= null;
					songNameLabel.text			= "";
                    waveFormImage.source        = null;
                    songTimeLabel.text          = "";
				}
				
				onPlayingChanged();
				this.invalidateDraw();
			}
		}
		
		private function onPrematureDraw(event:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, onPrematureDraw);
			draw();
		}
		
		// http://www.youtube.com/watch?v=_2XmLcnYSwQ&fmt=18
		public override function draw():void
		{
			super.draw();
			
			if(stage == null)
			{
				addEventListener(Event.ADDED_TO_STAGE, onPrematureDraw);
				return;
			}
			
			songImage.move(0, 0);
			songImage.setSize(44, 44);
			
			playButton.move(19, 52);
			
			songNameLabel.width = 404;
			
			songTimeLabel.move(2, 116);
			
			background.y        	= playButton.y - 2;
			background.width    	= width;
			background.height 		= height - background.y;
			
			songNameLabel.x = 49;
			songNameLabel.y = songImage.y + songImage.height - (songNameLabel.textHeight + 4);
			
			waveFormImage.move(101, background.y + 1);
			waveFormImage.setSize(width - waveFormImage.x - 1, background.height - 1);
			
			var playButtonHitStateGraphics:Graphics = playButtonHitState.graphics;
			playButtonHitStateGraphics.clear();
			playButtonHitStateGraphics.beginFill(0x00FF00);
			playButtonHitStateGraphics.drawRect(0, 0, 100, 100);
			playButtonHitStateGraphics.endFill();
			
			
			playButtonHitState.x = background.x;
			playButtonHitState.y = background.y;
			
			waveFormBackground.x = waveFormImage.x;
			waveFormBackground.y = waveFormImage.y;
			waveFormBackground.width = waveFormImage.width;
			waveFormBackground.height = waveFormImage.height;
			
			loadingProgress.x = playbackProgress.x = waveFormImage.x;
			loadingProgress.y = playbackProgress.y =  waveFormImage.y;
			loadingProgress.width =  waveFormImage.width;
			loadingProgress.height = waveFormImage.height;
			
			seekClicker.x = loadingProgress.x;
			seekClicker.y = loadingProgress.y;
			
			
			updateSongProgressBackground();	
			
			
			setChildIndex(debugShape, numChildren - 1);
			
			
			onPlayingChanged();
			/*
			var g:Graphics = graphics;
			g.clear();
			g.lineStyle(4, 0xFF0000);
			g.drawRect(songNameLabel.x, songNameLabel.y, songNameLabel.width, songNameLabel.height);
			g.endFill();
			*/
        }

        private function updateSongTime():void
        {
            songTimeLabel.text 		= millisecondsToTime(songVO.currentTime) + " / " + millisecondsToTime(songVO.duration);
            pooledProgress 			= Math.round((songVO.currentTime / songVO.duration) * 100);
			playbackProgress.setProgress(waveFormImage.width, waveFormImage.height, (songVO.currentTime / songVO.duration));
            updateSongProgressBackground();
        }

        private function updateSongProgressBackground():void
        {
            var g:Graphics = seekClicker.graphics;
			g.clear();
			if(songVO)
			{
				//g.lineStyle(0, 0xFF0000);
	            g.beginFill(0x00FF00, 0);
				g.drawRect(0, 0,  waveFormImage.width * songVO.downloadProgress,  loadingProgress.height);
				g.endFill();
			}
	       
        }

        private function millisecondsToTime(milliseconds:Number):String
        {

            var seconds:Number = Math.floor(milliseconds / 1000);
            var minutes:Number = Math.floor(seconds / 60);
            var hours:Number   = Math.floor(minutes / 60);

            seconds %= 60;
            minutes %= 60;
            hours   %= 24;

            var secondsString:String = seconds.toString();
            var minutesString:String = minutes.toString();
            var hoursString:String   = hours.toString();

            if(secondsString.length < 2)
                secondsString = "0" + secondsString;

            if(minutesString.length < 2)
                minutesString = "0" + minutesString;


            return hoursString + ":" + minutesString + ":" + secondsString;
        }

		private function onPlay(event:MouseEvent):void
		{
			if(songVO)
			{
				var evt:SongEvent;
				if(songVO.playing == false)
				{
					evt			 	= new SongEvent(SongEvent.PLAY, true);
				}
				else
				{
					evt				= new SongEvent(SongEvent.STOP, true);
				}
				evt.song 			= songVO;
				dispatchEvent(evt);
			}
		}
		
		private function onPlayingChanged(event:Event=null):void
		{
			if(songVO == null)
			{
				setBitmapCached(true);
				playButton.selected = false;
				return;
			}
			playButton.selected = songVO.playing;
			if(songVO.playing)
			{
				setBitmapCached(false);
			}
			else
			{
				setBitmapCached(true);
			}
		}

        private function onCurrentTimeChanged(event:Event):void
        {
            updateSongTime();
        }

        private function onDownloadProgressChanged(event:Event):void
        {
            loadingProgress.setProgress(songVO.downloadProgress);
        }

        private function onSongSeekClick(event:MouseEvent):void
        {
            var evt:SongEvent           = new SongEvent(SongEvent.SEEK_CLICKED, true);
            evt.seekPercent             = seekClicker.mouseX / loadingProgress.width;
            dispatchEvent(evt);
        }
		
		private function setBitmapCached(cached:Boolean):void
		{
			cacheAsBitmap = cached;
			if(cached)
			{
				cacheAsBitmapMatrix = new Matrix();
			}
			else
			{
				cacheAsBitmapMatrix = null;
			}
			/*
			cacheIt(background, cached);
			cacheIt(songImage, cached);
			cacheIt(playButton, cached);
			cacheIt(songNameLabel, cached);
			cacheIt(waveFormBackground, cached);
			cacheIt(waveFormImage, cached);
			cacheIt(seekClicker, cached);
			cacheIt(playButtonHitState, cached);
			cacheIt(debugShape, cached);
			*/
		}
			
	}
}