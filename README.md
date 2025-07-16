# Flixel DJ
A multi-track and multi-channel music manager for HaxeFlixel.

## Multi-Channel Tracks
Use a `FlxDjTrack` to manage multiple `FlxSounds`, which all share the same timing as well as other
properties like pan, pitch and a global volume multiplier. Channels are keyed by a lookup string,
which is then used to control or remove individual channels. To use a specific enum abstract over
`String` use `FlxTypedDjTrack<MyStringType>`.

### Channel Syncing
The following shows a basic example of adding multiple channels to a track:
```haxe
final track = new FlxDjTrack();
// play the track at 90% volume
track.volume = 0.9;
// add a drum track at full volume
track.add("drums", "assets/music/drums.ogg");
// play at 0.8 volume compared to the rest
track.add("trumpet", "assets/music/trumpet.ogg", 0.8); // (0.9 * 0.8 = 0.72 effective volume)
// start the track from the beginning
track.play();
```

### Channel Syncing
For best results, all channels should have the same `duration`. If a track contains channels of
varying lengths, the track's `duration` will be determined by the longest channel, called the
"main" channel, all shorter channels will be silent once they finish. Tracks are synced with the
main channel each update, if they stray too far, they are set back to the main channel's time.

### Sublooping Channels
Channels can have a length shorter than the main channel, so that they loop various times, before
the main channel finishes its loop. This example uses `addSubLoop` with the `endTime` arg to make
the drum track loop 8 times for each time the main track completes a single loop.
```haxe
final track = new FlxDjTrack();
track.add("trumpet", "assets/music/trumpet.ogg");
track.addSubLoop("drums", "assets/music/drums.ogg", track.length / 8.0);
track.play();
```
If a subloop's length is already shorter than the main track by some whole number factor,
the `endTime` can be ommitted and the channel's entire length will be used. If the subloop's
`endTime` is not a whole number factor of the track length, it will be cut off part way through its
loop every time the track completes a loop.

## Multi-Track DJing
Use a `FlxDJ` to manage multiple tracks. Djs will automatically play, pause, resume and fade tracks
to ensure only one track is playing at a time. 

### Adding and Switching Tracks
Similarly to `FlxDjTrack`'s channel ids, djs manage tracks via a string key. The following is an
example of adding tracks to a dj and using the dj to control them.
```haxe
final dj = new FlxDJ();

// create track 1
final track1 = new FlxDjTrack()
track1.add("intruments", "assets/songs/fresh/inst.ogg");
track1.add("bf", "assets/songs/fresh/voices-bf.ogg");
track1.add("dad", "assets/songs/fresh/voices-dad.ogg");
// add it to the dj
dj.addTrack("Fresh", track1);

// create track 2
final track2 = new FlxDjTrack()
track1.add("intruments", "assets/songs/fresh/inst-erect.ogg");
track1.add("bf", "assets/songs/fresh/voices-bf-erect.ogg");
track1.add("dad", "assets/songs/fresh/voices-dad-erect.ogg");
// add it to the dj
dj.addTrack("Fresh-Erect", track1);

// play track 1
dj.play("Fresh");
// wait 20 seconds then fade to track 2 in 0.5 seconds
FlxTimer.wait(20, ()->dj.fadeTrackTo("Fresh-Erect", 0.5));
```

Tracks do not need to be managed by DJ, they can be created, played, faded in and out and paused
individually.

## TODO:
- [ ] Change `FlxDjTrack` to `FlxMultiChannelSound` which extends `FlxSound`