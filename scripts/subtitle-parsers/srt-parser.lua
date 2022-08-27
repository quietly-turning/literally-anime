-- reference: https://www.matroska.org/technical/subtitles.html#srt-subtitles

local base_path = GAMESTATE:GetCurrentSong():GetSongDir()
local helpers   = dofile(base_path.."scripts/AnimeHelpers.lua")

local RageFile =
{
  READ       = 1,
  WRITE      = 2,
  STREAMED   = 4,
  SLOW_FLUSH = 8,
}

local ParseFile = function( file_path )
  local file = RageFileUtil.CreateRageFile()

  if not file:Open(file_path, RageFile.READ) then
    lua.ReportScriptError( string.format("ReadFile(%s): %s",file_path,file:GetError()) )
    file:destroy()
    return { }  -- return a blank table
  end

  local tbl = { }
  local current = tbl

  while not file:AtEOF() do
    local line = file:GetLine()
    -- TODO: implement 😩
  end

  file:Close()
  file:destroy()

  -- if tbl.events and type(tbl.events)=="table" then
  --   if tbl.events.Data and #tbl.events.Data > 0 then
  --     -- tbl.events.Data is the relevant data we want to return to SM5
  --     return tbl.events.Data
  --
  --   else
  --     lua.ReportScriptError(("Subtitle parsing error:\n'[Events]' section successfully found in %s, but dialogue lines not parsed correctly.\n\n"):format(file_path))
  --     return false
  --   end
  -- end
  --
  -- lua.ReportScriptError(("Subtitle parsing error:\n'[Events]' section could not be found in %s.\n\n"):format(file_path))
  -- return false
end

return ParseFile