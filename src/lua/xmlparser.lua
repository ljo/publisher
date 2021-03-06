--
--  xmlparser.lua
--  publisher
--
--  Copyright 2011 Patrick Gundlach.
--  See file COPYING in the root directory for license details.

local xmlreader = xmlreader
local w = w
local setmetatable,tostring,print = setmetatable,tostring,print
local table,string = table,string

module(...)

-- the root node for additional namespace information (the function prefix)
local root = nil

-- Return the textvalue of an element (tostring(xml))
local function xml_to_string( self )
  local ret = {}
  for i=1,#self do
    ret[#ret + 1] = tostring(self[i])
  end
  return table.concat(ret)
end

local mt = {
  __tostring = xml_to_string
}

function read_element(r)
  local ret = {}
  -- we set the global root element if unset to store ns info
  root = root or ret

  setmetatable(ret,mt)
  ret[".__name"] = r:local_name()

  while (r:move_to_next_attribute()) do
    if r:is_namespace_declaration() then
      root["__namespace"] = root["__namespace"] or {}
      root["__namespace"][string.gsub(r:name(),"^xmlns:?","")] = r:value()
    else
      ret[r:name()] = r:value()
    end
  end
  r:move_to_element()

  if r:is_empty_element() then
    return ret
  end

  while (r:read()) do
    if r:node_type() == 'element' then
      ret[#ret + 1] = read_element(r)
      ret[#ret][".__parent"] = ret
    elseif r:node_type() == 'end element' then
      return ret
    elseif r:node_type() == 'text' then
      ret[#ret + 1] = r:value()
    elseif r:node_type() == 'significant whitespace' then
      ret[#ret + 1] = ' '
    elseif r:node_type() == "comment" then
      -- ignorieren
    else
      warning("xmlparser: unknown node type found: %s",r:node_type())
    end
  end
  return ret
end

function parse(r)
  local ret
  -- jump over comments
  while r:read() do
    if (r:node_type() == 'element') then
      ret = read_element(r)
    end
  end
  if r:read_state() == "error" then
    print("Error!")
  end
  return ret
end

function parse_xml_file( filename )
  root = nil
  local r = xmlreader.from_file(filename,nil,{"nocdata","xinclude","nonet"})
  return parse(r)
end

function parse_xml(txt)
  root = nil
  local r = xmlreader.from_string(txt,nil,nil,{"nocdata","xinclude","nonet"})
  return parse(r)
end
