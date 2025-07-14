package flixel.sound;

import flixel.sound.FlxSoundGroup;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.tweens.FlxTween;

typedef FlxDjTrack = FlxTypedDjTrack<String>;

/**
 * A track with multiple channels, all kept in sync. Each channel has it's own volume and
 * can be faded in an out, or channels can be cross-faded from one to another
 */
class FlxTypedDjTrack<ID:String> extends flixel.FlxBasic
{
	/** The group controlling and updating these sounds */
	final channels:FlxChannelGroup;
	
	/** Whether or not the sound is currently playing */
	public var playing(default, null):Bool = false;
	
	/** Whether this contains any channels */
	public var empty(get, never):Bool;
	inline function get_empty() return channels.length == 0;
	
	/** 
	 * The position in runtime of the music playback in milliseconds.
	 * If set while paused, changes only come into effect after a `resume()` call
	 */
	public var time(default, null):Bool;
	
	// TODO: pan, pitch, length
	
	/**
	 * The volume of this track, all channels' effective volumes are scaled by this
	 */
	public var volume(get, set):Float;
	inline function get_volume() return channels.volume;
	inline function set_volume(value:Float) return channels.volume = value;
	
	final byId = new Map<ID, FlxDjChannel>();
	final syncModes = new Map<ID, FlxDjSyncMode>();
	
	/**
	 * Creates a new DJ
	 * 
	 * @param   group  The group controlling and updating these sounds, if `null`,
	 * `FlxG.sound.defaultMusicGroup` is used
	 */
	public function new (?group:FlxSoundGroup, autoPlay = true)
	{
		this.channels = group ?? FlxG.sound.defaultMusicGroup;
		
		super();
		
		if (autoPlay)
			play();
	}
	
	override function destroy()
	{
		super.destroy();
		
		clear();
	}
	
	/**
	 * Removes and destroys all channels
	 */
	public function clear()
	{
		playing = false;
		
		byId.clear();
		while (channels.length > 0)
		{
			final channel = channels.list[0];
			channel.destroy();
			channels.remove(channel);
		}
	}
	
	public function play(forceRestart = false, startTime = 0.0, ?endTime)
	{
		playing = true;
		channels.play(forceRestart, startTime, endTime);
	}
	
	public function pause()
	{
		playing = false;
		channels.pause();
	}
	
	public function stop()
	{
		playing = false;
		channels.stop();
	}
	
	public function add(id:ID, embeddedSound:FlxSoundAsset, volume = 1.0)
	{
		addHelper(id, embeddedSound, volume, ONCE);
	}
	
	public function addSubLoop(id:ID, embeddedSound:FlxSoundAsset, volume = 1.0, ?endTime:Float)
	{
		addHelper(id, embeddedSound, volume, LOOP(endTime));
	}
	
	
	public function addHelper(id:ID, embeddedSound:FlxSoundAsset, volume = 1.0, syncMode = ONCE)
	{
		if (has(id))
			remove(id);
		
		final main = channels.getMain();
		final channel = channels.addAsset(embeddedSound);
		byId[id] = channel;
		channels.add(channel);
		channel.volume = volume;
		
		if (playing)
		{
			if (main != null)
				channel.play(true, main.time, main.endTime);
			else
				channel.play(true);
		}
		else
			channel.stop();
		
		syncModes[id] = syncMode;
	}
	
	public function remove(id:ID)
	{
		if (has(id))
		{
			channels.remove(byId[id]);
			byId.remove(id);
			syncModes.remove(id);
		}
		else
			FlxG.log.warn('No channel with id: $id');
	}
	
	inline public function has(id:ID)
	{
		return byId.exists(id);
	}
	
	inline function assert(id:ID)
	{
		if (!has(id))
			throw 'No channel with id: $id';
		
		return byId[id];
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		
		final numSounds = channels.length;
		if (numSounds > 0)
		{
			final main = channels.getMain();
			final time = main.time;
			for (id => channel in byId)
			{
				channel.update(elapsed);
				if (channel == main)
					continue;
				
				if (time <= channel.length)
				{
					if (channel.playing)
						channel.syncTimeTo(time);
					else
						channel.play(true, time, main.endTime);
				}
				else
				{
					switch syncModes[id]
					{
						case ONCE:
							channel.pause();
						case LOOP(end):
							channel.syncTimeTo(time % (end ?? channel.length));
					}
				}
			}
		}
	}
	
	public function getChannelVolume(id:ID)
	{
		return assert(id).volume;
	}
	
	public function setChannelVolume(id:ID, volume:Float)
	{
		assert(id).volume = volume;
	}
	
	public function fadeIn(id:ID, duration:Float, volume:Float = 1.0, ?onComplete:()->Void)
	{
		assert(id).fadeTo(duration, volume, onComplete);
	}
	
	public function fadeOut(id:ID, duration:Float, volume:Float = 0.0, ?onComplete:()->Void)
	{
		assert(id).fadeTo(duration, volume, onComplete);
	}
	
	public function fadeFullFocus(id:ID, duration:Float, volume:Float = 1.0, ?onComplete:()->Void)
	{
		final target = assert(id);
		target.fadeTo(duration, volume, onComplete);
		for (sound in channels)
		{
			if (sound != target && sound.volume > 0.0)
				sound.fadeTo(duration, 0);
		}
	}
	
	override function draw() {}
	
	override function toString():String
	{
		return 'FlxDj: [${[for (id=>channel in byId) '$id => $channel']}]';
	}
}

@:forward
abstract FlxDjChannel(FlxSound) from FlxSound to FlxSound
{
	public var time(get, set):Float;
	
	inline function get_time()
	{
		@:privateAccess
		return this._channel.position;
	}
	
	inline function set_time(value:Float) return this.time = value;
	
	public function syncTimeTo(time:Float)
	{
		if (Math.abs(this.time - time) > 20)
			this.time = time;
	}
	
	public function fadeTo(duration:Float, volume:Float, ?onComplete:()->Void)
	{
		this.fadeIn(Math.max(0.0001, duration), this.volume, volume, callbackHelper(onComplete));
	}
	
	/**
	 * Converts a callback to a tween callback
	 */
	inline function callbackHelper(callback:Null<()->Void>):Null<(FlxTween)->Void>
	{
		return callback == null ? null : (_)->callback();
	}
	
	public function toString()
	{
		return '${(this.time)}/${(this.endTime ?? this.length)}ms';
	}
}

@:forward
abstract FlxChannelGroup(FlxSoundGroup) to FlxSoundGroup from FlxSoundGroup
{
	public var list(get, never):Array<FlxDjChannel>;
	inline function get_list() return cast this.sounds;
	
	public var empty(get, never):Bool;
	inline function get_empty():Bool return length == 0;
	
	public var length(get, never):Int;
	inline function get_length():Int return list.length;
	
	inline public function iterator()
	{
		return list.iterator();
	}
	
	inline public function forEach(f:(FlxDjChannel)->Void)
	{
		for (channel in list)
			f(channel);
	}
	
	inline public function getMain():Null<FlxDjChannel>
	{
		return empty ? null : list[0];
	}
	
	public function play(forceRestart = false, startTime = 0.0, ?endTime)
	{
		forEach((channel)->channel.play(forceRestart, startTime, endTime));
	}
	
	public function pause()
	{
		forEach((channel)->channel.pause());
	}
	
	public function stop()
	{
		forEach((channel)->channel.pause());
	}
	
	inline public function addAsset(embeddedSound:FlxSoundAsset)
	{
		final channel = FlxG.sound.list.recycle(FlxSound).loadEmbedded(embeddedSound, true);
		return add(channel);
	}
	
	inline public function add(channel:FlxDjChannel)
	{
		// key the longest as the main
		if (length > 0 && channel.length > getMain().length)
			this.sounds.unshift(channel);
		else
			this.sounds.push(channel);
		
		@:bypassAccessor
		channel.group = this;
		@:privateAccess
		channel.updateTransform();
		return channel;
	}
}

enum FlxDjSyncMode
{
	/** If this finished before the main channel, it pauses until the main channel loops */
	ONCE;
	
	/** If this finished before the main channel, it plays again */
	LOOP(end:Null<Float>);
}