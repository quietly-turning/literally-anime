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

   local events = {}
   local line_num = 0
   
   while not file:AtEOF() do
      local line = file:GetLine()
      line_num = line_num+1
      
      if line ~= "" then
         if tonumber(line) ~= nil then
            line = file:GetLine()
            line_num = line_num+1
            
            -- standardize numeric localization
            line = line:gsub(",", ".")
            
            if line:match("%d+:%d+:%d+%.%d+ %-%-> %d+:%d+:%d+%.%d+") then
               
               local start, finish = line:match("(%d+:%d+:%d+%.%d+) %-%-> (%d+:%d+:%d+%.%d+)")
               
               local text = ""

               line = file:GetLine()
               line_num = line_num+1
               
               while line ~= "" do
                  text = text..line
                  line = file:GetLine()
                  line_num = line_num+1
               end
               
               events[#events+1] = {Start=start, End=finish, Text=text}
               
            else
               lua.ReportScriptError( ("Error parsing %s\n   line %d: Couldn't parse start and finish time."):format(file_path, line_num) )
            end
         end
      end  
   end

   file:Close()
   file:destroy()
   
   return events
end

return ParseFile