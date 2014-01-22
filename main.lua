-- Project: Star Explorer
-- Description:
--
-- Version: 1.0
-- Managed with http://OutlawGameTools.com
--
-- Copyright 2013 . All Rights Reserved.
---- cpmgen main.lua


local physics = require("physics")
physics.start()
physics.setGravity( 0, 0 )

system.activate("multitouch")

display.setStatusBar(display.HiddenStatusBar)

-- Initialize variables

local background = display.newImage( "images/DownWithDiscobg.png" )
background.x = display.contentWidth/2
background.y = display.contentHeight/2

local lives = 3
local score = 0
local numShot = 0
local shotTable = { } 
local discoBallsTable = { }
local numDiscoBalls = 0
local maxShotAge = 1000
local tick = 400 --time between game loops
local died = false
local explosion = audio.loadSound ( "sounds/explosion.wav" )
local fire = audio.loadSound ( "sounds/fire.wav" )
local backgroundMusic=audio.loadSound("sounds/HeavyGuitarRiff.wav")
local cheer=audio.loadSound("sounds/RoaringCrowd.wav")
local death=audio.loadSound("sounds/DeathSound.wav")
local sheetInfo = require("images.DWDSpriteSheet")
local mySheet = graphics.newImageSheet( "images/DWDSpriteSheet.png", sheetInfo:getSheet())
local backgroundMusicChannel=audio.play(backgroundMusic,{loops=-1})
local ampTable={}
local numAmps=0
local maxAmpShieldAge=8000
local shieldOn=false
local shieldTable={}
local numShields=0
local guitarTable={}
local numGuitars=0
local shotEnhance=false
local shotEnhanceTimeMax=5000
local shotEnhanceTime=0

--

-- display lives and score
local function newText ( )
	textLives = display.newText( "Lives: "..lives, display.contentWidth/2, display.contentHeight/20, nil, 12, "right")
	textScore = display.newText( "Score: "..score, display.contentWidth/2, display.contentHeight/40, nil, 12, "right")
	textLives:setFillColor ( 255, 255, 255 )
	textScore:setFillColor ( 255, 255, 255 )
end

local function  updateText ( )
	textLives.text = "Lives: "..lives
	textScore.text = "Score: "..score
end

--basic dragging physics

local function startDrag (event)
	local t = event.target
	
	local phase = event.phase
	if "began" == phase then
		display.getCurrentStage ( ):setFocus ( t )
		t.isFocus = true
		
		--Store initial position
		t.x0 = event.x - t.x
		
		event.target.bodyType = "kinematic"
		
		--Stop current motion
		event.target:setLinearVelocity (0, 0)
		event.target.angularVelocity = 0
	
	elseif t.isFocus then
		if "moved" == phase then
			t.x = event.x - t.x0
		elseif "ended" == phase or "cancelled" == phase then
			display.getCurrentStage ( ):setFocus(nil)
			t.isFocus = false
			if (not event.target.isPlatform) then
				event.target.bodyType = "dynamic"
			end
		end
	end
	return true
end

local function spawnRocker ( )
	rocker = display.newImage( mySheet, 6 )
	rocker.x = display.contentWidth/2
	rocker.y = display.contentHeight - 50
	physics.addBody ( rocker, {density=1.0, friction=0, bounce=1.0 } )
	rocker.myName = "rocker"
end

local function loadDiscoBall ( )
	numDiscoBalls = numDiscoBalls + 1
	discoBallsTable [numDiscoBalls ] = display.newImage(mySheet, 2)
	physics.addBody ( discoBallsTable [numDiscoBalls], {density=1.0, friction=0.4, bounce=1 } )
	discoBallsTable[numDiscoBalls].myName = "discoBall"
	discoBallsTable[numDiscoBalls].x=(math.random(display.contentWidth))
	discoBallsTable[numDiscoBalls].y=-20
	transition.to(discoBallsTable[numDiscoBalls],{y=display.contentHeight+30,time=5000+(score/10)})
end

local function loadAmp ()
	local ranNum=math.random(20)
	if(ranNum==1) then
		numAmps=numAmps+1
		ampTable[numAmps]=display.newImage(mySheet,1)
		physics.addBody(ampTable[numAmps],{density=0, friction=0})
		ampTable[numAmps].myName="amp"
		ampTable[numAmps].x=(math.random(display.contentWidth))
		ampTable[numAmps].y=-20
		transition.to(ampTable[numAmps],{y=display.contentHeight+30,time=5000+(score/10)})
	end
end

local function loadGuitar ()
	local ranNum=math.random(20)
	if(ranNum==1) then
		numGuitars=numGuitars+1
		guitarTable[numGuitars]=display.newImage(mySheet,5)
		physics.addBody(guitarTable[numGuitars],{density=0, friction=0})
		guitarTable[numGuitars].myName="guitar"
		guitarTable[numGuitars].x=(math.random(display.contentWidth))
		guitarTable[numGuitars].y=-20
		transition.to(guitarTable[numGuitars],{y=display.contentHeight+30, time=5000+(score/10)})
	end
end

local function onCollision (event)
	if ((event.object1.myName == "rocker" or event.object2.myName == "rocker")and(event.object1.myName=="discoBall" or event.object2.myName=="discoBall")) then
		if (died == false) then
			died = true
			if (lives == 1) then
				audio.play(death)
				event.object1:removeSelf()
				event.object2:removeSelf()
				lives = lives - 1
				updateText( )
				cleanup ( )
				local lose = display.newText( "You Have Failed", display.contentWidth/2, display.contentHeight/2, nil, 36 )
				lose:setFillColor ( 255, 255, 255 )
			else
				audio.play(death)
				rocker.alpha = 0
				lives = lives - 1
				cleanup ( )
				weDied ( )
			end
		end
	end
	if ( (event.object1.myName == "discoBall" and event.object2.myName == "shot") or (event.object1.myName == "shot" and event.object2.myName == "discoBall") ) then
		audio.play (explosion)
		event.object1:removeSelf()
		event.object1.myName = nil
		event.object2:removeSelf()
		event.object2.myName = nil
		score = score + 100
		if(score%5000==0) then
			lives=lives+1
		end
	end
	if((event.object1.myName == "rocker" and event.object2.myName == "amp") or (event.object1.myName == "amp" and event.object2.myName == "rocker")) then
		if (shieldOn==false) then
			audio.play(cheer)
			if(event.object1.myName=="amp") then
				event.object1:removeSelf()
				event.object1.myName = nil
			else
				event.object2:removeSelf()
				event.object2.myName = nil
			end
			numShields=numShields+1
			shieldTable[numShields]=display.newImage(mySheet,3)
			shieldTable[numShields].age=0
			shieldTable[numShields].myName="shield"
			shieldTable[numShields].x=display.contentWidth/2
			shieldTable[numShields].y=display.contentHeight/2-60
			shieldOn=true
			for i=table.getn(discoBallsTable), 1, -1 do
				if(discoBallsTable[i].myName ~=nil and discoBallsTable[i].y>display.contentHeight/2)then
						discoBallsTable[i]:removeSelf()
						discoBallsTable[i].myName=nil
				end
			end
		else
			audio.play(cheer)
			if(event.object1.myName=="amp") then
				event.object1:removeSelf()
				event.object1.myName = nil
			else
				event.object2:removeSelf()
				event.object2.myName = nil
			end
			shieldTable[numShields].age=0
		end
	end
	if((event.object1.myName == "discoBall" and event.object2.myName == "shield") or (event.object1.myName == "shield" and event.object2.myName == "discoBall")) then
		if(event.object1.myName=="discoBall") then
			event.object1:removeSelf()
			event.object1.myName = nil
		else
			event.object2:removeSelf()
			event.object2.myName = nil
		end
	end
	if((event.object1.myName == "rocker" and event.object2.myName == "guitar") or (event.object1.myName == "guitar" and event.object2.myName == "rocker")) then
		if(shotEnhance==false) then
			audio.play(cheer)
			if(event.object1.myName=="guitar") then
				event.object1:removeSelf()
				event.object1.myName=nil
			else
				event.object2:removeSelf()
				event.object2.myName=nil
			end
			shotEnhance=true
			shotEnhanceTime=0
		else
			if(event.object1.myName=="guitar") then
				event.object1:removeSelf()
				event.object1.myName=nil
			else
				event.object2:removeSelf()
				event.object2.myName=nil
			end
			shotEnhanceTime=0
		end
	end
end

function weDied ( )
	rocker.x = display.contentWidth/2
	rocker.y = display.contentHeight - 50
	transition.to ( rocker, {alpha = 1, time = 2000} )
	died = false
end

local function fireshot (event)
	if (shotEnhance==true) then
		audio.play(fire)
		--first shot
		numShot = numShot + 1
		shotTable[numShot] = display.newImage( mySheet, 4)
		physics.addBody ( shotTable[numShot], {density=1, friction=0} )
		shotTable[numShot].isbullet = true
		shotTable[numShot].x = rocker.x
		shotTable[numShot].y = rocker.y - 105
		transition.to ( shotTable[numShot], {y = -80, time = 700} )
		shotTable[numShot].myName = "shot"
		shotTable[numShot].age = 0

		--second shot
		numShot=numShot+1
		shotTable[numShot]=display.newImage(mySheet,4)
		physics.addBody ( shotTable[numShot], {density=1, friction=0} )
		shotTable[numShot].isbullet = true
		shotTable[numShot].x = rocker.x - 20
		shotTable[numShot].y = rocker.y - 105
		transition.to ( shotTable[numShot], {x=0, y = -80, time = 700} )
		shotTable[numShot]:rotate(-50)
		shotTable[numShot].myName = "shot"
		shotTable[numShot].age = 0

		--third shot
		numShot=numShot+1
		shotTable[numShot]=display.newImage(mySheet,4)
		physics.addBody ( shotTable[numShot], {density=1, friction=0} )
		shotTable[numShot].isbullet = true
		shotTable[numShot].x = rocker.x + 20
		shotTable[numShot].y = rocker.y - 105
		transition.to ( shotTable[numShot], {x=display.contentWidth, y = -80, time = 700} )
		shotTable[numShot]:rotate(50)
		shotTable[numShot].myName = "shot"
		shotTable[numShot].age = 0
	else
		numShot = numShot + 1
		shotTable[numShot] = display.newImage( mySheet, 4)
		physics.addBody ( shotTable[numShot], {density=1, friction=0} )
		shotTable[numShot].isbullet = true
		shotTable[numShot].x = rocker.x
		shotTable[numShot].y = rocker.y - 105
		transition.to ( shotTable[numShot], {y = -80, time = 700} )
		audio.play(fire)
		shotTable[numShot].myName = "shot"
		shotTable[numShot].age = 0
	end
end

function cleanup ( )
	for i = 1, table.getn(discoBallsTable) do
		if (discoBallsTable[i].myName ~= nil) then
			discoBallsTable[i]:removeSelf()
			discoBallsTable[i].myName = nil
		end
	end
	
	for i = 1, table.getn(shotTable) do
		if (shotTable[i].myName ~= nil) then
			shotTable[i]:removeSelf()
			shotTable[i].myName = nil
		end
	end

	for i=1, table.getn(ampTable) do
		if(ampTable[i].myName~=nil) then
			ampTable[i]:removeSelf()
			ampTable[i].myName=nil
		end
	end

	for i=1, table.getn(shieldTable) do
		if(shieldTable[i].myName~=nil) then
			shieldTable[i]:removeSelf()
			shieldTable[i].myName=nil
			shieldOn=false
		end
	end

	for i=1, table.getn(guitarTable) do
		if(guitarTable[i].myName~=nil)then
			guitarTable[i]:removeSelf()
			guitarTable[i].myName=nil
		end
	end
	shotEnhance=false
end

local function gameLoop ( )
	if(lives~=0) then
		updateText ( )
		loadDiscoBall ( )
		loadAmp()
		loadGuitar()
		for i=table.getn(discoBallsTable), 1, -1 do
			if (discoBallsTable[i].myName ~=nil and discoBallsTable[i].y>display.contentHeight)then
				discoBallsTable[i]:removeSelf()
				discoBallsTable[i].myName=nil
			end
		end
		for i=table.getn(ampTable), 1, -1 do
			if (ampTable[i].myName ~=nil and ampTable[i].y>display.contentHeight)then
				ampTable[i]:removeSelf()
				ampTable[i].myName=nil
			end
		end
		for i = table.getn(shotTable), 1, -1 do
			if (shotTable[i].myName ~= nil and shotTable[i].age < maxShotAge) then
				shotTable[i].age = shotTable[i].age + tick
			elseif (shotTable[i].myName ~= nil) then
				shotTable[i]:removeSelf()
				shotTable[i].myName = nil
			end
		end
		for i=table.getn(guitarTable), 1, -1 do
			if (guitarTable[i].myName ~=nil and guitarTable[i].y>display.contentHeight)then
				guitarTable[i]:removeSelf()
				guitarTable[i].myName=nil
			end
		end
		if (shieldOn==true) then
			if (shieldTable[numShields].age>=maxAmpShieldAge) then
				shieldTable[numShields]:removeSelf()
				shieldTable[numShields].myName=nil
				shieldOn=false
			else
				shieldTable[numShields].age=shieldTable[numShields].age+tick
				for i=table.getn(discoBallsTable), 1, -1 do
					if(discoBallsTable[i].myName ~=nil and discoBallsTable[i].y>display.contentHeight/2)then
							discoBallsTable[i]:removeSelf()
							discoBallsTable[i].myName=nil
					end
				end
			end
		end
		if(shotEnhance==true) then
			if(shotEnhanceTime>shotEnhanceTimeMax) then
				shotEnhance=false
			else
				shotEnhanceTime=shotEnhanceTime+tick
			end
		end
	end
end

--Start the game
spawnRocker ( )
newText ( )

rocker:addEventListener ( "touch", startDrag )
rocker:addEventListener ( "tap", fireshot )
Runtime:addEventListener ( "collision", onCollision )

timer.performWithDelay ( tick, gameLoop, 0 )