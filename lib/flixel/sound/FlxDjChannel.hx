package flixel.sound;

import flixel.sound.FlxSoundGroup;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.tweens.FlxTween;
using flixel.util.NullUtil;

@:nullSafety(Strict)
class FlxDjChannelRaw extends FlxSound
{
	public final syncMode:FlxDjSyncMode;
	// final parent:FlxSound;
	final parent:FlxDjTrack;
	
	public function new (parent, embeddedSound, syncMode)
	{
		this.parent = parent;
		this.syncMode = syncMode;
		super();
		loadEmbedded(embeddedSound, true);
	}
	
	override function calcTransformVolume():Float
	{
		final volume = (group != null ? group.getVolume() : 1.0) * parent.volume * _volume * _volumeAdjust;
		
		#if FLX_SOUND_SYSTEM
		if (FlxG.sound.muted)
			return 0.0;
		
		return FlxG.sound.applySoundCurve(FlxG.sound.volume * volume);
		#else
		return volume;
		#end
	}
	
	public function fadeTo(duration:Float, volume:Float, ?onComplete:()->Void)
	{
		if (fadeTween != null)
			fadeTween.cancel();
			
		fadeTween = FlxTween.num(this.volume, volume, Math.max(0.0001, duration), { onComplete: onComplete.tweenNoArg() }, volumeTween);
	}
}

@:nullSafety(Strict)
@:forward
abstract FlxDjChannel(FlxDjChannelRaw) from FlxDjChannelRaw to FlxSound
{
	public var time(get, set):Float;
	
	inline function get_time()
	{
		@:privateAccess
		final channel = this._channel;
		return channel != null ? channel.position : this.time;
	}
	
	inline function set_time(value:Float) return this.time = value;
	
	public function new (track, embeddedSound, mode)
	{
		this = new FlxDjChannelRaw(track, embeddedSound, mode);
	}
	
	public function syncTimeTo(time:Float)
	{
		if (Math.abs(this.time - time) > 20)
			this.time = time;
	}
	
	public function toString()
	{
		return '${this.volume * 100}%(${this.getActualVolume() * 100}) ${(this.time)}/${(this.endTime ?? this.length)}ms';
	}
}

enum FlxDjSyncMode
{
	/** If this finished before the main channel, it pauses until the main channel loops */
	ONCE;
	
	/** If this finished before the main channel, it plays again */
	LOOP(end:Null<Float>);
}