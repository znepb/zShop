--[[

	PAIN picture editor for ComputerCraft

	Get it with

	 pastebin get wJQ7jav0 pain

	 std pb wJQ7jav0 pain

     std ld pain pain

	

	This is a stable release. You fool!

--]]



local displayHelp = function()

	local progname = fs.getName(shell.getRunningProgram())

	print(progname.." <filename>")

	print("Press F1 in program for more.")

end



local pMode = 0



local tArg = {...}

if (not tArg[1]) and shell then

	return displayHelp()

end



if tArg[2] == "view" then

	pMode = 1

elseif tArg[2] == "moo" then

	return print("This PAIN does not have Super Cow Powers.")

end



local fileName

if not term.isColor() then

	error("Only for Advanced computers")

end

local barmsg = "Press F1 for help."

local tse = textutils.serialise

local tun = textutils.unserialise

local paintEncoded

local lastPaintEncoded

local frame = 1

local doRender = false

local metaHistory = {}

local bepimode = false      --this is a family-friendly program! now stand still while I murder you

local evenDrawGrid = true   --will you evenDraw(the)Grid ?

local renderBlittle = false --whether or not to render all in blittle

local firstTerm, blittleTerm = term.current()

local firstBG = term.getBackgroundColor()

local firstTX = term.getTextColor()



local grid



local yield = function()

	os.queueEvent("yield")

	os.pullEvent("yield")

end



local paint = {

	scrollX = 0,

	scrollY = 0,

	t = colors.gray,

	b = colors.white,

	m = 1,	--in case you want to use PAIN as a level editor or something

	c = " ",

	doGray = false,

}



local scr_x, scr_y = term.getSize()

local scrollX, scrollY = 0, 0



local keysDown = {}

local miceDown = {}



local doRenderBar = 1 -- 1 and 0. Not true or false



local fixstr = function(str)

	return str:gsub("\\(%d%d%d)",string.char)

end



local choice = function(input,breakkeys)

	repeat

		event, key = os.pullEvent("key")

		if type(key) == "number" then key = keys.getName(key) end

		if key == nil then key = " " end

		if type(breakkeys) == "table" then

			for a = 1, #breakkeys do

				if key == breakkeys[a] then

					return ""

				end

			end

		end

	until string.find(input, key)

	return key

end

local explode = function(div,str)

    if (div=='') then return false end

    local pos,arr = 0,{}

    for st,sp in function() return string.find(str,div,pos,true) end do

        table.insert(arr,str:sub(pos,st-1))

        pos = sp + 1

    end

    table.insert(arr,str:sub(pos))

    return arr

end



local function cutString(max_line_length, str) --from stack overflow

   local lines = {}

   local line

   str:gsub('(%s*)(%S+)', 

      function(spc, word) 

         if not line or #line + #spc + #word > max_line_length then

            table.insert(lines, line)

            line = word

         else

            line = line..spc..word

         end

      end

   )

   table.insert(lines, line)

   return lines

end



local cutUp = function(len,tbl)

	local output = {}

	local e = 0

	local s

	for a = 1, #tbl do

		if #(tbl[a]:gsub(" ","")) == 0 then

			s = {""}

		else

			s = cutString(len,tbl[a])

		end

		for b = 1, #s do

			table.insert(output,s[b])

		end

	end

	return output

end



local getEvents = function(...)

	local output

	while true do

		output = {os.pullEvent()}

		for a = 1, #arg do

			if type(arg[a]) == "boolean" then

				if doRender == arg[a] then

					return {}

				end

			elseif output[1] == arg[a] then

				return unpack(output)

			end

		end

	end

end



local sanitize = function(sani,tize)

	local _,x = string.find(sani,tize)

	if x then

		return sani:sub(x+1)

	else

		return sani

	end

end

local ro = function(input, max)

	return math.floor(input % max)

end



local guiHelp = function()

	term.redirect(firstTerm)

	scr_x, scr_y = term.current().getSize()

	local _helpText = [[



 'PAIN' Help Page

Programmed by LDDestroier/EldidiStroyrr



(use UP/DOWN or scrollwheel, exit with Q)

If you want to use PAIN to its full capacity, then READ EVERYTHING HERE! It's not TOO long, and it's completely worth it!



Syntax:

>pain <filename> [view]



[view]: disable all writing capability to view a file



You can see what colors are selected based on the word "PAIN" on the hotbar.



Hotkeys:

 left/right ctrl: toggle the menu



 left click:

  +shift = drag and let go to make a line

  -alone = place pixel



 right click: delete pixel



 middle click OR "t": place text down with current colors



 "[" or mouse scroll down:

  +shift = change to previous text color

  -alone = change to previous background color



 "]" or mouse scroll up:

  +shift = change to next text color

  -alone = change to next background color



 spacebar:

  +shift = toggle grid

  -alone = toggle bar visibility



 arrowkeys:

  +shift = move entire picture

  +tab = move one pixel at a time

  -alone = looks around the canvas smoothly



 "+" (or equals):

  +left alt = swap the current frame with the next frame

  -alone = change to next frame



 "-":

  +left alt = swap the current frame with the previous frame

  -alone = change to previous frame



 "a": set the coordinates to 0,0



 "b": toggle redirect to blittle, to preview in teletext characters



 "c": input coordinates to move the canvas to



 "g": toggle grayscale mode. everything is in shades of gray. if you Save, it saves in grayscale.



 "f":

  +shift = fill all empty pixels with background color

  -alone = absolutely nothing



 "m": set metadata for pixels (for game makers, otherwise safe to ignore)





 Le Menu (access with CTRL):



 -left click on a menu item to select it.

 -if you click on the menubar, let go on an option to select it.



 "Save"

 Saves all frames to a specially formatted PAIN paint file. The format PAIN uses is very inefficient despite my best efforts, so Export if you don't use text or multiple frame.



 "Export"

 Exports current frame to the basic paint format, which doesn't save text, but is WAY more space-efficient. Specify a path, too.



 "Del. Frame"

 Deletes the current frame. Tells you off if you try to delete the only frame.



 "Clear"

 Deletes all pixels on the current frame.



 "Exit"

 Durr I dunno, I think it exits.





I hope my PAIN causes you joy.

]]

	_helpText = explode("\n",_helpText)

	helpText = cutUp(scr_x,_helpText)

	local helpscroll = 0

	term.setBackgroundColor(colors.gray)

	term.setTextColor(colors.white)

	term.clear()

	local evt, key

	while true do

		term.clear()

		for a = 1, scr_y do

			term.setCursorPos(1,a)

			term.clearLine()

			term.write(helpText[a-helpscroll] or "")

		end

		repeat

			evt,key = os.pullEvent()

		until evt == "key" or evt == "mouse_scroll"

		if evt == "key" then

			if key == keys.up then

				helpscroll = helpscroll + 1

			elseif key == keys.down then

				helpscroll = helpscroll - 1

			elseif key == keys.pageUp then

				helpscroll = helpscroll + scr_y

			elseif key == keys.pageDown then

				helpscroll = helpscroll - scr_y

			elseif (key == keys.q) or (key == keys.space) then

				doRender = true

				if renderBlittle then term.redirect(blittleTerm) end

				scr_x, scr_y = term.current().getSize()

				return

			end

		elseif evt == "mouse_scroll" then

			helpscroll = helpscroll - key

		end

		if helpscroll > 0 then

			helpscroll = 0

		elseif helpscroll < -(#helpText-(scr_y-3)) then

			helpscroll = -(#helpText-(scr_y-3))

		end

	end

end



local tableRemfind = function(tbl, str)

	local out = tbl

	for a = 1, #tbl do

		if tbl[a] == str then

			table.remove(out,a)

			return out,a

		end

	end

	return {}

end



local stringShift = function(str,amt)

	return str:sub(ro(amt-1,#str)+1)..str:sub(1,ro(amt-1,#str))

end



local deepCopy

deepCopy = function(obj)

	if type(obj) ~= 'table' then return obj end

	local res = {}

	for k, v in pairs(obj) do res[deepCopy(k)] = deepCopy(v) end

	return res

end



local renderBottomBar = function(txt)

	term.setCursorPos(1,scr_y)

	term.setBackgroundColor(colors.lightGray)

	term.setTextColor(colors.black)

	term.clearLine()

	term.write(txt)

end



local bottomPrompt = function(txt,history,cho,breakkeys)

	renderBottomBar(txt)

	local out

	sleep(0)

	if cho then

		out = choice(cho,breakkeys)

	else

		out = read(_,history)

	end

	return out

end



local getDotsInLine = function( startX, startY, endX, endY ) --stolen from the paintutils API...hehehe

    local out = {}

    

    startX = math.floor(startX)

    startY = math.floor(startY)

    endX = math.floor(endX)

    endY = math.floor(endY)



    if startX == endX and startY == endY then

        out = {{x=startX,y=startY}}

        return out

    end

    

    local minX = math.min( startX, endX )

    if minX == startX then

        minY = startY

        maxX = endX

        maxY = endY

    else

        minY = endY

        maxX = startX

        maxY = startY

    end

        

    local xDiff = maxX - minX

    local yDiff = maxY - minY

            

    if xDiff > math.abs(yDiff) then

        local y = minY

        local dy = yDiff / xDiff

        for x=minX,maxX do

            table.insert(out,{x=x,y=math.floor(y+0.5)})

            y = y + dy

        end

    else

        local x = minX

        local dx = xDiff / yDiff

        if maxY >= minY then

            for y=minY,maxY do

                table.insert(out,{x=math.floor(x+0.5),y=y})

                x = x + dx

            end

        else

            for y=minY,maxY,-1 do

                table.insert(out,{x=math.floor(x+0.5),y=y})

                x = x - dx

            end

        end

    end

    return out

end



local movePaintEncoded = function(pe,xdiff,ydiff)

	local outpootis = deepCopy(pe)

	for a = 1, #outpootis do

		outpootis[a].x = outpootis[a].x+xdiff

		outpootis[a].y = outpootis[a].y+ydiff

	end

	return outpootis

end



local clearRedundant = function(dots)

	local input = {}

	local pheight = 0

	local pwidth = 0

	for a = 1, #dots do

		if dots[a].y > pheight then

			pheight = dots[a].y

		end

		if dots[a].x > pwidth then

			pwidth = dots[a].x

		end

	end

	for a = 1, #dots do

		if not input[dots[a].y] then input[dots[a].y] = {} end

		input[dots[a].y][dots[a].x] = dots[a]

	end

	local output = {}

	local frame = 0

	for y = 1, pheight do

		for x = 1, pwidth do

			if input[y] then

				if input[y][x] then

					table.insert(output,input[y][x])

				end

			end

			if frame >= 50 then

				--yield()

				frame = 0

			end

		end

	end

	return output

end



local grayOut = function(color)

	local c = deepCopy(_G.colors)

	local grays = {

		[c.white] = c.white,

		[c.orange] = c.lightGray,

		[c.magenta] = c.lightGray,

		[c.lightBlue] = c.lightGray,

		[c.yellow] = c.white,

		[c.lime] = c.lightGray,

		[c.pink] = c.lightGray,

		[c.gray] = c.gray,

		[c.lightGray] = c.lightGray,

		[c.cyan] = c.lightGray,

		[c.purple] = c.gray,

		[c.blue] = c.gray,

		[c.brown] = c.gray,

		[c.green] = c.lightGray,

		[c.red] = c.gray,

		[c.black] = c.black,

	}

	local newColor = grays[color] or 1

	return newColor

end



local getOnscreenCoords = function(tbl,_x,_y)

	local screenTbl = {}

	for a = 1, #tbl do

		if tbl[a].x+paint.scrollX > 0 and tbl[a].x+paint.scrollX <= scr_x then

			if tbl[a].y+paint.scrollY > 0 and tbl[a].y+paint.scrollY <= scr_y then

				table.insert(screenTbl,{tbl[a].x+paint.scrollX,tbl[a].y+paint.scrollY})

			end

		end

	end

	if not _x and _y then

		return screenTbl

	else

		for a = 1, #screenTbl do

			if screenTbl[a][1] == _x and screenTbl[a][2] == _y then

				return true

			end

		end

		return false

	end

end



local fillTool = function(info,cx,cy,color,layer) --takes a frame, not the whole paintEncoded

	local x,y

	local output = {}

	for a = 1, #info do

		if (info[a].x == cx) and (info[a].y == cy) then

			x = cx

			y = cy

			replaceColor = info[a].b

			break

		end

	end

	if not x and y then

		return

	end

	if color == replaceColor then

		return

	end

	table.insert(output,{

		["x"] = x,

		["y"] = y,

		["b"] = color,

		["t"] = color,

		["c"] = " ",

		["m"] = paint.m

	})

	local loops = 0

	local tAffectedPoints = {

		[1] = {

			x = x+tTerm.scroll.x,

			z = z+tTerm.scroll.z

		}

	}

	while #tAffectedPoints > 0 do

		if loops%200 == 0 then

			sleep(0.05)

		end

		for i=-1,1,2 do

			local x = tAffectedPoints[1]["x"]+i

			local z = tAffectedPoints[1]["z"]

			if tBlueprint[layer][x][z] == replaceColor and x >= tTerm.viewable.sX and x <= tTerm.viewable.eX and z >= tTerm.viewable.sZ and z <= tTerm.viewable.eZ then

				drawPoint(x,z,color,layer,true,true)

				table.insert(tAffectedPoints,{["x"] = x,["z"] = z})

			end

			x = tAffectedPoints[1]["x"]

			z = tAffectedPoints[1]["z"]+i

			if tBlueprint[layer][x][z] == replaceColor and x >= tTerm.viewable.sX and x <= tTerm.viewable.eX and z >= tTerm.viewable.sZ and z <= tTerm.viewable.eZ then

				drawPoint(x,z,color,layer,true,true)

				table.insert(tAffectedPoints,{["x"] = x,["z"] = z})

			end

		end

		table.remove(tAffectedPoints,1)

		loops = loops+1

	end

end



local saveFile = function(path,info)

	local output = {}

	for a = 1, #info do

		output[a] = clearRedundant(info[a])

		if a % 8 == 0 then yield() end

	end

	local fileout = textutils.serialize(output):gsub("  ",""):gsub("\n",""):gsub(" = ","="):gsub(",}","}")

	if #fileout >= fs.getFreeSpace(fs.getDir(path)) then

		barmsg = "Not enough space."

		return

	end

	local file = fs.open(path,"w")

	file.write(fileout)

	file.close()

end

local renderBar = function(msg,dontSetVisible)

	local tsv = term.current().setVisible

	if (doRenderBar == 0) or renderBlittle then return end

	if tsv and (not dontSetVisible) then tsv(false) end

	term.setCursorPos(1,scr_y)

	term.setBackgroundColor(colors.lightGray)

	term.setTextColor(colors.black)

	term.clearLine()

	term.setBackgroundColor(paint.b)

	term.setTextColor(paint.t)

	term.setCursorPos(2,scr_y)

	term.write("PAIN")

	term.setBackgroundColor(colors.lightGray)

	term.setTextColor(colors.black)

	term.setCursorPos(7,scr_y)

	term.write(msg.." Frame: "..frame.."/"..#paintEncoded)

	term.write(" (X:"..paint.scrollX.." Y:"..paint.scrollY..")")

	if tsv and (not dontSetVisible) then tsv(true) end

end



local rendback = {

	b = colors.black,

	t = colors.gray,

}



local getTablePaint = function(pe)

	local output = {}

	for a = 1, #pe do

		if not output[pe[a].y] then output[pe[a].y] = {} end

		output[pe[a].y][pe[a].x] = pe[a]

	end

	return output

end



local renderPainyThings = function(xscroll,yscroll,doGrid)

	if bepimode then

		grid = {

			"Bepis",

			"episB",

			"pisBe",

			"isBep",

			"sBepi",

		}

	else

		grid = {

			"%%..",

			"%%..",

			"%%..",

			"..%%",

			"..%%",

			"..%%",

		}

	end

	term.setBackgroundColor(rendback.b)

	term.setTextColor(rendback.t)

	local badchar = "/"

	local blittlelabel = "blittle max"

	local screenlabel = "screen max"

	if doGrid then

		for y = 1, scr_y-(renderBlittle and 0 or doRenderBar) do

			term.setCursorPos(1,y)

			--the single most convoluted line I've ever written that works, and I love it

			term.write(stringShift(grid[ro(y+(yscroll+2),#grid)+1],xscroll+1):rep(math.ceil(scr_x/#grid[ro(y+(yscroll+2),#grid)+1])):sub(1,scr_x))

			term.setCursorPos(1,y)

			if ((scr_y+1)-yscroll) == y then --regular limit

				term.write( (string.rep("@", ( (scr_x)     ) - (#screenlabel+2)  ) ..screenlabel:gsub(" ","@"):upper().."@@"):sub(xscroll>0 and xscroll or 0) )

			elseif (((scr_y*3)+1)-yscroll) == y then --blittle limit

				term.write( (string.rep("@", ( ((scr_x*2))   ) - (#blittlelabel+2) )..blittlelabel:gsub(" ","@"):upper().."@@"):sub(xscroll>0 and xscroll or 0) )

			end

			--Stupid easter eggs, ho!--

			if 1000-yscroll == y then

				term.setCursorPos(1000-xscroll,y)

				term.write(" What ARE you doing? Stop messing around! ")

			end

			if 2016-yscroll == y then

				term.setCursorPos(200-xscroll,y)

				term.write(" MOTHER 3 is the best RPG ever. ")

			end

			if 2017-yscroll == y then

				term.setCursorPos(200-xscroll,y)

				term.write(" Wouldn't you agree? ")

			end

			if 800-yscroll == y then

				term.setCursorPos(1700-xscroll,y)

				term.write(" Which would you say is better? ")

			end

			if 801-yscroll == y then

				term.setCursorPos(1700-xscroll,y)

				term.write(" Cave Story or Braid? ")

			end

			if 802-yscroll == y then

				term.setCursorPos(1700-xscroll,y)

				term.write(" It depends what you're looking for. ")

			end

			--Is this the end?--

			if (xscroll > scr_x) and (xscroll < (scr_x*2)+1) then --blittle limit

				for y = 1, scr_y do

					if y+yscroll <= (scr_y*3) then

						if not (y == scr_y and doRenderBar == 1) then

							term.setCursorPos((scr_x+1)-(xscroll-scr_x),y)

							term.write("@")

						end

					end

				end

			elseif (xscroll > 0) then --regular limit

				for y = 1, scr_y do

					if y+yscroll <= scr_y then

						if not (y == scr_y and doRenderBar == 1) then

							term.setCursorPos((scr_x+1)-xscroll,y)

							term.write("@")

						end

					end

				end

			end

		end

		--render areas that won't save

		if xscroll < 0 then

			for y = 1, scr_y do

				if not (y == scr_y and doRenderBar == 1) then

					term.setCursorPos(1,y)

					term.write(badchar:rep(-xscroll))

				end

			end

		end

		if yscroll < 0 then

			for y = 1, -yscroll do

				if not (y == scr_y and doRenderBar == 1) then

					term.setCursorPos(1,y)

					term.write(badchar:rep(scr_x))

				end

			end

		end

	else

		term.clear()

	end

end



renderPAIN = function(dots,xscroll,yscroll,doPain)

	local tsv = term.current().setVisible

	if tsv then tsv(false) end

	local beforeTX,beforeBG = term.getTextColor(), term.getBackgroundColor()

	local cx,cy = term.getCursorPos()

	local FUCK, SHIT = pcall(function()

		if doPain then

			renderPainyThings(xscroll,yscroll,evenDrawGrid)

			renderBar(barmsg,true)

		end

		for a = 1, #dots do

			local d = dots[a]

			if doPain then

				if not ((d.y-yscroll >= 1 and d.y-yscroll <= scr_y-(renderBlittle and 0 or (doRenderBar or 0))) and (d.x-xscroll >= 1 and d.x-xscroll <= scr_x)) then

					d = nil

				end

			end

			if d then

				term.setCursorPos(d.x-(xscroll or 0),d.y-(yscroll or 0))

				term.setTextColor((paint.doGray and grayOut(d.t)) or d.t)

				term.setBackgroundColor((paint.doGray and grayOut(d.b)) or d.b)

				term.write(d.c)

			end

		end

	end)

	term.setBackgroundColor(beforeBG)

	term.setTextColor(beforeTX)

	term.setCursorPos(cx,cy)

	if tsv then tsv(true) end

	if not FUCK then error(SHIT) end --GODDAMN IT

end



renderPAINFS = function(filename,xscroll,yscroll,frameNo,doPain)

	local tun, tse = textutils.unserialize, textutils.serialize

	local file = fs.open(filename,"r")

	local contents = file.readAll()

	local amntFrames

	file.close()

	local tcontents = tun(contents)

	if type(tcontents) ~= "table" then

		tcontents = importFromNFP(contents)

	else

		amntFrames = #tcontents

		tcontents = tcontents[frameNo or 1]

	end

	renderPAIN(tcontents,xscroll,yscroll,doPain)

	return amntFrames

end



local getBlittle = function()

	if not blittle then

		local geet = http.get("http://pastebin.com/raw/ujchRSnU")

		if not geet then

			return false

		else

			geet = geet.readAll()

			local file = fs.open("/.templittle/blittle","w")

			file.write(geet)

			file.close()

			os.loadAPI("/.templittle/blittle")

			fs.delete("/.templittle/")

			if not blittleTerm then

				blittleTerm = blittle.createWindow()

			end

			return blittleTerm, firstTerm

		end

	else

		if not blittleTerm then

			blittleTerm = blittle.createWindow()

		end

		return blittleTerm, firstTerm

	end

end



local putDownText = function(x,y)

	term.setCursorPos(x,y)

	term.setTextColor((paint.doGray and grayOut(paint.t)) or paint.t)

	term.setBackgroundColor((paint.doGray and grayOut(paint.b)) or paint.b)

	local msg = read()

	if #msg > 0 then

		for a = 1, #msg do

			table.insert(paintEncoded[frame],{x=a+(x+paint.scrollX)-1,y=y+paint.scrollY,t=paint.t,b=paint.b,c=msg:sub(a,a),m=paint.m})

		end

	end

end



local deleteDot = function(x,y)

	local good = false

	for a = #paintEncoded[frame],1,-1 do

		local b = paintEncoded[frame][a]

		if (x == b.x) and (y == b.y) then

			table.remove(paintEncoded[frame],a)

			good = true

		end

	end

	return good

end



CTB = function(_color) --Color To Blit

	local blitcolors = {

		[0] = " ",

		[colors.white] = "0",

		[colors.orange] = "1",

		[colors.magenta] = "2",

		[colors.lightBlue] = "3",

		[colors.yellow] = "4",

		[colors.lime] = "5",

		[colors.pink] = "6",

		[colors.gray] = "7",

		[colors.lightGray] = "8",

		[colors.cyan] = "9",

		[colors.purple] = "a",

		[colors.blue] = "b",

		[colors.brown] = "c",

		[colors.green] = "d",

		[colors.red] = "e",

		[colors.black] = "f",

	}

	return blitcolors[_color] or "f"

end



BTC = function(_color) --Blit To Color

	local blitcolors = {

		[" "] = 0,

		["0"] = colors.white,

		["1"] = colors.orange,

		["2"] = colors.magenta,

		["3"] = colors.lightBlue,

		["4"] = colors.yellow,

		["5"] = colors.lime,

		["6"] = colors.pink,

		["7"] = colors.gray,

		["8"] = colors.lightGray,

		["9"] = colors.cyan,

		["a"] = colors.purple,

		["b"] = colors.blue,

		["c"] = colors.brown,

		["d"] = colors.green,

		["e"] = colors.red,

		["f"] = colors.black,

	}

	return blitcolors[_color]

end



exportToNFP = function(input)

	local doop = {}

	local p = input

	local pheight = 0

	local pwidth = 0

	for a = 1, #p do

		if p[a].y > pheight then

			pheight = p[a].y

		end

		if p[a].x > pwidth then

			pwidth = p[a].x

		end

	end

	for k,v in pairs(p) do

		if not doop[v.y] then doop[v.y] = {} end

		doop[v.y][v.x] = CTB(v.b)

	end

	for y = 1, pheight do

		if doop[y] then

			for x = 1, pwidth do

				if doop[y][x] then

					nfpoutput = nfpoutput..doop[y][x]

				else

					nfpoutput = nfpoutput.." "

				end

			end

		end

		nfpoutput = nfpoutput.."\n"

	end

	return nfpoutput

end



importFromNFP = function(theInput)

	local output = {}

	local input = explode("\n",theInput)

	for a = 1, #input do

		line = input[a]

		for b = 1, #line do

			if (line:sub(b,b) ~= " ") and BTC(line:sub(b,b)) then

				table.insert(output,{

					x = b,

					y = a,

					t = colors.white,

					b = BTC(line:sub(b,b)) or colors.black,

					c = " ",

				})

			end

		end

	end

	return output

end



local getTheDoots = function(pe)

	local hasBadDots = false

	local baddestX,baddestY = 1,1

	barmsg = "Checking..."

	for b = 1, #pe do

		local doot = pe[b]

		if doot.x <= 0 or doot.y <= 0 then

			hasBadDots = true

			if doot.x < baddestX then

				baddestX = doot.x

			end

			if doot.y < baddestY then

				baddestY = doot.y

			end

		end

		if b % 64 == 0 then yield() end

	end

	return baddestX, baddestY

end



local function deepcompare(t1,t2,ignore_mt)

	local ty1 = type(t1)

	local ty2 = type(t2)

	if ty1 ~= ty2 then return false end

	-- non-table types can be directly compared

	if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end

	-- as well as tables which have the metamethod __eq

	local mt = getmetatable(t1)

	if not ignore_mt and mt and mt.__eq then return t1 == t2 end

	for k1,v1 in pairs(t1) do

		local v2 = t2[k1]

		if v2 == nil or not deepcompare(v1,v2) then return false end

	end

	for k2,v2 in pairs(t2) do

		local v1 = t1[k2]

		if v1 == nil or not deepcompare(v1,v2) then return false end

	end

	return true

end



local displayMenu = function()

	menuOptions = {"Save","Export","Del.frame","Clear","Exit"}

	local diss = " "..table.concat(menuOptions," ")

	local cleary = scr_y-math.floor(#diss/scr_x)

	for a = cleary,scr_y do

		term.setCursorPos(1,a)

		term.setBackgroundColor(colors.lightGray)

		term.clearLine()

	end

	local menuPoses = {}

	local menuFunctions = {

		[1] = function() --Save

			local hasBadDots = false

			for a = 1, #paintEncoded do

				local radx,rady = getTheDoots(paintEncoded[a])

				if radx ~= 1 or rady ~= 1 then

					hasBadDots = true

				end

			end

			if hasBadDots then

				local ting = bottomPrompt("Dot(s) are OoB! Save or fix? (Y/N/F)",_,"ynf",{keys.leftCtrl,keys.rightCtrl})

				if ting == "f" then

					for a = 1, #paintEncoded do

						local baddestX, baddestY = getTheDoots(paintEncoded[a])

						paintEncoded[a] = movePaintEncoded(paintEncoded[a],-(baddestX-1),-(baddestY-1))

					end

				elseif ting ~= "y" then

					barmsg = ""

					return false

				end

			end

			local output = deepCopy(paintEncoded)

			if paint.doGray then

				for a = 1, #paintEncoded do

					for b = 1, #paintEncoded[a] do

						output[a][b].b = grayOut(paintEncoded[a][b].b)

						output[a][b].t = grayOut(paintEncoded[a][b].t)

						if not output[a][b].m then output[a][b].m = 1 end

					end

					if a % 2 == 0 then yield() end

				end

			end

			saveFile(fileName,output)

			lastPaintEncoded = deepCopy(paintEncoded)

			term.setCursorPos(9,scr_y)

			barmsg = "Saved as '"..fileName.."'"

			doRender = true

		end,

		[2] = function() --Export

			nfpoutput = ""

			local exportName = bottomPrompt("Export to: /")

			if fs.combine("",exportName) == "" then return end

			if fs.isReadOnly(exportName) then

				barmsg = "That's read-only."

				doRender = true

				return

			end

			if fs.exists(exportName) then

				if bottomPrompt("Overwrite? (Y/N)",_,"yn",{keys.leftCtrl,keys.rightCtrl}) ~= "y" then return end

			end

			local output = exportToNFP(paintEncoded[frame])

			if keysDown[207] then --secretly convert into what paintutils.loadImage() would return!

				local bepis = explode("\n",output)

				output = {}

				for y = 1, #bepis do

					output[y] = {}

					for x = 1, #bepis[y] do

						output[y][x] = BTC(bepis[y]:sub(x,x))

					end	

				end

				output = textutils.serialize(output):gsub("\n",""):gsub(" ",""):gsub(",}","}")

			end

			local file = fs.open(exportName,"w")

			file.write(output)

			file.close()

			doRender = true

			barmsg = "Exported as '"..exportName.."'"

			return

		end,

		[3] = function() --Del.Frame

			local outcum = bottomPrompt("Thou art sure? (Y/N)",_,"yn",{keys.leftCtrl,keys.rightCtrl})

			if outcum == "y" then

				if #paintEncoded == 1 then

					barmsg = "Ha! You can't do that."

					return

				end

				table.remove(paintEncoded,frame)

				barmsg = "Deleted frame "..frame.."."

				if paintEncoded[frame-1] then

					frame = frame - 1

				else

					frame = frame + 1

				end

				if #paintEncoded < frame then

					repeat

						frame = frame - 1

					until #paintEncoded >= frame

				end

				--renderPAIN(paintEncoded[frame],paint.scrollX,paint.scrollY,true)

			end

			doRender = true

		end,

		[4] = function() --Clear

			local outcum = bottomPrompt("Clear the frame? (Y/N)",_,"yn",{keys.leftCtrl,keys.rightCtrl})

			if outcum == "y" then

				paintEncoded[frame] = {}

				barmsg = "Cleared frame "..frame.."."

				--renderPAIN(paintEncoded[frame],paint.scrollX,paint.scrollY,true)

			end

			doRender = true

		end,

		[5] = function() --Exit

			if not deepcompare(lastPaintEncoded,paintEncoded) then

				local outcum = bottomPrompt("Abandon unsaved work? (Y/N)",_,"yn",{keys.leftCtrl,keys.rightCtrl})

				sleep(0)

				if outcum == "y" then

					return "exit"

				else

					doRender = true

					return nil

				end

			else

				return "exit"

			end

		end,

	}

	local cursor = 1

	local redrawmenu = true

	local initial = os.time()

	local clickdelay = 0.003

	while true do

		if redrawmenu then

			term.setCursorPos(2,cleary)

			term.clearLine()

			for a = 1, #menuOptions do

				if a == cursor then

					term.setTextColor(colors.black)

					term.setBackgroundColor(colors.white)

				else

					term.setTextColor(colors.black)

					term.setBackgroundColor(colors.lightGray)

				end

				menuPoses[a] = {term.getCursorPos()}

				write(menuOptions[a])

				term.setBackgroundColor(colors.lightGray)

				if a ~= #menuOptions then

					write(" ")

				end

			end

			redrawmenu = false

		end

		local event,key,x,y = getEvents("key","char","mouse_click","mouse_up","mouse_drag")

		if event == "key" then

			if key == keys.left then

				redrawmenu = true

				cursor = cursor - 1

			elseif key == keys.right then

				redrawmenu = true

				cursor = cursor + 1

			elseif key == keys.enter then

				local res = menuFunctions[cursor]()

				if res == "exit" then

					return "exit"

				else

					return

				end

			elseif key == keys.leftCtrl or key == keys.rightCtrl then

				doRender = true

				return

			end

		elseif event == "char" then

			for a = 1, #menuOptions do

				if key:lower() == menuOptions[a]:sub(1,1):lower() and a ~= cursor then

					cursor = a

					redrawmenu = true

					break

				end

			end

		elseif event == "mouse_click" or event == "mouse_up" then

			if y < cleary then

				return

			elseif key == 1 and initial+clickdelay < os.time() then --key? more like button

				for a = 1, #menuPoses do

					if y == menuPoses[a][2] then

						if x >= menuPoses[a][1] and x <= menuPoses[a][1]+#menuOptions[a] then

							local res = menuFunctions[a]()

							if res == "exit" then

								return "exit"

							else

								return

							end

						end

					end

				end

			end

		--elseif event == "mouse_drag" then

		end

		if (initial+clickdelay < os.time()) and string.find(event,"mouse") then

			if key == 1 then --key? key? what key? all I see is button!

				for a = 1, #menuPoses do

					if y == menuPoses[a][2] then

						if x >= menuPoses[a][1] and x <= menuPoses[a][1]+#menuOptions[a] then

							cursor = a

							redrawmenu = true

							break

						end

					end

				end

			end

		end

		if cursor < 1 then

			cursor = #menuOptions

		elseif cursor > #menuOptions then

			cursor = 1

		end

	end

end



local lastMX,lastMY



local doNonEventDrivenMovement = function() --what a STUPID function name, man

	local didMove

	while true do

		didMove = false

		if (not keysDown[keys.leftShift]) and (not isDragging) and (not keysDown[keys.tab]) then

			if keysDown[keys.right] then

				paint.scrollX = paint.scrollX + 1

				didMove = true

			elseif keysDown[keys.left] then

				paint.scrollX = paint.scrollX - 1

				didMove = true

			end

			if keysDown[keys.down] then

				paint.scrollY = paint.scrollY + 1

				didMove = true

			elseif keysDown[keys.up] then

				paint.scrollY = paint.scrollY - 1

				didMove = true

			end

			if didMove then

				if lastMX and lastMY then

					if miceDown[1] then

						os.queueEvent("mouse_click",1,lastMX,lastMY)

					end

					if miceDown[2] then

						os.queueEvent("mouse_click",2,lastMX,lastMY)

					end

				end

				doRender = true

			end

		end

		sleep(0)

	end

end



local linePoses = {}

local dragPoses = {}



local getInput = function() --gotta catch them all

	local button, x, y, oldmx, oldmy, origx, origy

	local isDragging = false

	local proceed = false

	renderBar(barmsg)

	while true do

		doRender = false

		local oldx,oldy = paint.scrollX,paint.scrollY

		local evt = {getEvents("mouse_scroll","mouse_click", "mouse_drag","mouse_up","key","key_up",true)}

		if (evt[1] == "mouse_scroll") and (not viewing) then

			local dir = evt[2]

			if dir == 1 then

				if keysDown[keys.leftShift] or keysDown[keys.rightShift] then

					paint.t = paint.t * 2

					if paint.t > 32768 then

						paint.t = 32768

					end

				else

					paint.b = paint.b * 2

					if paint.b > 32768 then

						paint.b = 32768

					end

				end

			else

				if keysDown[keys.leftShift] or keysDown[keys.rightShift] then

					paint.t = math.ceil(paint.t / 2)

					if paint.t < 1 then

						paint.t = 1

					end

				else

					paint.b = math.ceil(paint.b / 2)

					if paint.b < 1 then

						paint.b = 1

					end

				end

			end

			renderBar(barmsg)

		elseif ((evt[1] == "mouse_click") or (evt[1] == "mouse_drag")) and (not viewing) then

			if evt[1] == "mouse_click" then

				origx, origy = evt[3], evt[4]

			end

			oldmx,oldmy = x or evt[3], y or evt[4]

			lastMX,lastMY = evt[3],evt[4]

			button,x,y = evt[2],evt[3],evt[4]

			if renderBlittle then

				x = 2*x

				y = 3*y

				lastMX = 2*lastMX

				lastMY = 3*lastMY

			end

			linePoses = {{x=oldmx,y=oldmy},{x=x,y=y}}

			miceDown[button] = true

			doRender = true

			if y <= scr_y-(renderBlittle and 0 or doRenderBar) then

				if (button == 3) then

					putDownText(x,y)

					miceDown = {}

					keysDown = {}

				elseif button == 1 then

					if keysDown[keys.leftShift] and evt[1] == "mouse_click" then

						isDragging = true

					end

					if isDragging then

						if evt[1] == "mouse_click" then

							dragPoses[1] = {x=x,y=y}

						end

						dragPoses[2] = {x=x,y=y}

					else

						if evt[1] == "mouse_drag" then

							local points = getDotsInLine(linePoses[1].x,linePoses[1].y,linePoses[2].x,linePoses[2].y)

							for a = 1, #points do

								table.insert(paintEncoded[frame],{

									x = points[a].x + paint.scrollX,

									y = points[a].y + paint.scrollY,

									c = paint.c,

									b = paint.b,

									t = paint.t,

									m = paint.m,

								})

							end

						else

							table.insert(paintEncoded[frame],{

								x = x + paint.scrollX,

								y = y + paint.scrollY,

								c = paint.c,

								b = paint.b,

								t = paint.t,

								m = paint.m,

							})

						end

					end

				elseif button == 2 and y <= scr_y-(renderBlittle and 0 or doRenderBar) then

					deleteDot(x+paint.scrollX,y+paint.scrollY)

				end

			elseif origy >= scr_y-(renderBlittle and 0 or doRenderBar) then

				keysDown = {}

				local res = displayMenu()

				if res == "exit" then break end

				doRender = true

			end

		elseif (evt[1] == "mouse_up") and (not viewing) then

			origx,origy = 0,0

			local button = evt[2]

			miceDown[button] = false

			oldmx,oldmy = nil,nil

			lastMX, lastMY = nil,nil

			if isDragging then

				local points = getDotsInLine(dragPoses[1].x,dragPoses[1].y,dragPoses[2].x,dragPoses[2].y)

				for a = 1, #points do

					table.insert(paintEncoded[frame],{

						x = points[a].x + paint.scrollX,

						y = points[a].y + paint.scrollY,

						c = paint.c,

						b = paint.b,

						t = paint.t,

						m = paint.m,

					})

				end

				doRender = true

			end

			isDragging = false

		elseif evt[1] == "key" then

			local key = evt[2]

			if (not keysDown[keys.leftShift]) and (keysDown[keys.tab]) then

				if key == keys.right and (not keysDown[keys.right]) then

					paint.scrollX = paint.scrollX + 1

					doRender = true

				elseif key == keys.left and (not keysDown[keys.left]) then

					paint.scrollX = paint.scrollX - 1

					doRender = true

				end

				if key == keys.down and (not keysDown[keys.down]) then

					paint.scrollY = paint.scrollY + 1

					doRender = true

				elseif key == keys.up and (not keysDown[keys.up]) then

					paint.scrollY = paint.scrollY - 1

					doRender = true

				end

			end

			keysDown[key] = true

			if key == keys.space then

				if keysDown[keys.leftShift] then

					evenDrawGrid = not evenDrawGrid

				else

					doRenderBar = math.abs(doRenderBar-1)

				end

				doRender = true

			end

			if key == keys.b then

				local blTerm, oldTerm = getBlittle()

				renderBlittle = not renderBlittle

				term.setBackgroundColor(colors.black)

				term.clear()

				if renderBlittle then

					term.redirect(blTerm)

					blTerm.setVisible(true)

				else

					term.redirect(oldTerm)

					blTerm.setVisible(false)

				end

				doRender = true

				scr_x, scr_y = term.current().getSize()

			end

			if (key == keys.c) and (not renderBlittle) then

				local newX = tonumber(bottomPrompt("Goto X:"))

				local newY

				if newX then

					newY = tonumber(bottomPrompt("Goto Y:"))

					paint.scrollX = newX or paint.scrollX

					paint.scrollY = newY or paint.scrollY

				end

				doRender = true

			end

			if (keysDown[keys.leftShift]) and (not isDragging) then

				if key == keys.left then

					paintEncoded[frame] = movePaintEncoded(paintEncoded[frame],-1,0)

					doRender = true

				elseif key == keys.right then

					paintEncoded[frame] = movePaintEncoded(paintEncoded[frame],1,0)

					doRender = true

				elseif key == keys.up then

					paintEncoded[frame] = movePaintEncoded(paintEncoded[frame],0,-1)

					doRender = true

				elseif key == keys.down then

					paintEncoded[frame] = movePaintEncoded(paintEncoded[frame],0,1)

					doRender = true

				end

			end

			if keysDown[keys.leftAlt] then

				if #paintEncoded > 1 then

					if key == keys.equals and paintEncoded[frame+1] then --basically plus

						local first = deepCopy(paintEncoded[frame])

						local next = deepCopy(paintEncoded[frame+1])

						paintEncoded[frame] = next

						paintEncoded[frame+1] = first

						frame = frame + 1

						barmsg = "Swapped prev frame."

					end

					if key == keys.minus and paintEncoded[frame-1] then

						local first = deepCopy(paintEncoded[frame])

						local next = deepCopy(paintEncoded[frame-1])

						paintEncoded[frame] = next

						paintEncoded[frame-1] = first

						frame = frame - 1

						barmsg = "Swapped next frame."

					end

				end

			end

			if not renderBlittle then

				if key == keys.m then

					local incum = bottomPrompt("Set meta: ",metaHistory)

					paint.m = incum:gsub(" ","") ~= "" and incum or paint.m

					if paint.m ~= metaHistory[#metaHistory] then

						table.insert(metaHistory,paint.m)

					end

					doRender = true

				end

				if key == keys.f7 then

					bepimode = not bepimode

					doRender = true

				end

				if key == keys.t then

					renderBottomBar("Click to place text.")

					local mevt

					repeat

						mevt = {os.pullEvent("mouse_click")}

					until mevt[2] == 1 and mevt[4] < scr_y-(renderBlittle and 0 or doRenderBar)

					local x,y = mevt[3],mevt[4]

					if renderBlittle then

						x = 2*x

						y = 3*y

					end

					putDownText(x,y)

					miceDown = {}

					keysDown = {}

				end

				if not keysDown[keys.leftAlt] then

					if key == keys.equals then --basically 'plus'

						if not paintEncoded[frame+1] then

							paintEncoded[frame+1] = {}

							local sheet = paintEncoded[frame]

							if keysDown[keys.leftShift] then

								paintEncoded[frame+1] = deepCopy(sheet)

							end

						end

						frame = frame + 1

						doRender = true

					elseif key == keys.minus then

						if frame > 1 then

							frame = frame - 1

							doRender = true

						end

					end

				end

				if (key == keys.leftCtrl or key == keys.rightCtrl) then

					keysDown = {[207] = keysDown[207]}

					local res = displayMenu()

					if res == "exit" then break end

					doRender = true

				end

			end

			if (key == keys.f and keysDown[keys.leftShift]) then

				local deredots = {}

				for a = 1, #paintEncoded[frame] do

					local dot = paintEncoded[frame][a]

					if dot.x-paint.scrollX > 0 and dot.x-paint.scrollX <= scr_x then

						if dot.y-paint.scrollY > 0 and dot.y-paint.scrollY <= scr_y then

							table.insert(deredots,{dot.x-paint.scrollX, dot.y-paint.scrollY})

						end

					end

				end

				for y = 1, scr_y-(renderBlittle and 0 or doRenderBar) do

					for x = 1, scr_x do

						local good = true

						for a = 1, #deredots do

							if (deredots[a][1] == x) and (deredots[a][2] == y) then

								good = bad

								break

							end

						end

						if good then

							table.insert(paintEncoded[frame],{

								x = x+paint.scrollX,

								y = y+paint.scrollY,

								c = " ",

								t = paint.t,

								b = paint.b,

								m = paint.m,

							})

						end

					end

				end

				doRender = true

			end

			if key == keys.g then

				paint.doGray = not paint.doGray

				doRender = true

			end

			if key == keys.a then

				paint.scrollX = 0

				paint.scrollY = 0

				doRender = true

			end

			if key == keys.f1 then

				guiHelp()

			end

			if key == keys.leftBracket then

				os.queueEvent("mouse_scroll",2,1,1)

			elseif key == keys.rightBracket then

				os.queueEvent("mouse_scroll",1,1,1)

			end

		elseif evt[1] == "key_up" then

			local key = evt[2]

			keysDown[key] = false

		end

		if (oldx~=paint.scrollX) or (oldy~=paint.scrollY) then

			doRender = true

		end

		if doRender then

			renderPAIN(paintEncoded[frame],paint.scrollX,paint.scrollY,true)

			doRender = false

		end

	end

end



if not shell then return end



fileName = shell.resolve(tostring(tArg[1]))



if not fs.exists(fileName) then

	paintEncoded = {{}}

else

	local file = fs.open(fileName,"r")

	local contents = file.readAll()

	file.close()

	if type(tun(contents)) ~= "table" then

		if pMode ~= 1 then print("Importing from NFP...") end

		paintEncoded = {importFromNFP(contents)}

		if fileName:sub(-4,-1) == ".nfp" then

			fileName = fileName:sub(1,-5)

		end

	else

		paintEncoded = tun(contents)

	end

end



paintEncoded = tun(tse(paintEncoded):gsub("bg","b"):gsub("txt","t"):gsub("char","c"):gsub("meta","m")) -- gotta have backwards compatibility, sorta



if not paintEncoded[frame] then paintEncoded = {paintEncoded} end

if pMode == 1 then

	doRenderBar = 0

	renderPAIN(paintEncoded[tonumber(tArg[5]) or 1],tonumber(tArg[3]) or 0,tonumber(tArg[4]) or 0)

	sleep(0)

	return

else

	renderPAIN(paintEncoded[frame],paint.scrollX,paint.scrollY,true)

end

lastPaintEncoded = deepCopy(paintEncoded)



parallel.waitForAny(getInput,doNonEventDrivenMovement)



term.setCursorPos(1,scr_y)

term.setBackgroundColor(colors.black)

term.clearLine()
