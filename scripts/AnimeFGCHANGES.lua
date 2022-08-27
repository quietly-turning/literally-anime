-- ------------------------------------------------------
-- load helpers, get assets

local base_path = GAMESTATE:GetCurrentSong():GetSongDir()
local helpers = dofile(base_path.."scripts/AnimeHelpers.lua")
local assets  = helpers.GetAssets() 
if not assets then return Def.Actor({}) end

-- ------------------------------------------------------
-- provide sensible-ish values by default, but allow user-provided values in anime.ini to override

local font_zoom = assets.FontZoom or 0.735
local subtitle_color        = assets.TextColor   or {1,1,1,1} -- white text by default
local subtitle_stroke_color = assets.StrokeColor or {0,0,0,1} -- black stroke around text by default

-- ------------------------------------------------------
-- these values are hardcoded for now

local font_path = base_path .. "fonts/Work Sans 40px/Semibold/_work sans semibold 40px.ini"
local font_size = 40
local max_subt_width = (_screen.w-30) / font_zoom

-- ------------------------------------------------------

local subtitle_data

if assets.SubtitleFile then
   -- get parser
   local ParseFile = dofile(base_path.."scripts/subtitle-parsers/ass-parser.lua")
   -- parse subtitle file, get data
   subtitle_data = ParseFile(assets.SubtitleFile)
end

-- ------------------------------------------------------
-- custom inputhandler is used to pause playback when the START button is tapped

local time_at_start, time_at_pause_start
local time_spent_paused = 0
local subtitle_ref, audio_ref, video_ref
local paused = false

local inputhandler = function(event)
   if not event or not event.PlayerNumber or not event.button then
      return false
   end

   if event.type == "InputEventType_Release" then
      if event.GameButton == "Start" then
         -- invert boolean value for paused
         paused = not paused

         if paused then
            video_ref:pause()
            audio_ref:pause(true)
            time_at_pause_start = (GetTimeSinceStart() - time_at_start)
            SCREENMAN:GetTopScreen():PauseGame(true)
            -- TODO: show "paused, press &START; to continue" help text when paused
         else
            video_ref:play()
            audio_ref:pause(false)
            time_spent_paused = time_spent_paused + (GetTimeSinceStart() - time_at_start - time_at_pause_start)
            SCREENMAN:GetTopScreen():PauseGame(false)
         end
      end
   end
end

-- ------------------------------------------------------
-- custom Update function is used to keep track of which subtitle to show

local subtitle_index = 1
local set = false  -- when false, the subtitle_actor has an empty string as its text

local Update = function()
   -- check reasons we shouldn't update, first   

   -- haven't started playing yet
   if type(time_at_start)~="number" or type(time_spent_paused)~="number" then
      return false
   end

   -- paused
   if paused then return false end
   if not assets.SubtitleFile then return false end

   -- no more subtitles to show
   if not (subtitle_data[subtitle_index] and subtitle_data[subtitle_index].Start and subtitle_data[subtitle_index].End) then
      return false
   end
   
   -- ------------------------

   local time = GetTimeSinceStart() - time_at_start - time_spent_paused

   if not set and time >= subtitle_data[subtitle_index].Start then
      subtitle_ref:settext(subtitle_data[subtitle_index].Text)
      set = true

   elseif set and time >= subtitle_data[subtitle_index].End then
      subtitle_ref:settext("")
      set = false
      subtitle_index = subtitle_index + 1
   end
end


-- ------------------------------------------------------

local af = Def.ActorFrame{}

-- sleep for a Very Long While so that the FGCHANGE stays alive when nothing else is tweening
af[#af+1] = Def.Actor({ InitCommand=function(self) self:sleep(999999) end })

-- black Quad serving two purposes
-- 1. the initial fullscreen-covering fade-to-black
-- 2. fullscreen dark backdrop for letter/pillar-boxing needs in case the video file
--    is not the same aspect ratio as StepMania
af[#af+1] = Def.Quad{
   InitCommand=function(self) self:FullScreen():diffuse(0,0,0,0) end,
   OnCommand=function(self)
      -- fade Quad in, covering the UI, giving an appearance of fading to black
      self:smooth(0.5):diffusealpha(1)
      self:queuecommand("Next")
   end,
   NextCommand=function(self)
      self:GetParent():queuecommand("HideUI"):queuecommand("UnhideVideo")
   end
}

-- ------------------------------------------------------
-- reference: https://quietly-turning.github.io/Lua-For-SM5/LuaAPI#Actors-ActorSound
local audio_actor = Def.Sound{ File=assets.AudioFile }
audio_actor.InitCommand=function(self) audio_ref = self end

-- reference: https://quietly-turning.github.io/Lua-For-SM5/LuaAPI#Actors-Sprite
local video_actor = Def.Sprite{ Texture=assets.VideoFile}

-- reference: https://quietly-turning.github.io/Lua-For-SM5/LuaAPI#Actors-BitmapText
local subtitle_actor = Def.BitmapText{ File=font_path }

-- ------------------------------------------------------

af.HideUICommand=function(self)
   helpers.HideUI()
   self:queuecommand("AttachInputHandler")
end

af.AttachInputHandlerCommand=function(self)
   local topscreen = SCREENMAN:GetTopScreen()
   if topscreen and inputhandler then
      topscreen:AddInputCallback( inputhandler )
   end
   self:queuecommand("Play")
end

af.PlayCommand=function(self)
   -- Let's do our best to start video and audio playback simultaneously!
   -- Having refs available here and calling play() directly on one, then the other,
   -- both from within the scope of this ActorFrame's PlayCommand is probably 
   -- more reliable than something like 
   --    self:queuecommand("StartPlayback")
   -- where the video_actor and audio_actor  both have their own
   -- custom StartPlaybackCommand() functions like
   --    StartPlaybackCommand=function(self) self:play() end
   -- In general, queuecommnd's timing is unreliable when precision is important.
   video_ref:play()
   audio_ref:play()
   
   
   time_at_start = GetTimeSinceStart()
   self:SetUpdateFunction( Update )
end

-- ------------------------------------------------------

video_actor.InitCommand=function(self)
   video_ref = self

   -- don't start playing yet
   self:pause()
   
   -- hide at init and set opacity to 0
   self:visible(false):diffusealpha(0)
   self:Center()

   -- scale the video to use as much screen as possible
   -- without distorting or drawing beyond borders
   -- this may introduce letterboxing/pillarboxing
   -- depending on the video files and screen aspect ratio
   local texture = self:GetTexture()
   local img_w = texture:GetImageWidth()
   local img_h = texture:GetImageHeight()

   local xscale = _screen.w / img_w
   local yscale = _screen.h / img_h

   if img_w > img_h then
      if xscale < 1 then
         self:zoom(yscale)
      else
         self:zoomy(yscale)
      end
   else
      if yscale < 1 then
         self:zoom(xscale)
      else
         self:zoomx(xscale)
      end
   end
end

video_actor.UnhideVideoCommand=function(self)
   -- start drawing the video (drawing ≠ playing); its opacity will still be 0
   self:visible(true)
   -- tween the video's opacity up to 1
   self:smooth(0.333):diffusealpha(1):queuecommand("FadeDone") 
end

-- ------------------------------------------------------



-- ------------------------------------------------------

subtitle_actor.InitCommand=function(self)
   subtitle_ref = self
   self:Center():wrapwidthpixels(max_subt_width):zoom(font_zoom)
   self:vertalign(bottom):y(_screen.h - 24)
   self:diffuse(subtitle_color):strokecolor(subtitle_stroke_color)
end

-- ------------------------------------------------------
-- add 

af[#af+1] = video_actor
af[#af+1] = audio_actor
af[#af+1] = subtitle_actor

return af