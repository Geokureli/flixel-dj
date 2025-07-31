package flixel.util;

import flixel.tweens.FlxTween;

@:nullSafety(Strict)
class NullUtil
{
	public static inline function sure<T>(obj:Null<T>):T
	{
		return @:nullSafety(Off) (obj:T);
	}
	
	public static function tweenNoArg(f:Null<()->Void>):Null<TweenCallback>
	{
		return f != null ? (_)->sure(f)(): null;
	}
}