-- if you contribute, please tick up the version number :)
local helpers = {
    version = "1.0",
    name    = "AnimeHelpers",
    contributors = {
        "quietly-turning",
    }
}

-- ------------------------------------------------------

local supported_subtitle_formats = { "srt", "ass "}

-- ------------------------------------------------------
-- iterates over a numerically-indexed table (haystack) until a desired value (needle) is found
-- if found, return the index (number) of the desired value within the table
-- if not found, return nil

helpers.FindInTable = function(needle, haystack)
	for i = 1, #haystack do
		if needle == haystack[i] then
			return i
		end
	end
	return nil
end

-- ------------------------------------------------------
-- based on global split() from _fallback/Scripts/00 init.lua
-- hackishly modified to include a numeric "stop" value
-- as in: stop splitting the provided `text` if you've already split `stop` number of times

helpers.split = function(delimiter, text, stop)
   local list = {}
   local pos = 1

   while 1 do
      local first,last = string.find(text, delimiter, pos)
      if first then
         table.insert(list, string.sub(text, pos, first-1))
         pos = last+1
         -- if we have a stop value and have reach our limit of splits
         if stop and (#list >= stop-1) then
            -- insert the remaining string until its end and break
            table.insert(list, string.sub(text, pos))
            break
         end
      else
         table.insert(list, string.sub(text, pos))
         break
      end
   end
   return list
end

-- ------------------------------------------------------
-- GetAssets()

helpers.GetAssets = function()

  local base_path = GAMESTATE:GetCurrentSong():GetSongDir()
  local ini_file = nil

  -- find anime.ini, accounting for user variation like "Anime.ini" or "anime.INI"
  for filename in ivalues(FILEMAN:GetDirListing(base_path)) do
    if filename:match(helpers.MixedCasePattern("anime.ini")) then
      ini_path = base_path..filename
      break
    end
  end

  if not ini_path then
    lua.ReportScriptError("\n❌ Couldn't find any \"anime.ini\" file in " .. base_path .. ".\nGiving up. :(\n")
    return Def.Actor({})
  end

  -- find the [media] section in anime.ini
  local ini = IniFile.ReadFile(ini_path)
  local anime_section_found = type(ini.media)=="table"
  if not anime_section_found then
    lua.ReportScriptError("\n✅ Found \"anime.ini\"\n❌Couldn't find a [media] section in anime.ini.\nGiving up. :(\n")
    return Def.Actor({})
  end

  local anime_section = ini.media
  -- find "VideoFile=something"  "AudioFile=something"  and  "SubtitleFile=something"  lines in anime.ini
  local video_section_found    = type(anime_section.VideoFile)=="string"
  local audio_section_found    = type(anime_section.AudioFile)=="string"
  local subtitle_section_found = type(anime_section.SubtitleFile)=="string"

  -- ensure that the files specified are included with this stepchart
  local video_file_found    = video_section_found    and FILEMAN:DoesFileExist(base_path .. anime_section.VideoFile)
  local audio_file_found    = audio_section_found    and FILEMAN:DoesFileExist(base_path .. anime_section.AudioFile)
  local subtitle_file_found = subtitle_section_found and FILEMAN:DoesFileExist(base_path .. anime_section.SubtitleFile)

  --get subtitle file extension
  local subtitle_extension = anime_section.SubtitleFile:match("%.(.+)$")
  -- only .srt and .ass are supported
  local subtitle_format_supported = subtitle_section_found and table.search(supported_subtitle_formats, subtitle_extension)


  -- if the video or audio files can't be found, let the user know and don't proceed
  -- a subtitle file is optional, but if the user specified a subtitle file that can't be found, let them know and don't proceed
  if (not video_section_found) or (not audio_section_found) or (not video_file_found) or (not audio_file_found) or (subtitle_section_found and subtitle_file_found==false) then
    local error = "INI FILE\n   ✅ Found \"anime.ini\"\n   ✅ Found an [anime] section in anime.ini"

    -- video
    error = error .. (video_section_found and "\n\nVIDEO\n   ✅ Found a \"VideoFile=\" line" or "   ❌ Could not find a \"VideoFile=\" line")
    if video_section_found then
      error = error .. (video_file_found and ("\n   ✅ Found %s"):format(base_path..anime_section.VideoFile) or ("   ❌ Could not find %s\n"):format(base_path..anime_section.VideoFile))
    end

    -- audio
    error = error .. (audio_section_found and "\n\nAUDIO\n   ✅ Found an \"AudioFile=\" line" or "   ❌ Could not find an \"AudioFile=\" line")
    if audio_section_found then
      error = error .. (audio_file_found and ("\n   ✅ Found %s\n"):format(base_path..anime_section.AudioFile) or ("\n   ❌ Could not find %s\n"):format(base_path..anime_section.AudioFile))
    end

    -- subtitle
    if subtitle_section_found and (subtitle_file_found==false or subtitle_format_supported==false) then
      error = error .."\nSUBTITLES"
      if subtitle_file_found==false then
        error = error .. ("\n   ✅ Found a \"SubtitleFile=\" line\n❌Could not find %s\n"):format(anime_section.SubtitleFile)
      end
      if not subtitle_format_supported then
         error =  error .. ("\n   ❌ Subtitle format %s isn't supported.\nOnly .srt and .ass subtitle files are supported.\n"):format(extension)
      end
    end

    lua.ReportScriptError(error)
    return false
  end

  local return_data = {
    VideoFile=base_path..anime_section.VideoFile,
    AudioFile=base_path..anime_section.AudioFile,
  }

  -- optionally include path for SubtitleFile
  if subtitle_section_found and subtitle_file_found then
    return_data.SubtitleFile = base_path..anime_section.SubtitleFile
  end

  if type(ini.subtitle_style)=="table" then
    -- optionally include FontZoom as number
     if type(ini.subtitle_style.FontZoom)=="number" then
        return_data.FontZoom = ini.subtitle_style.FontZoom
     end
     -- optionally include TextColor as stepmania color
     if type(ini.subtitle_style.TextColor)=="string" then
        local c = color(ini.subtitle_style.TextColor)
        if c ~= nil then return_data.TextColor = c end
     end
    -- optionally include StrokeColor as stepmania color
     if type(ini.subtitle_style.StrokeColor)=="string" then
        local c = color(ini.subtitle_style.StrokeColor)
        if c ~= nil then return_data.StrokeColor = c end
     end
  end

  return return_data
end

-- ------------------------------------------------------
-- StrToSecs converts a stringifed timestamp formatted like "00:02:15.100"
-- and returns it as a numeric 135.1

helpers.StrToSecs = function(s)
    local hour, min, sec, hundreth = s:gsub(",", "."):match("(%d+):(%d+):(%d+%.%d+)")
    hour = tonumber(hour) or 0
    min  = tonumber(min)  or 0
    sec  = tonumber(sec)  or 0
    return ((hour*60*60)+(min*60)+(sec))
end

-- ------------------------------------------------------
-- function for detecting edit mode
-- returns true or false

helpers.IsEditMode = function()
    local screen = SCREENMAN:GetTopScreen()
    if not screen then
        lua.ReportScriptError("Helpers.IsEditMode() check failed to run because there is no Screen yet.")
        return nil
    end

    return (THEME:GetMetric(screen:GetName(), "Class") == "ScreenEdit")
end

-- ------------------------------------------------------
-- hides all children layers of the current screen execpt for "SongForeground"
-- intended to be used with ScreenGameplay

helpers.HideUI = function()
   local screen = SCREENMAN:GetTopScreen()
    if not screen then
        lua.ReportScriptError("Helpers.HideUI() failed to run because there is no Screen yet.")
        return nil
    end

   -- don't hide the theme's UI in EditMode
   if helpers.IsEditMode() then
      return
   end

   for name,layer in pairs(screen:GetChildren()) do
      if name ~= "SongForeground" then
         layer:visible(false)
      end
   end
end

-- ------------------------------------------------------
-- Takes a string and generates a case insensitive Lua string pattern.
-- e.g. "ini" returns "[Ii][Nn][Ii]"
--
-- originally appeared in Simply Love/Scripts/SL-ChartParser.lua

helpers.MixedCasePattern = function(str)
	local t = {}
	for c in str:gmatch(".") do
		t[#t+1] = "[" .. c:upper() .. c:lower() .. "]"
	end
	return table.concat(t, "")
end

-- ------------------------------------------------------
-- WideScale() is copied from Simply Love/Scripts/SL-Helpers.lua
-- Useful for writing one line of code that scales a number depending on the player's current theme aspect ratio.
-- This clamps the the scaled value to not exceed whatever is provided as AR16_9, which would otherwise happen
-- with, for example ultrawide (21:9) monitors.

helpers.WideScale = function(AR4_3, AR16_9)
	return clamp(scale( SCREEN_WIDTH, 640, 854, AR4_3, AR16_9 ), AR4_3, AR16_9)
end

return helpers