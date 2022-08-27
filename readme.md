# literally anime
Scripts for video + audio + subtitle playback in StepMania 5.


## about

![twitter thread](https://i.imgur.com/rfrMu2fl.png)
![I am her cat](https://i.imgur.com/3jVjNJXl.png)


## how to use

You can't yet, not really.  This is still a work-in-progress.

... but it will probably involve using ffmpeg to separate a single video file into three distinct files:

  * video file
  * audio file
  * subtitle file

Placing those three files in `./media`, and editing [anime.ini](./anime.ini) to match.
  
For ffmpeg usage, see: <https://stackoverflow.com/a/32925753>


## ssc file

### required .ssc fields

Two fields in your ssc field must be set appropriately for this to work.

The `#LASTSECONDHINT` field should match the duration of the video, in seconds.  If your video is 5 minutes and 25 seconds long, use `#LASTSECONDHINT:325.000;`

The `FGCHANGES` field should be set to `#FGCHANGES:0.000=./scripts/AnimeFGCHANGES.lua=1.000=0=0=0=StretchNoLoop====,;`

---

### optional-but-nice .ssc fields

You can provide preview audio (to be played in ScreenSelectMusic but not in ScreenGameplay) by using two `#MUSIC` tags.

Specify `#MUSIC:your-song-here.ogg;` as general audio so that StepMania plays it as preview music in ScreenSelectMusic.

Specify `#MUSIC:silence.ogg;` as stepchart-specific audio so that StepMania does not play any extraneous music during Gameplay.

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