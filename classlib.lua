
local ambiguous

if keep_ambiguous then
	ambiguous = { _type = 'ambiguous' }
--назначение типов
	local function invalid(operation)
		return function()
			error('Invalid ' .. operation .. ' on ambiguous')
		end
	end
--обработчики ошибок при вызове функции
	local ambiguous_mt =
	{
		__add		= invalid('addition'),
		__sub		= invalid('substraction'),
		__mul		= invalid('multiplication'),
		__div		= invalid('division'),
		__mod		= invalid('modulus operation'),
		__pow		= invalid('exponentiation'),
		__unm		= invalid('unary minus'),
		__concat	= invalid('concatenation'),
		__len		= invalid('length operation'),
		__eq		= invalid('equality comparison'),
		__lt		= invalid('less than'),
		__le		= invalid('less or equal'),
		__index		= invalid('indexing'),
		__newindex	= invalid('new indexing'),
		__call		= invalid('call'),
		__tostring	= function() return 'ambiguous' end,
		__tonumber	= invalid('conversion to number')
	}
	setmetatable(ambiguous, ambiguous_mt)

end


--резервирование некотрых имен

local reserved =
{
	__index			= true,
	__newindex		= true,
	__type			= true,
	__class			= true,
	__bases			= true,
	__inherited		= true,
	__from			= true,
	__shared		= true,
	__user_init		= true,
	__name			= true,
	__initialized	= true
}


local rename =
{
	__init	= '__user_init',
	__set	= '__user_set',
	__get	= '__user_get'
}



--создание метатаблицы, содержащей следующие функции:
--__call() - создание экземпляра, __init() - конструктор, is_a()-проверка типа implements()- для проверки поддержки интерфейса,
--__newindex() для контроля численности класса
local class_mt = {} 
class_mt.__index = class_mt

--[[
	This controls class population.
	Here 'self' is a class being populated by inheritance or by the user.
]]

function class_mt:__newindex(name, value)--нейм - ключ

	-- переименование пользовательских атрибутов 
	if rename[name] then name = rename[name] end

	-- __user_get() needs an __index() handler
	--если передааное имя = юзергет, тогда индекс наследника = 
	if name == '__user_get' then--доступ по пользовательскому ключу
		self.__index = value and function(obj, k)
			local v = self[k]
			if v == nil and not reserved[k] then --если В - пустое и не резервированное, тогда 
			   v = value(obj, k)
			 end
			return v
		end or self

	-- __user_set() needs a __newindex() handler
	elseif name == '__user_set' then
		self.__newindex = value and 
		function(obj, k, v)
			if reserved[k] or not value(obj, k, v) then 
				rawset(obj, k, v) 
		     end
		end or nil

	end
	-- назначение пользовательских атрибутов
	rawset(self, name, value)
end






--[[
	This function creates an object of a certain class and calls itself
	recursively to create one child object for each base class. Base objects
	of unnamed base classes are accessed by using the base class as an index
	into the object, base objects of named base classes are accessed as fields
	of the object with the names of their respective base classes.
	Classes derived in shared mode will create only a single base object.
	Unambiguous grandchildren are inherited by the parent if they do not
	collide with direct children.
]]

local function build(class, shared_objs, shared)

	--Поиск и возвращение какого-то предыдущего объекта класса 
	if shared then
		local prev_instance = shared_objs[class]
		if prev_instance then return prev_instance end
	end

	--создание нового объекта
	local obj = { __type = 'object' }

	-- создание дочернего объекта базового класса 
	local nbases = #class.__bases
	if nbases > 0 then

		-- здесь будут храниться наследники
		local inherited = {}

		-- список ключей
		local ambiguous_keys = {}

		-- создание дочернего объекта для каждого базового класса
		for i = 1, nbases do  
			local base = class.__bases[i]
			local child = build(base, shared_objs, class.__shared[base]) -- рекурсивный вызов функции для создания ребенка
			obj[base.__name] = child

			-- получение дочернего объекта для этого дочернего объекта
			for c, grandchild in pairs(child) do

				-- может быть только один внук каждого класса, иначе ссылка будет неоднозначной 
				if not ambiguous_keys[c] then--если нет ключей
					if not inherited[c] then inherited[c] = grandchild -- если нет наследтников, тогда наследник = мегаребенок
					elseif inherited[c] ~= grandchild then--если же ключ не равен мегаребенку, тогда эта херь неоднозачна
						inherited[c] = ambiguous
						table.insert(ambiguous_keys, c) --добавление ключа на указанную позицию
					end
				end
			end
		end

		--добавлять унаследованных детей если они не совпадают с прямыми детьми 
		for k, v in pairs(inherited) do
			if not obj[k] then obj[k] = v end
		end

	end

	-- добавления объекта в класс
	setmetatable(obj, class)

	-- If общий, то добавляем в хранилище общих объектов
	if shared then shared_objs[class] = obj end

	return obj

end

--[[
	The __call() operator creates an instance of the class and initializes it.
]]
--создание и инициальизация объекта класса.
function class_mt:__call(...) --класс_мт - метатблица
	local obj = build(self, {}, false)--при вызове строим объект с использованием базового конструктора 
	obj:__init(...)
	return obj
end

--[[
	The implements() method checks that an object or class supports the
	interface of a target class. This means it can be passed as an argument to
	any function that expects the target class. We consider only functions
	and callable objects to be part of the interface of a class.
]]

function class_mt:implements(class)--проверка вохождения метода или объекта в интерфейс целевого класса 

	-- Auxiliary function to determine if something is callable
	local function is_callable(v)--функция оперделения вызываемог объекта
		if v == ambiguous then return false end --если объект неоднозначен, тогда вернуть фолс
		if type(v) == 'function' then return true end --если тип - функция, тогда вернуть тру 
		local mt = getmetatable(v)
		return mt and type(mt.__call) == 'function'
	end

	-- Check we have all the target's callables (except reserved names)
	--проверка всех ключей за исключенгием резерва
	for k, v in pairs(class) do
		if not reserved[k] and is_callable(v) and not is_callable(self[k]) then
			return false
		end
	end
	return true
end

--[[
	The is_a() method checks the type of an object or class starting from
	its class and following the derivation chain upwards looking for
	the target class. If the target class is found, it checks that its
	interface is supported (this may fail in multiple inheritance because
	of ambiguities).
]]
--проверка типа объекта или класса , начиная с класса и вверх по цепочке. 
function class_mt:is_a(class)

	-- если наш класс - класс, то это правда 
	if self.__class == class then return true end

	local function find(target, classlist)--проверка является ли класс одним из списка классов 
		for i = 1, #classlist do
			local class = classlist[i]
			if class == target or find(target, class.__bases) then
				return true
			end
		end
		return false
	end

	-- Check that we derive from the target
	if not find(class, self.__bases) then return false end

	-- Check that we implement the target's interface.
	return self:implements(class)
end

--[[
	Factory-supplied constructor, calls the user-supplied constructor if any,
	then calls the constructors of the bases to initialize those that were
	not initialized before. Objects are initialized exactly once.
]]

function class_mt:__init(...)--пользовательский конструктор
	if self.__initialized then return end
	if self.__user_init then self:__user_init(...) end
	for i = 1, #self.__bases do
		local base = self.__bases[i]
		self[base.__name]:__init(...)
	end
	self.__initialized = true
end


-- PUBLIC

--[[
	Utility type and interface checking functions
]]

function typeof(value)
	local t = type(value)
	return t =='table' and value.__type or t
end

function classof(value)
	local t = type(value)
	return t == 'table' and value.__class or nil
end

function classname(value)
	if not classof(value) then return nil end
	local name = value.__name
	return type(name) == 'string' and name or nil
end

function implements(value, class)

	return classof(value) and value:implements(class) or false

end

function is_a(value, class)
	return classof(value) and value:is_a(class) or false
end

--[[
	Use a table to control class creation and naming.
]]




class = {}--сам класс
local mt = {}--метатаблица класса
setmetatable(class, mt)

--[[
	Create a named or unnamed class by calling class([name, ] ...).
	Arguments are an optional string to set the class name and the classes or
	shared classes to be derived from.
]]

function mt:__call(...)--можно создать именновый или безименный класс

	local arg = {...}

	-- создание нового класса
	local c =
	{
		__type = 'class',
		__bases = {},
		__shared = {}
	}
	c.__class = c
	c.__index = c

	-- первый строковый аргумент - название
	if type(arg[1]) == 'string' then
		c.__name = arg[1]
		table.remove(arg, 1)
	else
		c.__name = c
	end

	--хранилие атрибутов наследников
	local inherited = {}
	local from = {}

	-- список ключей
	local ambiguous_keys = {}

	--наследование от базовых классов
	for i = 1, #arg do
		local base = arg[i]

		-- получение базы 
		local basetype = typeof(base)
		local shared = basetype == 'share'
		assert(basetype == 'class' or shared, --вывод ошибки
				'Base ' .. i .. ' is not a class or shared class')
		if shared then base = base.__class end

		--проверки на повтор базы
		assert(c.__shared[base] == nil, 'Base ' .. i .. ' is duplicated')

		-- добавляем
		c.__bases[i] = base
		c.__shared[base] = shared

		-- узнаем методы которые можно наследовать
		for k, v in pairs(base) do

			-- пропускаем зарезервированные и неоднозначные методы
			if type(v) == 'function' and not reserved[k] and
				not ambiguous_keys[k] then

				--откуда взялся этот метод
				local new_from

				-- проверка на то был ли метод унаследован от базы
				local base_inherited = base.__inherited[k]
				if base_inherited then
					--если метод был переопределен, то отменить это наследование 
					if base_inherited ~= v then		-- (1)
						base.__inherited[k] = nil
						base.__from[k] = nil

					-- если все еще наследуется, тополучитть его оригинал(путь?)
					else
						new_from = base.__from[k]
					end
				end

				-- If it is not inherited by the base, it originates there
				new_from = new_from or { class = base, shared = shared }
				--добавление первого наследования 
 				local current_from = from[k]
				if not current_from then
					from[k] = new_from
					local origin = new_from.class

					-- We assume this is an instance method (called with
					-- self as first argument) and wrap it so that it will
					-- receive the correct base object as self. For class
					-- functions this code is unusable.
					inherited[k] = function(self, ...)
						return origin[k](self[origin.__name], ...)
					end

				-- Methods inherited more than once are ambiguous unless
				-- they originate in the same shared class.
				elseif current_from.class ~= new_from.class or
						not current_from.shared or not new_from.shared then
					inherited[k] = ambiguous
					table.insert(ambiguous_keys, k)
					from[k] = nil
				end
			end
		end
	end

	-- Set the metatable now, it monitors attribute setting and does some
	-- special processing for some of them.
	setmetatable(c, class_mt)

	-- Set inherited attributes in the class, they may be redefined afterwards
	for k, v in pairs(inherited) do c[k] = v end	-- checked at (1)
	c.__inherited = inherited
	c.__from = from

	return c
end

--[[
	Create a named class and assign it to a global variable of the same name.
	Example: class.A(...) is equivalent to (global) A = class('A', ...).
]]

function mt:__index(name)  
	return function(...)
		local c = class(name, ...)
		getfenv()[name] = c
		return c
	end
end

function shared(class) -- функция наследоавния
	assert(typeof(class) == 'class', 'Argument is not a class')
	return { __type = 'share', __class = class }
end
