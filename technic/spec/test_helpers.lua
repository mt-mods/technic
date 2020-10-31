
package.path = "../?.lua;./?.lua;machines/?.lua;" .. package.path

local _fixture_path = "spec/fixtures"

function fixture_path(name)
	return string.format("%s/%s", _fixture_path, name)
end

local _fixtures = {}
function fixture(name)
	if not _fixtures[name] then
		dofile(fixture_path(name) .. ".lua")
	end
	_fixtures[name] = true
end

local _source_path = "."

function source_path(name)
	return string.format("%s/%s", _source_path, name)
end

function sourcefile(name)
	dofile(source_path(name) .. ".lua")
end

function timeit(count, func, ...)
	local socket = require 'socket'
	local t1 = socket.gettime() * 1000
	for i=0,count do
		func(...)
	end
	local diff = (socket.gettime() * 1000) - t1
	local info = debug.getinfo(func,'S')
	print(string.format("\nTimeit: %s:%d took %d ticks", info.short_src, info.linedefined, diff))
end

function count(t)
	if type(t) == "table" or type(t) == "userdata" then
		local c = 0
		for a,b in pairs(t) do
			c = c + 1
		end
		return c
	end
end

local function sequential(t)
	local p = 1
	for i,_ in pairs(t) do
		if i ~= p then return false end
		p = p +1
	end
	return true
end

local function tabletype(t)
	if type(t) == "table" or type(t) == "userdata" then
		if count(t) == #t and sequential(t) then
			return "array"
		else
			return "hash"
		end
	end
end

-- Busted test framework extensions

local assert = require('luassert.assert')
local say = require("say")

local function is_array(_,args) return tabletype(args[1]) == "array" end
say:set("assertion.is_indexed.negative", "Expected %s to be indexed array")
assert:register("assertion", "is_indexed", is_array, "assertion.is_indexed.negative")

local function is_hash(_,args) return tabletype(args[1]) == "hash" end
say:set("assertion.is_hashed.negative", "Expected %s to be hash table")
assert:register("assertion", "is_hashed", is_hash, "assertion.is_hashed.negative")
