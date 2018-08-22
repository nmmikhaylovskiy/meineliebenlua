package.path = package.path..";/home/nm/Desktop/copy.lua"
--require "goodbuglibary"
require "copy"
local Aimal = class("Animal")
function Aimal:tellAboutSelf()
	print("Staring tell about self")
end

function Aimal:voce()
	print("soma voice")
end
local animal_1=Aimal("Cat")

local Berd = class("Berd", Aimal)
function Berd:voce( ... )
	print("kar")
	self:super():voce()
end
function Berd:tellAboutSelf( ... )
	print("!")
	
end
local bird_1 = Berd("Pingue")



local SuperBird=class("ff",Berd)
function SuperBird:voce( ... )
	print("f")
	self: super():tellAboutSelf()
end

function SuperBird:tellAboutSelf( ... )
	print("here")
	self:super():tellAboutSelf()
end

local bird_2 = SuperBird("dd")


bird_2:voce()
--bird_2:tellAboutSelf()





 --bird_1:tellAboutSelf()

-- local animail = Animal()
-- animail:tellAboutSelf()



-- local arr = { x = "x"}
-- local meta = {}
-- print("meta index", meta)
-- print("arr index", arr)

-- function meta:__call()
-- 	print("call")
-- 	if self.x == "x" then
-- 		self.y = "y"
-- 		print("ok") 
-- 	end
-- 	-- self:me()
-- end
-- function meta:__index(key)
-- 	print("index")
-- 	print(self, key)
-- end

-- local res = setmetatable(arr, meta)

-- res()
-- print(res.y)

