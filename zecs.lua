local id,entities,queries,cbStack=0,{},{},{}
local function cuid()
 id+=1
 return id
end
local function assign(...)
 local result={}
 for e in all(pack(...)) do
  if type(e)=="table" then
   for k,v in next,e do
    result[k]=v
   end
  end
 end
 return result
end
local function every(table,checkFunc)
 for v in all(table) do
  if(not checkFunc(v))return
 end
 return true
end
local function tableSame(a,b)
 if(#a~=#b)return
 local hash={}
 for _,v in next,a do
  hash[v]=(hash[v] or 0)+1
 end
 for _,v in next,b do
  hash[v]=(hash[v] or 0)-1
 end
 for _,v in next,hash do
  if(v~=0)return
 end
 return true
end
local function find(table,item,compFunc)
 for k,v in next,table do
  if(compFunc(k,item))return v
 end
end
local function updateFilters(ent)
 for filter,filtered in next,queries do
  filtered[ent.id]=every(filter,function(compFactory)return ent[compFactory] end) and ent
 end
end
local function addComp(ent,comp)
 assert(not ent[comp.compFactory])
 ent[comp.compFactory]=comp
end
local function createEntity(...)
 local ent=assign{}
 ent.id,ent.isActive=cuid(),true
 setmetatable(ent,{
  __add=function(self,comp)
   QueueCb(function()
    addComp(self,comp)
    updateFilters(self)
   end)
   return self
  end,
  __sub=function(self,compFactory)
   QueueCb(function()
    self[compFactory]=nil
    updateFilters(self)
   end)
   return self
  end
 })
 for comp in all(pack(...)) do
  addComp(ent,comp)
 end
 return ent
end
SingletonEntity=createEntity()
entities[SingletonEntity.id]=SingletonEntity
function QueueCb(cb)
 add(cbStack,cb)
end
function QueryWorld(filter)
 local cached=find(queries,filter,tableSame)
 if(cached) return cached
 queries[filter]={}
 local filtered=queries[filter]
 for _,ent in next,entities do
  filtered[ent.id]=every(filter,function(compFactory)return ent[compFactory] end) and ent
 end
 return filtered
end
function QueryWorldSingle(filter)
 local filtered=QueryWorld(filter)
 for _,ent in next,filtered do
  return ent
 end
end
function Entity(...)
 local ent=createEntity(...)
 QueueCb(function()
  entities[ent.id]=ent
  updateFilters(ent)
 end)
 return ent
end
function Component(defaults)
 local function compFactory(attributes)
  local comp=assign(defaults,attributes)
  comp.compFactory=compFactory
  return comp
 end
 return compFactory
end
function System(filter,cb)
 local filtered=QueryWorld(filter)
 return function(...)
  for _,ent in next,filtered do
   if (ent.isActive) cb(ent,...)
  end
 end
end
function SetEntActive(ent,isActive)
 QueueCb(function() ent.isActive=isActive end)
end
function Remove(ent)
 QueueCb(function()
  ent.isActive,entities[ent.id]=false
  for _,filtered in next,queries do
   filtered[ent.id]=nil
  end
 end)
end
function ClearWorld()
 for _,filtered in next,queries do
  for id,__ in next,filtered do
   filtered[id]=nil
  end
 end
 entities,cbStack,id={},{},0
 SingletonEntity=createEntity()
 entities[SingletonEntity.id]=SingletonEntity
end
function UpdateWorld()
 while #cbStack>0 do
  deli(cbStack,1)()
 end
end