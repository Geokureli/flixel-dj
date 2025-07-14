package;

import flixel.FlxG;
import flixel.group.FlxSpriteContainer;
import flixel.sound.FlxDjTrack;
import flixel.text.FlxText;
import flixel.ui.FlxButton;

class PlayState extends flixel.FlxState
{
	var dj:FlxDjTrack;
	
	var fadeInfo:FlxText;
	var buttons = new FlxTypedSpriteContainer<ChannelUI>();
	
	override function create()
	{
		super.create();
		FlxG.camera.bgColor = 0xFF6699FF;
		
		FlxG.plugins.addPlugin(dj = new FlxDjTrack());
		
		var y = 0.0;
		final gap = 0;
		
		final allOnBtn = new FlxButton(0, y, "All channels on", allOnClick);
		allOnBtn.screenCenter(X);
		add(allOnBtn);
		y += allOnBtn.height + gap;
		
		for (channel in ChannelID.allOnce)
		{
			dj.add(channel, 'assets/music/$channel.wav', 0.0);
			final button = new ChannelUI(0, y, dj, channel);
			buttons.add(button);
			y += button.height + gap;
		}
		
		final margin = 3;
		final loopLabel = new FlxText(0, y - margin, "Sub-loops");
		loopLabel.screenCenter(X);
		y += loopLabel.height + gap - margin * 2;
		
		for (channel in ChannelID.allLoop)
		{
			dj.addSubLoop(channel, 'assets/sounds/$channel.wav', 0.0, 500);
			final button = new ChannelUI(0, y, dj, channel);
			buttons.add(button);
			y += button.height + gap;
		}
		
		buttons.screenCenter(X);
		add(buttons);
		add(loopLabel);
		
		fadeInfo = new FlxText("Fade time [L/R arrows]: 0.25");
		fadeInfo.y = y;
		fadeInfo.screenCenter(X);
		add(fadeInfo);
	}
	
	function allOnClick()
	{
		for (channel in ChannelID.allOnce)
		{
			if (dj.getChannelVolume(channel) != 1.0)
				dj.fadeIn(channel, ChannelUI.fadeTime);
		}
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
			
			fadeInfo.text = 'Fade time: ${ChannelUI.fadeTime}\nL/R arrow keys to change';
		}
		
		if (FlxG.keys.justPressed.SPACE)
		{
			trace(dj);
		}
	}
}

enum abstract ChannelID(String) to String
{
	static public final allOnce = [FROG, REINDEER, SNOW, TANK, TANKMAN, TREE];
	var FROG = "frog";
	var REINDEER = "reindeer";
	var SNOW = "snow";
	var TANK = "tank";
	var TANKMAN = "tankman";
	var TREE = "tree";
	
	// TODO: make sounds loop better
	static public final allLoop = [BIRD, CAKE, GEARS, SPLAT];
	// static public final allLoop:Array<ChannelID> = [];
	var BIRD = "bird";
	var CAKE = "cake";
	var GEARS = "gears";
	var SPLAT = "splat";
	
	public function toTitleCase()
	{
		return this.substr(0, 1).toUpperCase() + this.substr(1);
	}
}

class ChannelUI extends FlxSpriteContainer
{
	static public var fadeTime = 0.25;
	
	final labelUpdater:()->String;
	final label:FlxText;
	final toggleBtn:FlxButton;
	final focusBtn:FlxButton;
	
	public function new (x = 0.0, y = 0.0, dj:FlxDjTrack, channel:ChannelID)
	{
		super();
		
		label = new FlxText(0, 0, 100, '${channel.toTitleCase()}: 0');
		labelUpdater = ()->'${channel.toTitleCase()}: ${Math.floor(100 * dj.getChannelVolume(channel))}';
		
		toggleBtn = new FlxButton(label.width, 0, "toggle", function()
		{
			if (dj.getChannelVolume(channel) == 0)
				dj.fadeIn(channel, fadeTime);
			else
				dj.fadeOut(channel, fadeTime);
		});
		
		focusBtn = new FlxButton(toggleBtn.x + toggleBtn.width, 0, "focus", ()->dj.fadeFullFocus(channel, fadeTime));
		
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