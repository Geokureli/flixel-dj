package flixel.sound;

import flixel.sound.FlxDjChannel;
import flixel.sound.FlxSound;
import flixel.sound.FlxSoundGroup;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.tweens.FlxTween;
import openfl.utils.ByteArray;
using flixel.util.NullUtil;


typedef FlxMultiChannelSound = FlxTypedMultiChannelSound<String>;

/**
 * A track with multiple channels, all kept in sync. Each channel has it's own volume and
 * can be faded in an out, or channels can be cross-faded from one to another
 */
@:nullSafety(Strict)
class FlxTypedMultiChannelSound<ChannelID:String> extends FlxSound
{
	/** Whether or not the sound is currently playing */
	public var playing(default, null):Bool = false;
	
	/** Whether this contains any channels */
	public var empty(get, never):Bool;
	inline function get_empty() return main == null;
	
	/** The duration of the track in milliseconds. */
	public var duration(get, never):Float;
	inline function get_duration() return main == null ? 0 : main.length;
	
	override function get_length() return main == null ? 0 : main.length;
	
	// override function get_time() return main == null ? 0 : main.time; // super is inline
	override function set_time(value:Float)
	{
		if (main != null)
		{
			main.time = value;
			syncChannels();
		}
		return 0;
	}
	
	// override function set_volume(value:Float):Float
	// {
	// 	_volume = FlxMath.bound(Volume, 0, 1);
		
	// 	for (channel in channels)
	// 		@:privateAccess
	// 		channel.updateTransform();
		
	// 	return value;
	// }
	
	override function set_pan(value:Float):Float
	{
		this.pan = value;
		for (channel in channels)
			channel.pan = value;
		
		return value;
	}
	
	function set_persist(value:Bool):Bool
	{
		this.persist = value;
		for (channel in channels)
			channel.persist = value;
		
		return value;
	}
	
	#if FLX_PITCH
	public var pitch(default, set):Float = 0.0;
	function set_pitch(value:Float):Float
	{
		this.pitch = value;
		for (channel in channels)
			channel.pitch = value;
		
		return value;
	}
	#end
	
	public final channels = new Map<ChannelID, FlxDjChannel>();
	
	var main:Null<FlxDjChannel> = null;
	
	/**
	 * Creates a new Sound
	 */
	public function new ()
	{
		super();
	}
	
	override function destroy()
	{
		super.destroy();
		
		
		main = null;
		for (channel in channels)
			channel.destroy();
		
		channels.clear();
	}
	
	override function cleanup(destroySound:Bool, resetPosition = true):Void
	{
		super.cleanup(destroySound, resetPosition);
		
		main = null;
		for (channel in channels)
			channel.cleanup(destroySound, resetPosition);
		
		channels.clear();
	}
	
	// override function play(forceRestart = false, startTime = 0.0, ?endTime) { super.play(); }
	
	override function startSound(time:Float)
	{
		super.startSound(time);
		
		for(channel in channels)
			channel.startSound(forceRestart, startTime, endTime);
	}
	
	/** Resumes the track and all of its channels */
	override function resume()
	{
		super.resume();
		
		for(channel in channels)
			channel.resume();
	}
	
	/** Pauses the track and all of its channels, while maintaining the current time */
	override function pause()
	{
		super.pause();
		
		for(channel in channels)
			channel.pause();
	}
	
	/** Stops the track and all of its channels, setting the time to 0 */
	override function stop()
	{
		super.pause();
		
		for(channel in channels)
			channel.stop();
	}
	
	override function loadEmbedded(embeddedSound, looped = false, autoDestroy = false, ?onComplete)
	{
		// super.loadEmbedded(embeddedSound, looped, autoDestroy, onComplete);
		throw "Do not call loadEmbedded, call add or addChannel";
	}
	
	override function loadByteArray(bytes, looped = false, autoDestroy = false, ?onComplete)
	{
		// return super.loadByteArray(bytes, looped, autoDestroy, onComplete);
		throw "Do not call loadByteArray, call add or addChannel";
	}
	
	override function loadStream(soundURL, looped = false, autoDestroy = false, ?onComplete, ?onLoad)
	{
		// return super.loadByteArray(bytes, looped, autoDestroy, onComplete);
		throw "Do not call loadStream, call add or addChannel";
	}
	
	/**
	 * The primary method of adding full-length channels to this track, if a channel already
	 * exists with the given `id`, it is removed and destroyed.
	 * 
	 * @param   id             The lookup id, to control this channel
	 * @param   embeddedSound  A asset string or sound object for the desired channel sound
	 * @param   volume         How loud this track will be
	 */
	public function add(id:ChannelID, embeddedSound:FlxSoundAsset, volume = 1.0)
	{
		return addHelper(id, embeddedSound, volume, ONCE);
	}
	
	/**
	 * Useful for adding channels shorter than the track's duration by some integer factor.
	 * This channel will repeat multiple times before the entire track finishes its normal loop
	 * 
	 * @param   id             Lookup id for the channel, used for fading in and out, and removing
	 * @param   embeddedSound  A asset string or sound object for the desired channel sound
	 * @param   volume         How loud this channel will be
	 * @param   endTime        Optional custom length for the channel
	 */
	public function addSubLoop(id:ChannelID, embeddedSound:FlxSoundAsset, volume = 1.0, ?endTime:Float)
	{
		return addHelper(id, embeddedSound, volume, LOOP(endTime));
	}
	
	inline function addHelper(id:ChannelID, embeddedSound:FlxSoundAsset, volume = 1.0, syncMode = ONCE)
	{
		final channel = new FlxDjChannel(cast this, embeddedSound, syncMode);
		channel.volume = volume;
		return addChannel(id, channel);
	}
	
	/**
	 * An internal method to add the target channel to this track, if a channel already exists with
	 * the given `id`, it is removed and destroyed.
	 * 
	 * **NOTE:** Unless you know what you're doing, use `add` or `addSubLoop` instead.
	 * 
	 * @param id       Lookup id for the channel, used for fading in and out, and removing
	 * @param channel  The channel to add
	 */
	public function addChannel(id:ChannelID, channel:FlxDjChannel)
	{
		if (has(id))
			remove(id);
		
		group.add(channel);
		channels[id] = channel;
		channel.pan = this.pan;
		channel.persist = this.persist;
		
		final wasEmpty = empty;
		if (wasEmpty || channel.length > assertMain().length)
			main = channel;
		
		if (playing)
		{
			if (wasEmpty)
				channel.play(true);
			else
				channel.play(true, main.sure().time, main.sure().endTime);
		}
		else
			channel.stop();
	}
	
	/**
	 * Removes and optionally destroys the channel with the given `id`. If the channel has the
	 * highest `duration`, the track's `duration` will now match the next longest channel
	 */
	public function remove(id:ChannelID, destroy = true):Null<FlxDjChannel>
	{
		if (has(id))
		{
			final channel = channels[id].sure();
			removeHelper(id, channel, destroy);
			if (main == channel)
			{
				// Select new main
				for (channel in channels)
				{
					if (main == null || channel.length > main.length)
						main == channel;
				}
			}
			
			return channel;
		}
		
		FlxG.log.warn('No channel with id: $id');
		return null;
	}
	
	function removeHelper(id:ChannelID, channel:FlxDjChannel, destroy:Bool)
	{
		group.remove(channel);
		channels.remove(id);
		if (destroy)
			channel.destroy();
	}
	
	/** Whether the track contains a channel with the target `id` */
	inline public function has(id:ChannelID)
	{
		return channels.exists(id);
	}
	
	/** Returns the channel with the given `id`, if it exists, otherwise returns `null` */
	inline public function get(id:ChannelID):Null<FlxDjChannel>
	{
		return channels[id];
	}
	
	/** Returns the channel with the given `id`, or throws an error, if none exists */
	public function assertGet(id:Null<ChannelID>):FlxDjChannel
	{
		if (id != null && has(id))
			return channels[id].sure();
		
		throw 'No channel with id: $id';
	}
	
	inline function assertMain():FlxDjChannel
	{
		if (main != null)
			return main;
		
		throw 'Track has no main';
	}
	
	override function updateTransform()
	{
		super.updateTransform();
		
		for (channel in channels)
			channel.updateTransform();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		for (channel in channels)
			channel.update(elapsed);
		
		if (!playing)
			return;
		
		syncChannels();
	}
	
	function syncChannels()
	{
		for (id => channel in channels)
		{
			final main = assertMain();
			if (channel == main)
			{
				_time = main.time;
				continue;
			}
			
			if (main.time <= channel.length)
			{
				if (channel.playing)
					channel.syncTimeTo(main.time);
				else
					channel.play(true, main.time, main.endTime);
			}
			else
			{
				switch channel.syncMode
				{
					case ONCE:
						channel.pause();
					case LOOP(end):
						channel.syncTimeTo(main.time % (end ?? channel.length));
				}
			}
		}
	}
	
	/**
	 * Sets the desired channel's to the target volume. If there is no channel associated with
	 * the id, an error is thrown
	 */
	public function getChannelVolume(id:ChannelID)
	{
		return assertGet(id).volume;
	}
	
	/**
	 * Sets the desired channel's to the target volume. If there is no channel associated with
	 * the id, an error is thrown
	 */
	public function setChannelVolume(id:ChannelID, volume:Float)
	{
		assertGet(id).volume = volume;
	}
	
	override function fadeIn(duration:Float, from:Float, to:Float, ?onComplete:()->Void)
	{
		if (!playing)
			play();
		
		volume = from;
		fadeToHelper(duration, to, onComplete);
	}
	
	override function fadeOut(duration:Float, from:Float, to:Float, ?onComplete:()->Void)
	{
		volume = from;
		fadeToHelper(duration, to, onComplete);
	}
	
	/**
	 * Fades this track's volume to the desired. If the track isn't playing, `play()` is called
	 * 
	 * @param   duration    The time it takes, in seconds to fade the channel
	 * @param   volume      The desired volume of the track
	 * @param   onComplete  Called when the fade is complete
	 */
	public function fadeTo(duration:Float, volume:Float, ?onComplete:()->Void)
	{
		fadeToHelper(duration, volume, onComplete.tweenNoArg());
	}
	
	function fadeToHelper(duration:Float, volume:Float, ?onComplete:FlxTween->Void)
	{
		if (fadeTween != null)
			fadeTween.cancel();
		
		fadeTween = FlxTween.num(this.volume, volume, duration, { onComplete: onComplete }, volumeTween);
	}
	
	/**
	 * Fades the channel's volume up to full
	 * 
	 * @param   id          The lookup id of the channel, if no channel matches an error is thrown
	 * @param   duration    The time it takes, in seconds to fade the channel
	 * @param   onComplete  Called when the fade is complete
	 */
	inline public function fadeChannelIn(id:ChannelID, duration:Float, ?onComplete:()->Void)
	{
		fadeChannelTo(id, duration, 1.0, onComplete);
	}
	
	/**
	 * Fades the channel's volume down to zero
	 * 
	 * @param   id          The lookup id of the channel, if no channel matches an error is thrown
	 * @param   duration    The time it takes, in seconds to fade the channel
	 * @param   onComplete  Called when the fade is complete
	 */
	inline public function fadeChannelOut(id:ChannelID, duration:Float, ?onComplete:()->Void)
	{
		fadeChannelTo(id, duration, 0.0, onComplete);
	}
	
	/**
	 * Fades the channel's volume down to zero
	 * 
	 * @param   id          The lookup id of the channel, if no channel matches an error is thrown
	 * @param   duration    The time it takes, in seconds to fade the channel
	 * @param   volume      The desired volume of the channel
	 * @param   onComplete  Called when the fade is complete
	 */
	public function fadeChannelTo(id:ChannelID, duration:Float, volume:Float, ?onComplete:()->Void)
	{
		assertGet(id).fadeTo(duration, volume, onComplete);
	}
	
	/**
	 * Fades all channels' volumes down to zero, while fading this to the target volume
	 * @param   id          The lookup id of the channel
	 * @param   duration    The time it takes, in seconds to focus the channel
	 * @param   volume      The desired volume of the focused channel
	 * @param   onComplete  Called when the fade is complete
	 */
	public function fadeChannelFocus(id:ChannelID, duration:Float, volume:Float = 1.0, ?onComplete:()->Void)
	{
		final target = assertGet(id);
		target.fadeTo(duration, volume, onComplete);
		for (sound in channels)
		{
			if (sound != target && sound.volume > 0.0)
				sound.fadeTo(duration, 0);
		}
	}
	
	override function toString():String
	{
		return 'FlxMultiChannelSound: [${[for (id=>channel in channels) '$id => $channel']}]';
	}
}