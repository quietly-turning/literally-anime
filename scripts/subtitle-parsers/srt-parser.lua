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

      if line_num == 1 then
         -- unicode "byte order mark" EFBBBF is typically (but not always!) the first three bytes of the file
         if line:byte(1)==239 and line:byte(2)==187 and line:byte(3)==191 then
            -- skip it if we find it
            line = string.char(line:byte(4))
         end
      end

      if line ~= "" then
         if tonumber(line) ~= nil then
            -- advance GetLine to read the timestamp
            line = file:GetLine()
            line_num = line_num+1

            -- standardize begin/end timestamps to use periods
            line = line:gsub(",", ".")

            if line:match("%d+:%d+:%d+%.%d+ %-%-> %d+:%d+:%d+%.%d+") then

               local start, finish = line:match("(%d+:%d+:%d+%.%d+) %-%-> (%d+:%d+:%d+%.%d+)")

               -- advance GetLine to read the subtitle text
               line = file:GetLine()
               line_num = line_num+1
               local text = line

               -- advance GetLine to read either the 2nd line of subtitle text
               -- or an empty line indicating we should move onto the next subtitle unit
               line = file:GetLine()
               line_num = line_num+1

               while line ~= "" do
                  text = ("%s\n%s"):format(text, line)

                  -- continue advancing GetLine until we get a line that's an empty string
                  line = file:GetLine()
                  line_num = line_num+1
               end

               table.insert(events, {Start=helpers.StrToSecs(start), End=helpers.StrToSecs(finish), Text=text})

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