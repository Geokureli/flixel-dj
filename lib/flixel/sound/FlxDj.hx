package flixel.sound;

import flixel.sound.FlxSoundGroup;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.tweens.FlxTween;

typedef FlxDj = FlxTypedDj<String>;

/**
 * A multi-track management tool
 */
class FlxTypedDj<TrackID:String> extends flixel.FlxBasic
{
	/** The group controlling and updating these sounds */
	final tracks = new Map<TrackID, FlxDjTrack>();
	
	public var current:Null<TrackID>;
	var currentTrack(get, never):Null<FlxDjTrack>;
	inline function get_currentTrack() return tracks[current];
	
	public function new(group:FlxSoundGroup)
	{
		super();
	}
	
	override function destroy()
	{
		super.destroy();
		
		current = null;
		for (track in tracks)
			track.destroy();
		tracks.clear();
	}
	
	public function has(id:TrackID)
	{
		return tracks.exists(id);
	}
	
	function assert(id:TrackID)
	{
		if (has(id))
			return tracks[id];
		
		throw 'No track with id: $id';
	}
	
	public function add(id:TrackID, track:FlxDjTrack):FlxDjTrack
	{
		if (has(id))
			throw 'Track: "$id" already exists';
		
		return tracks[id] = track;
	}
	
	public function remove(id:TrackID):Null<FlxDjTrack>
	{
		final track = tracks[id];
		if (track != null)
		{
			tracks.remove(id);
			return track;
		}
		
		FlxG.log.warn('No track with id: $id');
		return null;
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		for (track in tracks)
		{
			track.update(elapsed);
		}
	}
	
	public function play(id:TrackID, forceRestart = true, startTime = 0.0, ?endTime:Float)
	{
		if (current != null)
			assert(current).stop();
		
		final track = assert(id);
		current = id;
		track.play(forceRestart, startTime, endTime);
	}
	
	public function fadeTrackTo(id:TrackID, fadeTime:Float, forceRestart = true, startTime = 0.0, ?endTime:Float)
	{
		if (current != null)
		{
			final prevTrack = assert(current);
			prevTrack.stop();
		}
		
		final track = assert(id);
		current = id;
		track.play(forceRestart, startTime, endTime);
	}
}