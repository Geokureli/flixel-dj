package flixel.sound;

import flixel.sound.FlxSoundGroup;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.tweens.FlxTween;
import flixel.util.FlxSignal;
using flixel.util.NullUtil;


typedef FlxDj = FlxTypedDj<String>;

/**
 * A multi-track management tool
 */
@:nullSafety(Strict)
class FlxTypedDj<TrackID:String> extends flixel.FlxBasic
{
	public final group:FlxSoundGroup;
	
	/** The group controlling and updating these sounds */
	public final tracks = new Map<TrackID, FlxDjTrack>();
	
	/** The id of the current playing track, if any are plying */
	public var current(default, null):Null<TrackID>;
	
	/** The current playing track, if any are plying */
	public var currentTrack(get, never):Null<FlxDjTrack>;
	inline function get_currentTrack() return current == null ? null : tracks[current];
	
	public final preTrackChange = new FlxTypedSignal<(from:Null<TrackID>, to:Null<TrackID>)->Void>();
	public final postTrackChange = new FlxTypedSignal<(from:Null<TrackID>, to:Null<TrackID>)->Void>();
	
	/**
	 * Creates a new DJ
	 * 
	 * @param   group  The group containing all these sounds, if `null`,
	 *                 `FlxG.sound.defaultMusicGroup` is used
	 */
	public function new(?group:FlxSoundGroup)
	{
		this.group = group ?? FlxG.sound.defaultMusicGroup;
		super();
	}
	
	override function destroy()
	{
		super.destroy();
		
		clear(true);
		
		preTrackChange.removeAll();
		postTrackChange.removeAll();
	}
	
	/** Removes and optionally destroys all channels */
	public function clear(destroy = true)
	{
		clearCurrentTrack();
		
		for (id => track in tracks)
			removeHelper(id, track, destroy);
	}
	
	public function clearCurrentTrack()
	{
		final prev = current;
		if (prev != null)
		{
			final prevTrack = assertGet(prev);
			preTrackChange.dispatch(prev, null);
			prevTrack.stop();
		}
		
		current = null;
		
		if (prev != null)
			preTrackChange.dispatch(prev, null);
	}
	
	/** Whether the track contains a channel with the target `id` */
	public function has(id:TrackID)
	{
		return tracks.exists(id);
	}
	
	/** Returns the track with the given`id`, or throws an error, if none exists */
	public function assertGet(id:Null<TrackID>):FlxDjTrack
	{
		if (id != null && has(id))
			return tracks[id].sure();
		
		throw 'No track with id: $id, tracks: ${[for (id in tracks.keys()) id]}';
	}
	
	/**
	 * Adds the given track, which can be referenced by the given id
	 * 
	 * @param   id     The lookup id, to control this Track
	 * @param   track  The track
	 * @return  The track passed in
	 */
	public function add(id:TrackID, track:FlxDjTrack):FlxDjTrack
	{
		if (has(id))
			throw 'Track: "$id" already exists';
		
		return tracks[id] = track;
	}
	
	/** Removes and optionally destroys the track with the given `id` */
	public function remove(id:TrackID, destroy = true):Null<FlxDjTrack>
	{
		final track = tracks[id];
		if (track != null)
		{
			if (id == current)
				clearCurrentTrack();
			
			return removeHelper(id, track, destroy);
		}
		
		FlxG.log.warn('No track with id: $id');
		return null;
	}
	
	function removeHelper(id:TrackID, track:FlxDjTrack, destroy = true):Null<FlxDjTrack>
	{
		tracks.remove(id);
		if (destroy)
			track.destroy();
		
		return track;
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		for (track in tracks)
		{
			track.update(elapsed);
		}
	}
	
	public function addAndPlayEmbedded(id:TrackID, embeddedSound:FlxSoundAsset, volume = 1.0, forceRestart = false, startTime = 0.0, ?endTime:Float, autoDestroy = true)
	{
		if (has(id) == false)
		{
			final track = new FlxDjTrack(group);
			track.autoDestroy = autoDestroy;
			track.add("default", embeddedSound);
			add(id, track);
		}
		
		final track = assertGet(id);
		track.setChannelVolume("default", volume);
		play(id, forceRestart, startTime, endTime);
		return track;
	}
	
	public function addAndFadeToEmbedded(id:TrackID, embeddedSound:FlxSoundAsset, fadeTime:Float, volume = 1.0, forceRestart = false, startTime = 0.0, ?endTime:Float, ?onFade, autoDestroy = true)
	{
		if (has(id) == false)
		{
			final track = new FlxDjTrack(group);
			track.autoDestroy = autoDestroy;
			track.add("default", embeddedSound);
			add(id, track);
		}
		
		final track = assertGet(id);
		track.setChannelVolume("default", volume);
		fadeTrackTo(id, fadeTime, forceRestart, startTime, endTime, onFade);
		return track;
	}
	
	
	/**
	 * Starts or resumes the track, after pausing the previous track
	 * 
	 * @param forceRestart  Whether the new track should restart or resume
	 * @param startTime     Optional way to set the track's time, in milliseconds, if restarting
	 * @param endTime       When to loop back to the start, in milliseconds
	 */
	public function play(id:TrackID, forceRestart = false, startTime = 0.0, ?endTime:Float)
	{
		if (current != null && current != id)
			checkAutoDestroy(current, assertGet(current));
		
		final prev = current;
		final track = assertGet(id);
		preTrackChange.dispatch(prev, id);
		
		current = id;
		track.play(forceRestart, startTime, endTime);
		
		postTrackChange.dispatch(prev, id);
	}
	
	/** Stops the current track and all of its channels, setting the time to 0 */
	public function stop()
	{
		final track = currentTrack;
		if (track == null)
			return;
		
		track.stop();
	}
	
	/** Stops the current track and all of its channels, setting the time to 0 */
	public function pause()
	{
		final track = currentTrack;
		if (track == null)
			return;
		
		track.pause();
	}
	
	/** Stops the current track and all of its channels, setting the time to 0 */
	public function resume()
	{
		assertGet(current).resume();
	}
	
	/**
	 * Fades from the current track to the new one, in the given time. If there is no track
	 * with the given `id`, an error is thrown.
	 * 
	 * @param id            The id of the track to play
	 * @param fadeTime      the time it takes to fade out the old track while fading in the new one
	 * @param forceRestart  Whether the new track should restart or resume
	 * @param startTime     Optional way to set the track's time, in milliseconds, if restarting
	 * @param endTime       When to loop back to the start, in milliseconds
	 * @param onFade        Called when the cross-fade is complete
	 */
	public function fadeTrackTo(id:TrackID, fadeTime:Float, forceRestart = false, startTime = 0.0, ?endTime, ?onFade)
	{
		final nextTrack = assertGet(id);
		if (current != null)
		{
			final prev = current.sure();
			final prevTrack = assertGet(prev);
			preTrackChange.dispatch(prev, id);
			
			if (prev == id)
			{
				// FlxG.log.warn('Already playing $id, cannot fade to self');
				throw 'Already playing $id, cannot fade to self';
				prevTrack.play(forceRestart, startTime, endTime);
				postTrackChange.dispatch(prev, id);
				return;
			}
			else if (prevTrack.playing)
			{
				prevTrack.fadeOut(fadeTime, function ()
				{
					postTrackChange.dispatch(prev, id);
					checkAutoDestroy(prev, prevTrack);
				});
			}
		}
		else
		{
			preTrackChange.dispatch(null, id);
		}
		
		current = id;
		nextTrack.play(forceRestart, startTime, endTime);
		nextTrack.volume = 0;
		nextTrack.fadeIn(fadeTime, onFade);
	}
	
	/**
	 * Checks whether the track is set to autoDestroy and destroys it, otherwise pauses it
	 * 
	 * @param  id     The ID of the track
	 * @param  track  The track itself
	 */
	function checkAutoDestroy(id:TrackID, track:FlxDjTrack)
	{
		if (track.autoDestroy)
		{
			track.stop();
			remove(id);
		}
		else
			track.pause();
	}
}