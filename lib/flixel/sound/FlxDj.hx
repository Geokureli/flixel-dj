package flixel.sound;

import flixel.sound.FlxSoundGroup;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.tweens.FlxTween;

typedef FlxDj = FlxTypedDj<String>;

/**
 * Controls the
 */
class FlxTypedDj<ID:String> extends flixel.FlxBasic
{
	/** The group controlling and updating these sounds */
	final tracks = new Map<ID, FlxDjTrack>();
	
	final currentTrack:FlxDjTrack;
	
	public function new()
	{
		super();
	}
	
	public function add(track:FlxDjTrack)
	{
		tracks = new Map();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		for (track in tracks)
		{
			track.update(elapsed);
		}
	}
}