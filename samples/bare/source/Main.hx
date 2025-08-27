package;

class Main extends openfl.display.Sprite
{
	public function new()
	{
		super();
		// addChild(new flixel.FlxGame(PlayState.new));
		addChild(new flixel.FlxGame(LoadState.new));
	}
}