package flixel.util;

import flixel.tweens.FlxTween;

@:nullSafety(Strict)

class NullUtil
{
	public static inline function sure<T>(obj:Null<T>):T
	{
		return cast obj;
	}
	
	public static function tweenNoArg(f:Null<()->Void>):Null<TweenCallback>
	{
		return f == null ? null : (_)->sure(f)();
	}
}