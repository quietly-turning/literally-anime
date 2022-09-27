local base_path = GAMESTATE:GetCurrentSong():GetSongDir()
local helpers = dofile(base_path.."scripts/AnimeHelpers.lua")
local font_data = dofile(base_path.."fonts/Work Sans 50px/Work Sans.lua")

local num_regular, num_italic, num_bold = 0, 0, 0
for _,_ in pairs(font_data.regular) do num_regular = num_regular+1 end
for _,_ in pairs(font_data.italic)  do num_italic  = num_italic+1  end
for _,_ in pairs(font_data.bold)    do num_bold    = num_bold+1    end

-- subtract 1 from each to account for " " character in each table that doesn't have a corresponding texture
num_regular = num_regular - 1
num_italic  = num_italic  - 1
num_bold    = num_bold    - 1

local max_subt_width = (_screen.w-30)

-- color
local c = {1,1,1,1}

-- texture width and height, to be given value in AMV's InitCommand
local texture_w, texture_h
local num_rows, num_cols = 16, 16

-- the width and height of a single character in the texture
-- note: char_tw and char_th not the width/height a font character when drawn to the screen
--       these are the texture_w/num_cols and texture_h/num_rows
local char_tw, char_th

-- get the vertex data needed for an ActorMultiVertex to draw a unit of subtitle text
-- using our hand-crafted sprite sheet and lua file
local GetVerts = function(t)
   local verts = {}
   local text
   local w, h = 0, 0
   local v_coords, tex_coords

   local row, col
   local char, char_index, char_w


   for phrase in ivalues(t) do
      text = phrase.text

      for i=1, text:len() do

         if char == "\n" then
            h = h + font_data.height
            w = 0

         else
            char = text:sub(i,i)

            if font_data[phrase.style] == nil then phrase.style="regular" end

            -- vertex coordiates, these are the 4 corners of this single character as it appears
            -- in the ActorMultiVertex's internal coordinate space.  the units of the coordinates
            -- are arbitrary, so we'll use pixels as that's convenient.
            v_coords = {
            --   x                  y                   z
               { w,                 h,                  1},
               { w+font_data.width, h,                  1},
               { w+font_data.width, h+font_data.height, 1},
               { w,                 h+font_data.height, 1},
            }


            if font_data[phrase.style][char] == nil then
               w = w + font_data.width
               lua.ReportScriptError("char: "..char.."\nstyle: "..phrase.style.."\n\n\n")
            else
               w = w + font_data[phrase.style][char]
            end

            if (char == " ") then
               table.insert(verts, {v_coords[1], c})
               table.insert(verts, {v_coords[2], c})
               table.insert(verts, {v_coords[3], c})
               table.insert(verts, {v_coords[4], c})
            else

               char_index = helpers.FindInTable(char, font_data.characters) or (#font_data.characters+1)
               char_index = char_index - 1

               if phrase.style=="italic" then
                  char_index = char_index + num_regular

               elseif phrase.style=="bold" then
                  char_index = char_index + num_regular + num+italic
               end

               row = math.floor(char_index / 16)
               col = (char_index % 16)

               -- texture coordinates, these are the 4 corners of the specific section of the bitmap texture
               -- we want drawn at this spot in the AMV.  texture coordinates exist between 0 and 1, so we'll
               -- need to scale pixel values down.
               tex_coords = {
               --  tx                                               ty
                  {scale( (col*char_tw),          0, texture_w, 0, 1), scale((row*char_th),           0, texture_h, 0, 1)}, -- top left
                  {scale(((col*char_tw)+char_tw), 0, texture_w, 0, 1), scale((row*char_th),           0, texture_h, 0, 1)}, -- top right
                  {scale(((col*char_tw)+char_tw), 0, texture_w, 0, 1), scale(((row*char_th)+char_th), 0, texture_h, 0, 1)}, -- bottom right
                  {scale( (col*char_tw),          0, texture_w, 0, 1), scale(((row*char_th)+char_th), 0, texture_h, 0, 1)}, -- bottom left
               }

               table.insert(verts, {v_coords[1], c, tex_coords[1]})
               table.insert(verts, {v_coords[2], c, tex_coords[2]})
               table.insert(verts, {v_coords[3], c, tex_coords[3]})
               table.insert(verts, {v_coords[4], c, tex_coords[4]})
            end
         end
      end
   end

   return verts
end

local temp = {
   { text="use italic when you want to ", style="regular"},
   { text="emphasize ", style="italic"},
   { text="something with text", style="regular"},
}

local AMVFont = Def.ActorMultiVertex{
   InitCommand=function(self)
      self:zoom(0.5)
      self:SetDrawState({Mode="DrawMode_Quads"})
      self:LoadTexture( font_data.texture )
      self:SetTextureFiltering( false )
      local texture = self:GetTexture()
      texture_w = texture:GetTextureWidth()
      texture_h = texture:GetTextureHeight()
      char_tw   = math.floor(texture_w / num_cols)
      char_th   = math.floor(texture_h / num_rows)
   end,
   OnCommand=function(self)
      self:playcommand("SetText", temp)
   end,
   SetTextCommand=function(self, params)
      self:SetVertices( GetVerts(params) )
   end
}

return AMVFont