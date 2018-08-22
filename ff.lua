package.path = package.path..";/home/nm/Desktop/copy.lua"
--require "classlib"
require "copy"
local Normal = class("Normal")

function Normal:testFunctionwithoutself()
	x=1
end

function Normal:testFunctionwithself()
	x=1
end
local g = Normal()

local NormalTwo = class("NormalTwo", Normal)
function NormalTwo:testFunctionwithoutself()
	x=1
end


local d= NormalTwo()

for i=0, 3000000000 do
	d.testFunctionwithoutself()
end
print(os.clock())