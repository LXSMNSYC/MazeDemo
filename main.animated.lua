--[[
    Maze Generation and Solver (Animated)
	
    MIT License

    Copyright (c) 2018 Alexis Munsayac

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
]]

local SPEED = 2

local DIRECTIONS = 2
local CLOSE = 0
local OPEN = 1
local SOLUTION = 2
local VISIT = 3 

math.randomseed(os.time())

local random = math.random 
local floor = math.floor
local abs = math.abs
local max = math.max 

local W, H = 600, 600 

local tilesW = 75
local tilesH = 75

local cellW = W/tilesW
local cellH = H/tilesH

local setColor = love.graphics.setColor 
local rectangle = love.graphics.rectangle


local function displayMap(map, w, h, solution)
	-- Copy the map
	local n = {}
	for k, v in ipairs(map) do 
		n[k] = v 
	end 
	-- Set the solution points
	if(solution) then 
		for k, v in ipairs(solution) do 
			n[v] = SOLUTION
		end 
	end 

	-- iterate through the map
	local prevX, prevY, drawLines = 0, 0, false
	for i = 1, #n do 
		local value = n[i]
		
		-- Convert the map coords to screen
		local x = ((i - 1) % w)*cellW
		local y = (floor((i - 1)/w))*cellH 
		

		if(value == CLOSE) then 
			-- Draws the open path 
			setColor(0.25, 0, 0.25)
			rectangle("fill", x, y, cellW, cellH)
			setColor(1, 1, 1)
		elseif(value == OPEN) then 
			-- Draws the open path 
			setColor(0x34/0xFF, 1, 0x34/0xFF)
			rectangle("fill", x, y, cellW, cellH)
			setColor(1, 1, 1)
		elseif(value == SOLUTION) then 
			-- Draw the solution path
			setColor(1, 1, 0x34/0xFF)
			rectangle("fill", x, y, cellW, cellH)
			-- Draw some steps
			local cw, ch = cellW*0.5, cellH*0.5
			if(cw >= 1 and ch >= 1) then 
				setColor(1, 0, 0)
				x = x + cw*0.5
				y = y + cw*0.5
				rectangle("fill", x, y, cw, ch)
				setColor(1, 1, 1)
			end 
		elseif(value == VISIT) then 
			setColor(0, 1, 1)
			rectangle("fill", x, y, cellW, cellH)
			setColor(1, 1, 1)
		end 

	end 
end 

local function empty() end 

local generateMazeUp, GMUfinish = empty, false  

local function generateMaze(w, h)
	generateMazeUp, GMUfinish = empty, false 
	-- the map that contains the paths
	local map = {}

	-- the list of cells contained within the map
	local cells = {}
	local parent = {}

	-- coords of the cells
	local cx, cy = {}, {}
	
	-- number of cells in the map
	local cellCount = 0

	-- Generate Cells
	for x = 1, w do 
		for y = 1, h do 
			-- identify if the point is a cell
			local isCell = (x % 2 == 0 and y % 2 == 0) 
			-- convert map 2D coord to 1D coord 
			local index = (y - 1)*w + x

			-- ternay; set value to OPEN if coord is a Cell
			map[index] = isCell and OPEN or CLOSE 

			-- if the coord is a cell, push to cell list
			if(isCell) then 
				cellCount = cellCount + 1
				cells[cellCount] = index
				cx[index] = x 
				cy[index] = y
			end 
		end 
	end 

	-- Visit Cells 
	local visited = {}

	-- pick a random cell to start with
	local currentCell = cells[floor(random(1, cellCount))]

	local cellStack, cz = {currentCell}, 1 
	visited[currentCell] = true 

	local function walk(x, y, dx, dy)
		--if(random(1, 100) > 50) then 
			-- get the coords of the cell to visit
			local tx, ty = x + dx, y + dy 
			-- convert 2D map to 1D map coord
			local index = (ty - 1)*w + tx 

			-- check if 2D coord is within bounds
			if((0 < tx and tx <= w) and (0 < ty and ty <= h)) then 
				-- check if cell is not yet visited
				if(not (visited[index] or parent[index])) then 
					-- cell is now visited
					visited[index] = true 

					-- punch through the wall
					-- set the blocked path between two cells to open
					-- local bx, by = x + dx/2, y + dy/2 
					-- local bi = (by - 1)*w + bx 
					
					-- map[bi] = OPEN

					-- push the next cell to visit
					cz = cz + 1
					cellStack[cz] = index

					parent[index] = (y - 1)*w + x
					return true 
				end 
			end

			return false 
		--end 
	end 

	-- cell visiting directions
	local dirs = {
		{-2, 0},
		{2, 0},
		{0, -2},
		{0, 2}
	}

	-- used for randomly visiting neighbor cells
	local function shuffle(t)
		local nt, nc = {}, 0
		local ct = #t 
		while(ct > 0) do
			local p = random(ct)

			nc = nc + 1
			nt[nc] = t[p]
			t[p] = t[ct]
			ct = ct - 1
		end 

		return nt
	end 

	-- iterate through the cell stack
	local function GMUListen()
		if (currentCell and cz > 0) then 
			-- get coords of the current cell
			local x, y = cx[currentCell], cy[currentCell]

			local parentNode = parent[currentCell]

			if(parentNode) then 
				-- punch through the wall
				-- set the blocked path between two cells to open
				local px, py = cx[parentNode], cy[parentNode]
				local bx, by = (x + px)/2, (y + py)/2 
				local bi = (by - 1)*w + bx 
				map[bi] = OPEN
			end 

			cellStack[cz] = nil
			-- pop stack
			cz = cz - 1
			-- shuffle directions
			local dir = shuffle({
				{-2, 0},
				{2, 0},
				{0, -2},
				{0, 2}
			})
			-- walk through neighbor cells

			local ci = 0
			for i = 1, 4 do
				local dec = dir[i] 

				if(walk(x, y, dec[1], dec[2])) then 
					ci = ci + 1 
				end 
				if(ci == max(2, DIRECTIONS)) then 
					break 
				end
			end

			-- visit the next cell from the stack
			currentCell = cellStack[cz]
		else 
			GMUfinish = true 
		end 
	end 
	generateMazeUp = GMUListen
	return map
end 

local solvePathVisit, SPVfinish = empty, false 
local SPTfinish = false 

local function solvePath(map, w, h, sx, sy, ex, ey)
	solvePathVisit, SPVfinish = empty, false 
	SPTfinish = false 
	-- convert 2D coords of goal points to 1D coords
	local startNode = (sy - 1)*w + sx
	local endNode = (ey - 1)*w + ex 

	-- used to reverse the steps list since
	-- the steps list is a backtrack
	-- startNode, endNode = endNode, startNode

	-- make sure that both start and end points are OPEN paths
	if(map[startNode] == 0 or map[endNode] == 0) then 
		return nil
	end 

	if(startNode == endNode) then 
		return 0
	end 

	-- used to track visited nodes
	local visitedNodes = {}

	-- builds the node tree
	local tree = {} 

	-- a list for pointing to parent tree nodes
	local parents = {}

	-- used for Breadth-First Search
	local visitQueue, vqSize = {startNode}, 1
	local visitCount = 1 

	-- track node positions
	local px, py = {[startNode] = sx}, {[startNode] = sy}

	local foundEnd = false 

	local function enqueueVisit(parent, tx, ty)
		local xb = 0 < tx and tx <= w 
		local yb = 0 < ty and ty <= h 

		-- check if the node to visit is within the map
		if(xb and yb) then 
			-- convert points to node
			local node = (ty - 1)*w + tx 
			-- check if node is an OPEN path node and not yet visited
			if((map[node] == OPEN) and (not visitedNodes[node]) and (not foundEnd)) then 
				-- the node is visited
				visitedNodes[node] = true
				
				-- save position of the node
				px[node] = tx 
				py[node] = ty 

				-- point parent of the node
				parents[node] = parent 

				-- insert node as a child of the parent
				local parentNode = tree[parent] or {} 
				parentNode[#parentNode + 1] = node 

				tree[parent] = parentNode 

				-- enqueue node to visit later
				vqSize = vqSize + 1
				visitQueue[vqSize] = node
			end 
		end 
	end 

	-- Breadth-First Search Tree

	local visitNode = visitQueue[visitCount]
	local function BuildListen()
		if (visitNode) then 
			map[visitNode] = VISIT
			if(visitNode == endNode) then 
				foundEnd = true 
				SPVfinish = true 
			end 

			if(foundEnd) then 
				map[visitNode] = SOLUTION
				if(visitNode ~= startNode) then
					-- go towards the next node to back track
					visitNode = parents[visitNode]
				else 
					SPTfinish = true 
				end 
			else 
				local tx, ty = px[visitNode], py[visitNode]

				-- visit all directions (if possible)
				enqueueVisit(visitNode, tx + 1, ty)
				enqueueVisit(visitNode, tx - 1, ty)
				enqueueVisit(visitNode, tx, ty + 1)
				enqueueVisit(visitNode, tx, ty - 1)
				
				-- go to the next node to visit
				visitQueue[visitCount] = nil
				visitCount = visitCount + 1
				visitNode = visitQueue[visitCount]
			end 
		end 
	end 

	solvePathVisit = BuildListen
end 

local mg, sol 
local mw, mh = W/cellW, H/cellH 

local startX, startY = 2, 2 
local endX, endY = mw - (mw % 2), mh - (mh % 2)
local timestamp = 0
local function updateSolution()
	sol = solvePath(
		mg, 
		mw, mh, 
		startX, startY,
		endX, endY
	)
end 
function love.load()
	love.window.setMode(W, H + 32, {
		borderless = true
	})
	
	mg = generateMaze(mw, mh)
end

local updateOnce = false 

local State = "none"
function love.update()
	for i = 1, SPEED do 
		if(GMUfinish) then 	
			if(not updateOnce) then 
				updateOnce = true 
				updateSolution()
			end 
			if(SPVfinish) then 
				if(not SPTfinish) then 
					State = "Backtracking"
				else 
					State = "Maze Solved!"
				end
			else 
				State = "Finding Goal Point"
			end 

			if(not (SPVfinish and SPTfinish)) then 
				solvePathVisit()
			end 
		else 
			generateMazeUp()
			updateOnce = false
			State = "Building Maze"
		end 
	end
end 


function love.draw()
	displayMap(mg, mw, mh, sol) 
	love.graphics.print("State: \n"..State, 8, H)
	love.graphics.print("Press Space to generate maze", W*0.25, H)
	love.graphics.print("Click maze to set goal points(left, right click).", W*0.5, H + 16)
	love.graphics.print("Press Esc to quit", W*0.75, H)
end 

function love.mousepressed(x, y, k)
	x = floor(x/cellW) + 1
	y = floor(y/cellH) + 1
	if(k == 1) then 
		startX, startY = x, y 
	else 
		endX, endY = x, y
	end 
	updateOnce = false
end

function love.keypressed(k)
	if(k == "escape") then 
		love.event.quit()
	elseif(k == "space") then
		mg = generateMaze(mw, mh) 
	end 
end 