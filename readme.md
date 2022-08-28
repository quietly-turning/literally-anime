# literally anime
scripts for video + audio + subtitle playback in StepMania 5


## about

![twitter thread](https://i.imgur.com/rfrMu2fh.png)

![I am her cat](https://i.imgur.com/3jVjNJXh.png)


## how to use

You can't yet, not really.  This is still a work-in-progress.

... but it will probably involve using ffmpeg to separate a single video file into three distinct files:

  * video file
  * audio file
  * subtitle file

placing those three files in `./media`, and editing [anime.ini](./anime.ini) to match.
  
For ffmpeg usage, see: <https://stackoverflow.com/a/32925753>


## ssc file

This works using StepMania's `FGCHANGES` scripting capabilities during gameplay to hide your theme's normal UI, and instead play a video with accompanying audio and subtitles.

You'll need to create a stepchart in your .ssc file, but you don't need to write any notes/arrows for it.

Check out the *example ssc file* below. Feel free to copy/paste it into an empty plaintext file and edit the fields you want, like `#TITLE`, `#SUBTITLE`, `#ARTIST`, `#TITLETRANSLIT`, etc.

---

### required .ssc fields

Two fields in your ssc field must be set appropriately for this to work.

Set `#LASTSECONDHINT` to the duration of your video in seconds.  For example, if your video is 5 minutes and 25 seconds long, use 
```
#LASTSECONDHINT:325.000;
```

Set `#FGCHANGES` to exactly:
```
#FGCHANGES:0.000=./scripts/AnimeFGCHANGES.lua=1.000=0=0=0=StretchNoLoop====;
```

This is needed to load the scripts that will play the video.

---

### optional-but-nice .ssc fields

#### preview audio for ScreenSelectMusic

You can provide preview audio (to be played in ScreenSelectMusic but not in ScreenGameplay) by using two `#MUSIC` tags.

Specify `#MUSIC:your-song-here.ogg;` as general audio so that StepMania plays it as preview music in ScreenSelectMusic.

Then, lower in the ssc file with the fields for your stepchart, specify `#MUSIC:silence.ogg;` as stepchart-specific audio so that StepMania does not play any extraneous music during Gameplay.

## example .ssc file

```
#VERSION:0.83;
#TITLE:彼女と彼女の猫;
#SUBTITLE:She and Her Cat;
#ARTIST:Makoto Shinkai;
#TITLETRANSLIT:Kanojo to Kanojo no Neko;
#SUBTITLETRANSLIT:;
#ARTISTTRANSLIT:;
#GENRE:literally anime;
#ORIGIN:;
#CREDIT:;
#BANNER:_bn She and Her Cat.png;
#BACKGROUND:;
#PREVIEWVID:;
#JACKET:;
#CDIMAGE:;
#DISCIMAGE:;
#LYRICSPATH:;
#CDTITLE:;
#MUSIC:Theme of She and Her Cat.ogg;
#OFFSET:0.000000;
#SAMPLESTART:0.000000;
#SAMPLELENGTH:1.000000;
#SELECTABLE:YES;
#BPMS:0.000=120.000;
#STOPS:;
#DELAYS:;
#WARPS:;
#TIMESIGNATURES:0.000=4=4;
#TICKCOUNTS:0.000=4;
#COMBOS:0.000=1;
#SPEEDS:0.000=1.000=0.000=0;
#SCROLLS:0.000=1.000;
#FAKES:;
#LABELS:0.000=Song Start;
#LASTSECONDHINT:284.237000;
#BGCHANGES:;
#FGCHANGES:0.000=./scripts/AnimeFGCHANGES.lua=1.000=0=0=0=StretchNoLoop====,
;
#KEYSOUNDS:;
#ATTACKS:
;

//---------------dance-single - ----------------
#NOTEDATA:;
#CHARTNAME:;
#STEPSTYPE:dance-single;
#DESCRIPTION:;
#CHARTSTYLE:;
#MUSIC:silence.ogg;
#DIFFICULTY:Beginner;
#METER:1;
#RADARVALUES:0.000000,0.000000,0.000000,0.000000,0.000000,0.000000,0.000000,0.000000,0.000000,0.000000,0.000000,0.000000,0.000000,0.000000,0.000000,0.000000,0.000000,0.000000,0.000000,0.000000,0.000000,0.000000,0.000000,0.000000,0.000000,0.000000,0.000000,0.000000;
#CREDIT:;
#NOTES:
0000
0000
0000
0000
;
```


## ~~frequently asked~~ questions

### Why three separate files?

StepMania's scripting API doesn't provide a way to play audio contained in video files.  This makes sense if you think about its roots being a DDR simulator.  The primary use-case for videos was in the background of gameplay, and to always be optional.

The consequence for this project is that you'll need distinct audio and video files.

StepMania also doesn't provide any support for reading subtitle data that's contained in a video file, but that's pretty reasonable. :)

### What subtitle formats are supported?

#### .ass

The [Advanced SubStation Alpha](https://en.wikipedia.org/wiki/SubStation_Alpha) format is supported to a limited extent.  Text can be colored and positioned.  Due to [how deep that rabbit hole goes](http://www.tcax.org/docs/ass-specs.htm), and how complicated it would be to replicate all of it in StepMania, full .ass support is unlikely to happen.

#### .srt

The [SRT Subtitles](https://www.matroska.org/technical/subtitles.html#srt-subtitles) format is **not** supported yet, but the format looks pretty straightforward, so I plan to get to it soon.