package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteContainer;
import flixel.sound.FlxDj;
import flixel.sound.FlxDjChannel;
import flixel.sound.FlxDjTrack;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import openfl.utils.ByteArray;
#if html5
import openfl.display.Loader;
import openfl.display.LoaderInfo;
import openfl.events.Event;
import openfl.net.FileFilter;
import openfl.net.FileReference;
#end

class LoadState extends flixel.FlxState
{
	var fadeInfo:FlxText;
	var dj:FlxDj;
	var trackUI:TrackUI;
	
	override function create()
	{
		super.create();
		FlxG.camera.bgColor = 0xFF6699FF;
		
		dj = new FlxDj();
		FlxG.plugins.addPlugin(dj);
		
		final margin = 35;
		
		final track = new FlxDjTrack();
		final trackID = "Track";
		dj.add(trackID, track);
		
		trackUI = new TrackUI(track, trackID, playTrack.bind(trackID), ()->dj.fadeTrackTo(trackID, ChannelUI.fadeTime, true));
		trackUI.x = margin;
		trackUI.y = margin;
		add(trackUI);
		
		// fade controller
		fadeInfo = new FlxText('Fade time [U/D arrows]: ${ChannelUI.fadeTime}');
		fadeInfo.screenCenter(X);
		fadeInfo.y = FlxG.height - fadeInfo.height - margin;
		add(fadeInfo);
		
		#if FLX_DEBUG
		FlxG.watch.addFunction('dj.current', function ()
		{
			if (dj.current == null)
				return null;
			
			return '${dj.current}: ${[for (id=>channel in dj.currentTrack.channels) '$id: $channel']}';
		});
		#end
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		final keys = FlxG.keys.pressed;
		final fadeTimeDelta = (keys.UP || keys.W ? 1.0 : 0.0) - (keys.DOWN || keys.S ? 1.0 : 0.0);
		
		if (fadeTimeDelta != 0)
		{
			ChannelUI.fadeTime += fadeTimeDelta * 0.25 * elapsed;
			if (ChannelUI.fadeTime < 0.0)
				ChannelUI.fadeTime = 0.0;
			
			fadeInfo.text = 'Fade time: ${Math.round(ChannelUI.fadeTime * 100) / 100}\nL/R arrow keys to change';
		}
	}
	
	function playTrack(id:String)
	{
		if (dj.current == null)
			dj.play(id);
		
		if (dj.current != id)
			dj.fadeTrackTo(id, ChannelUI.fadeTime);
	}
}

typedef TrackUI = TypedTrackUI<String>;

inline final gap = 4;

private class TypedTrackUI<ID:String> extends FlxSpriteContainer
{
	public final track:FlxDjTrack;
	
	final channels = new FlxTypedSpriteContainer<ChannelUI>();
	final name:ID;
	final label:FlxText;
	final playLine:FlxSprite;
	
	public function new (track, name:ID, onPlay:()->Void, onRestart:()->Void)
	{
		this.track = track;
		this.name = name;
		super();
		
		var y = 0.0;
		
		label = new FlxText(0, y, ChannelUI.LABEL_WIDTH, name);
		add(label);
		
		final playBtn = new FlxButton(0, y, "Play", onPlay);
		playBtn.x = label.x + label.width;
		label.y = playBtn.y + (playBtn.height - label.height) / 2;
		add(playBtn);
		
		final restartBtn = new FlxButton(0, y, "Restart", onRestart);
		restartBtn.x = playBtn.x + playBtn.width + ChannelUI.BUTTON_GAP;
		label.y = restartBtn.y + (restartBtn.height - label.height) / 2;
		add(restartBtn);
		
		y += playBtn.height + gap;
		
		final bgLine = new FlxSprite(0, y);
		bgLine.makeGraphic(Std.int(this.width), 3, 0xFFffffff);
		add(bgLine);
		
		playLine = new FlxSprite(1, y + 1);
		playLine.makeGraphic(Std.int(this.width) - 2, 1, 0xFF000000);
		playLine.origin.x = 0;
		add(playLine);
		
		y += bgLine.height + gap;
		
		final allOnBtn = new FlxButton(0, y, "All on", allOnClick);
		allOnBtn.x = ChannelUI.LABEL_WIDTH;
		add(allOnBtn);
		
		final allOffBtn = new FlxButton(0, y, "All off", allOffClick);
		allOffBtn.x = allOnBtn.x + allOnBtn.width + ChannelUI.BUTTON_GAP;
		add(allOffBtn);
		
		y += allOnBtn.height + gap;
		
		final addBtn = new FlxButton(0, y, "Add channel", onAddClick);
		add(addBtn);
		y += addBtn.height + gap;
		
		// for (id=>channel in track.channels)
		// {
		// 	if (channel.syncMode.match(ONCE))
		// 		addChannelUI(0, y, id, channel);
		// }
		
		// final margin = 3;
		// final loopLabel = new FlxText(0, y - margin, "Sub-loops");
		// loopLabel.x = (channels.width - loopLabel.width) / 2;
		// loopLabel.exists = false;
		// y += loopLabel.height + gap - margin * 2;
		
		// for (id=>channel in track.channels)
		// {
		// 	if (channel.syncMode.match(LOOP(_)))
		// 	{
		// 		addChannelUI(0, y, id, channel);
		// 		loopLabel.exists = false;
		// 	}
		// }
		
		add(channels);
		// add(loopLabel);
	}
	
	function appendChannel(id:String, byteArray:ByteArray)
	{
		// final sound = new openfl.media.Sound();
		// sound.loadCompressedDataFromByteArray(byteArray, byteArray.length);
		// trace('Appended $id, length: ${sound.length}');
		trace('Appended $id');
		// final channel = track.add(id, sound);
		final channel = new FlxDjChannel(track, LOOP(null));
		channel.loadByteArray(byteArray);
		track.addChannel(id, channel);
		
		addChannelUI(0, this.height + gap, id, channel);
	}
	
	function addChannelUI(x = 0.0, y = 0.0, id:String, channel:FlxDjChannel)
	{
		final button = new ChannelUI(0, y, track, id);
		channels.add(button);
		y += button.height + gap;
	}
	
	function allOnClick()
	{
		for (id=>channel in track.channels)
		{
			if (channel.syncMode.match(ONCE) && channel.volume != 1.0)
				channel.fadeTo(ChannelUI.fadeTime, 1.0);
		}
	}
	
	function allOffClick()
	{
		for (id=>channel in track.channels)
		{
			if (channel.syncMode.match(ONCE) && channel.volume != 0.0)
				channel.fadeTo(ChannelUI.fadeTime, 0.0);
		}
	}
	
	#if html5
	// static var lastSound:Null<openfl.media.SoundChannel> = null;
	static var lastSound:Null<FlxSound> = null;
	function onAddClick()
	{
		final ref = new FileReference();
		
		var onSelect:(Event)->Void = null;
		var onCancel:(Event)->Void = null;
		
		onSelect = function (e)
		{
			ref.removeEventListener(Event.SELECT, onSelect);
			ref.removeEventListener(Event.CANCEL, onCancel);
			
			trace('Selected: ${ref.name}');
			function onLoad(e:Event)
			{
				trace('Loaded: ${ref.name} bytes: ${ref.data.length}b');
				ref.removeEventListener(Event.COMPLETE, onLoad);
				
				final splitName = ref.name.split("/").pop().split(".");
				splitName.pop();
				final name = splitName.join(".");
				appendChannel(name, ref.data);
				
				// if (lastSound != null)
				// {
				// 	lastSound.stop();
				// }
				// lastSound = new FlxSound().loadByteArray(ref.data, true);
				// lastSound = new FlxDjChannel(null, LOOP(null));
				// lastSound.play();
				
				// final sound = new openfl.media.Sound();
				// sound.loadCompressedDataFromByteArray(ref.data, ref.data.length);
				// lastSound = sound.play();
			};
			
			// _text.text = ref.name;
			ref.addEventListener(Event.COMPLETE, onLoad);
			ref.load();
		}
		
		onCancel = function (e)
		{
			ref.removeEventListener(Event.SELECT, onSelect);
			ref.removeEventListener(Event.CANCEL, onCancel);
			
			trace("Cancelled browse");
		}
		
		ref.addEventListener(Event.SELECT, onSelect);
		ref.addEventListener(Event.CANCEL, onCancel);
		var filters = [new FileFilter("OGG Files", "*.ogg")];
		trace("Opening browser");
		ref.browse();
	}
	#end
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		label.text = '$name: ${Math.floor(track.volume * 100)}';
		
		for (channel in channels)
			channel.label.text = '${channel.id}: ${Math.floor(100 * track.getChannelVolume(channel.id))}';
		
		playLine.scale.x = track.time / track.duration;
	}
}

typedef ChannelUI = TypedChannelUI<String>;

class TypedChannelUI<ID:String> extends FlxSpriteContainer
{
	static public inline var LABEL_WIDTH = 100;
	static public inline var BUTTON_GAP = 4;
	static public var fadeTime = 0.25;
	
	public final label:FlxText;
	public final toggleBtn:FlxButton;
	public final focusBtn:FlxButton;
	public final id:ID;
	
	public function new (x = 0.0, y = 0.0, track:FlxDjTrack, id:ID)
	{
		this.id = id;
		super();
		
		label = new FlxText(0, 0, LABEL_WIDTH, '$id: 0');
		
		toggleBtn = new FlxButton(label.width, 0, "toggle", function()
		{
			if (track.getChannelVolume(id) == 0)
				track.fadeChannelIn(id, fadeTime);
			else
				track.fadeChannelOut(id, fadeTime);
		});
		
		focusBtn = new FlxButton(toggleBtn.x + toggleBtn.width + BUTTON_GAP, 0, "focus", ()->track.fadeChannelFocus(id, fadeTime));
		
		label.y = toggleBtn.y + (toggleBtn.height - label.height) / 2;
		add(label);
		add(toggleBtn);
		add(focusBtn);
		
		this.x = x;
		this.y = y;
	}
}