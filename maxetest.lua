require "copy"


local Normal = class("Normal")

function Normal:testFunctionwithoutself()
	print("I am normal testFunctionwithoutself in Normal")
end

function Normal:testFunctionwithself()
	print("I am not testFunctionwithoutself yet in Normal")
end
local norm = Normal("norm")
local NormalFirst = class("NormalFirst", Normal)

function  NormalFirst:testFunctionwithoutself()
		print("I am function in NormalFirst")
end

function NormalFirst:testFunctionwithself()
	
	print("I am ovverited function  in NormalFirst and i am call self in Normal")
	self:super():testFunctionwithself()
	
end

function  NormalFirst:somefunction()
		print("i am just a function in NormalFirst")
end

local normfirst=NormalFirst("normfirst")
local NormalSecond = class("NormalSecond", NormalFirst)

function NormalSecond:testFunctionwithoutself()
	print("i am function in NormalSecond")
end

function NormalSecond:testFunctionwithself()
	print("I am ovverited funcrion in NormalSecond and i am call self in NormalFirst")
	self:super():testFunctionwithself()
end

function  NormalSecond:somefunction()
	print("i am ovverited somefunction in NormalSecond and i call self testFunctionwithoutself ")
	self:super():testFunctionwithoutself()
end



local normsec= NormalSecond("normsecond")
--print("tests------------Normal")
--print("1")
norm:testFunctionwithoutself()
--print("2")
norm:testFunctionwithself()
--print("tests------------NormalFirst")
--print("1")
normfirst:testFunctionwithoutself()
print("2")
normfirst:testFunctionwithself()
print("3")
normfirst:somefunction()
normsec:testFunctionwithoutself()
normsec:testFunctionwithself()
normsec:somefunction()


print(   os.clock())