package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteContainer;
import flixel.sound.FlxDj;
import flixel.sound.FlxDjTrack;
import flixel.text.FlxText;
import flixel.ui.FlxButton;

class Main extends openfl.display.Sprite
{
	public function new()
	{
		super();
		addChild(new flixel.FlxGame(PlayState.new));
	}
}


enum abstract TrackID(String) to String
{
	var MUSIC_BOX = "Music Box";
	var SWORDS = "Swords";
}

@:forward(toLowerCase)
enum abstract ChannelID(String) to String
{
	static public final musicBoxOnce = [FROG, REINDEER, SNOW, TANK, TANKMAN, TREE];
	var FROG = "Frog";
	var REINDEER = "Reindeer";
	var SNOW = "Snow";
	var TANK = "Tank";
	var TANKMAN = "Tankman";
	var TREE = "Tree";
	
	static public final musicBoxLoop = [BIRD, CAKE, GEARS, SPLAT];
	var BIRD = "Bird";
	var CAKE = "Cake";
	var GEARS = "Gears";
	var SPLAT = "Splat";
	
	#if swords // TODO: Replace this with 
	static public final swords = [NEUTRAL, ANGEL, DEMON, GEAR, MENU, PLANT];
	var NEUTRAL = "Neutral";
	var ANGEL = "Angel";
	var DEMON = "Demon";
	var GEAR = "Gear";
	var MENU = "Menu";
	var PLANT = "Plant";
	#end
}

class PlayState extends flixel.FlxState
{
	var musicBox:TrackUI;
	var swords:TrackUI;
	
	var fadeInfo:FlxText;
	
	override function create()
	{
		super.create();
		FlxG.camera.bgColor = 0xFF6699FF;
		
		final dj = new FlxDj();
		FlxG.plugins.addPlugin(dj);
		
		final margin = 50;
		
		final track1 = new FlxTypedDjTrack<ChannelID>();
		dj.add(MUSIC_BOX, track1);
		
		#if FLX_DEBUG
		FlxG.watch.addFunction('dj.current', ()->dj.current);
		#end
		
		for (channel in ChannelID.musicBoxOnce)
			track1.add(channel, 'assets/music box/music/${channel.toLowerCase()}.wav', channel == TANKMAN ? 1.0 : 0.0);
		
		for (channel in ChannelID.musicBoxLoop)
			track1.addSubLoop(channel, 'assets/music box/sounds/${channel.toLowerCase()}.wav', 0.0, 500);
		
		function playTrack(id)
		{
			dj.fadeTrackTo(id, ChannelUI.fadeTime, false);
		}
		
		function restartTrack(id)
		{
			dj.fadeTrackTo(id, ChannelUI.fadeTime, true);
		}
		
		add(musicBox = new TrackUI(track1, MUSIC_BOX, playTrack.bind(MUSIC_BOX), restartTrack.bind(MUSIC_BOX)));
		musicBox.x = margin;
		musicBox.y = margin;
		
		final track2 = new FlxTypedDjTrack<ChannelID>();
		dj.add(SWORDS, track2);
		
		#if swords
		for (channel in ChannelID.swords)
			track2.add(channel, 'assets/swords/music/${channel.toLowerCase()}.ogg', channel == NEUTRAL ? 1.0 : 0.0);
		add(swords = new TrackUI(track2, "Swords", playTrack.bind(SWORDS), restartTrack.bind(SWORDS)));
		#else
		for (channel in ChannelID.musicBoxOnce)
			track2.add(channel, 'assets/music box/music/${channel.toLowerCase()}.wav', channel == TANKMAN ? 1.0 : 0.0);
		
		for (channel in ChannelID.musicBoxLoop)
			track2.addSubLoop(channel, 'assets/music box/sounds/${channel.toLowerCase()}.wav', 0.0, 500);
		add(swords = new TrackUI(track2, '$MUSIC_BOX 2', playTrack.bind(SWORDS), restartTrack.bind(SWORDS)));
		#end
		
		swords.x = FlxG.width - swords.width - margin;
		swords.y = margin;
		
		// fade controller
		fadeInfo = new FlxText('Fade time [L/R arrows]: ${ChannelUI.fadeTime}');
		fadeInfo.screenCenter(X);
		fadeInfo.y = musicBox.y + musicBox.height;
		add(fadeInfo);
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		final keys = FlxG.keys.pressed;
		final fadeTimeDelta = (keys.RIGHT || keys.D ? 1.0 : 0.0) - (keys.LEFT || keys.A ? 1.0 : 0.0);
		
		if (fadeTimeDelta != 0)
		{
			ChannelUI.fadeTime += fadeTimeDelta * 0.25 * elapsed;
			if (ChannelUI.fadeTime < 0.0)
				ChannelUI.fadeTime = 0.0;
			
			fadeInfo.text = 'Fade time: ${Math.round(ChannelUI.fadeTime * 100) / 100}\nL/R arrow keys to change';
		}
		
		if (FlxG.keys.justPressed.SPACE)
		{
			trace('MusicBox: ${musicBox.track}');
			trace('Swords: ${swords.track}');
		}
	}
}

class TrackUI extends FlxSpriteContainer
{
	public final track:FlxTypedDjTrack<ChannelID>;
	
	final channels = new FlxTypedSpriteContainer<ChannelUI>();
	final name:String;
	final label:FlxText;
	final playLine:FlxSprite;
	
	public function new (track, name:String, onPlay:()->Void, onRestart:()->Void)
	{
		this.track = track;
		this.name = name;
		super();
		
		var y = 0.0;
		final gap = 4;
		
		label = new FlxText(0, y, ChannelUI.LABEL_WIDTH, name);
		add(label);
		
		final playBtn = new FlxButton(0, y, "Play", onPlay);
		playBtn.x = label.x + label.width;
		label.y = playBtn.y + (playBtn.height - label.height) / 2;
		add(playBtn);
		
		final restartBtn = new FlxButton(0, y, "Restart", onRestart);
		restartBtn.x = playBtn.x + playBtn.width;
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
		allOffBtn.x = allOnBtn.x + allOnBtn.width;
		add(allOffBtn);
		
		y += allOnBtn.height + gap;
		
		for (id=>channel in track.channels)
		{
			if (channel.syncMode.match(ONCE))
			{
				final button = new ChannelUI(0, y, track, id);
				channels.add(button);
				y += button.height + gap;
			}
		}
		
		final margin = 3;
		final loopLabel = new FlxText(0, y - margin, "Sub-loops");
		loopLabel.x = (channels.width - loopLabel.width) / 2;
		loopLabel.exists = false;
		y += loopLabel.height + gap - margin * 2;
		
		for (id=>channel in track.channels)
		{
			if (channel.syncMode.match(LOOP(_)))
			{
				final button = new ChannelUI(0, y, track, id);
				channels.add(button);
				y += button.height + gap;
				loopLabel.exists = true;
			}
		}
		
		add(channels);
		add(loopLabel);
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
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		label.text = '$name: ${Math.floor(track.volume * 100)}';
		
		for (channel in channels)
			channel.label.text = '${channel.id}: ${Math.floor(100 * track.getChannelVolume(channel.id))}';
		
		playLine.scale.x = track.time / track.duration;
	}
}

class ChannelUI extends FlxSpriteContainer
{
	static public inline var LABEL_WIDTH = 75;
	static public var fadeTime = 0.25;
	
	public final label:FlxText;
	public final toggleBtn:FlxButton;
	public final focusBtn:FlxButton;
	public final id:ChannelID;
	
	public function new (x = 0.0, y = 0.0, track:FlxDjTrack, id:ChannelID)
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
		
		focusBtn = new FlxButton(toggleBtn.x + toggleBtn.width, 0, "focus", ()->track.fadeChannelFocus(id, fadeTime));
		
		label.y = toggleBtn.y + (toggleBtn.height - label.height) / 2;
		add(label);
		add(toggleBtn);
		add(focusBtn);
		
		this.x = x;
		this.y = y;
	}
}