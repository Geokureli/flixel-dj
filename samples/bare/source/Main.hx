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


enum abstract ChannelID(String) to String
{
	static public final track1Once = [FROG, REINDEER, SNOW, TANK, TANKMAN, TREE];
	var FROG = "frog";
	var REINDEER = "reindeer";
	var SNOW = "snow";
	var TANK = "tank";
	var TANKMAN = "tankman";
	var TREE = "tree";
	
	static public final track1Loop = [BIRD, CAKE, GEARS, SPLAT];
	var BIRD = "bird";
	var CAKE = "cake";
	var GEARS = "gears";
	var SPLAT = "splat";
	
	public function toTitleCase()
	{
		return this.substr(0, 1).toUpperCase() + this.substr(1);
	}
}

class PlayState extends flixel.FlxState
{
	var ui1:TrackUI;
	
	var fadeInfo:FlxText;
	
	override function create()
	{
		super.create();
		FlxG.camera.bgColor = 0xFF6699FF;
		
		var track1 = new FlxDjTrack();
		FlxG.plugins.addPlugin(track1);
		
		for (channel in ChannelID.track1Once)
			track1.add(channel, 'assets/music box/music/$channel.wav', 0.0);
		
		for (channel in ChannelID.track1Loop)
			track1.addSubLoop(channel, 'assets/music box/sounds/$channel.wav', 0.0, 500);
		
		add(ui1 = new TrackUI(track1, "Music Box"));
		ui1.screenCenter();
		
		fadeInfo = new FlxText('Fade time [L/R arrows]: ${ChannelUI.fadeTime}');
		fadeInfo.screenCenter(X);
		fadeInfo.y = ui1.y + ui1.height;
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
			trace('track1: ${ui1.track}');
		}
	}
}

class TrackUI extends FlxSpriteContainer
{
	public final track:FlxDjTrack;
	
	final buttons = new FlxTypedSpriteContainer<ChannelUI>();
	
	public function new (track:FlxDjTrack, name:String)
	{
		this.track = track;
		super();
		
		var y = 0.0;
		final gap = 4;
		
		final label = new FlxText(0, y, 100, name);
		add(label);
		
		final allOnBtn = new FlxButton(0, y, "All on", allOnClick);
		allOnBtn.x = label.x + label.width;
		add(allOnBtn);
		
		final allOffBtn = new FlxButton(0, y, "All off", allOffClick);
		allOffBtn.x = allOnBtn.x + allOnBtn.width;
		add(allOffBtn);
		
		label.y = allOnBtn.y + (allOnBtn.height - label.height) / 2;
		
		y += allOnBtn.height + gap;
		
		final line = new FlxSprite(0, y).makeGraphic(Std.int(this.width), 1, 0xFFffffff);
		add(line);
		
		y += line.height + gap;
		
		for (channel in ChannelID.track1Once)
		{
			final button = new ChannelUI(0, y, track, channel);
			buttons.add(button);
			y += button.height + gap;
		}
		
		final margin = 3;
		final loopLabel = new FlxText(0, y - margin, "Sub-loops");
		loopLabel.x = (buttons.width - loopLabel.width) / 2;
		y += loopLabel.height + gap - margin * 2;
		
		for (channel in ChannelID.track1Loop)
		{
			final button = new ChannelUI(0, y, track, channel);
			buttons.add(button);
			y += button.height + gap;
		}
		
		add(buttons);
		add(loopLabel);
	}
	
	function allOnClick()
	{
		for (channel in ChannelID.track1Once)
		{
			if (track.getChannelVolume(channel) != 1.0)
				track.fadeChannelIn(channel, ChannelUI.fadeTime);
		}
	}
	
	function allOffClick()
	{
		for (channel in ChannelID.track1Once)
		{
			if (track.getChannelVolume(channel) != 0.0)
				track.fadeChannelOut(channel, ChannelUI.fadeTime);
		}
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (FlxG.keys.justPressed.SPACE)
		{
			trace(track);
		}
	}
}

class ChannelUI extends FlxSpriteContainer
{
	static public var fadeTime = 0.1;
	
	final labelUpdater:()->String;
	public final label:FlxText;
	public final toggleBtn:FlxButton;
	public final focusBtn:FlxButton;
	
	public function new (x = 0.0, y = 0.0, track:FlxDjTrack, channel:ChannelID)
	{
		super();
		
		label = new FlxText(0, 0, 100, '${channel.toTitleCase()}: 0');
		labelUpdater = ()->'${channel.toTitleCase()}: ${Math.floor(100 * track.getChannelVolume(channel))}';
		
		toggleBtn = new FlxButton(label.width, 0, "toggle", function()
		{
			if (track.getChannelVolume(channel) == 0)
				track.fadeChannelIn(channel, fadeTime);
			else
				track.fadeChannelOut(channel, fadeTime);
		});
		
		focusBtn = new FlxButton(toggleBtn.x + toggleBtn.width, 0, "focus", ()->track.fadeChannelFocus(channel, fadeTime));
		
		label.y = toggleBtn.y + (toggleBtn.height - label.height) / 2;
		add(label);
		add(toggleBtn);
		add(focusBtn);
		
		this.x = x;
		this.y = y;
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		label.text = labelUpdater();
	}
}