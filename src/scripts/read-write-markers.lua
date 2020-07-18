-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Read and write markers from/to a json file
--
-- requested by rurounijones for OverlordBot (https://forums.eagle.ru/showthread.php?p=4413013)
-------------------------------------------------------------------------------------------------------------------------------------------------------------


markers = {}

-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Global settings. Stores the script constants
-------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Identifier. All output in DCS.log will start with this.
markers.Id = "RW-MARKERS - "

--- Version.
markers.Version = "1.1.0"

-- trace level, specific to this module
markers.Trace = true

markers.RadioMenuName = "MARKERS"

-- the default name of the json markers file
markers.jsonFileName = "markers.json"

markers.randomization = 1000

-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Do not change anything below unless you know what you are doing!
-------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Radio menus paths
markers.radioRootPath = nil

-- poi groups list (table of POIGroup objects)
markers.poiGroups = {}

-- DCS markers table
markers.markersTable = {}

-- DCS marker counter
markers.markersCounter = 1000

-- DCS user markers dictionary
markers.userMarkers = {}

markers.jsonFilepath = nil

-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Utility methods
-------------------------------------------------------------------------------------------------------------------------------------------------------------

function markers.logError(message)
  veaf.logError(markers.Id .. message)
end

function markers.logWarning(message)
  veaf.logWarning(markers.Id .. message)
end

function markers.logInfo(message)
  veaf.logInfo(markers.Id .. message)
end

function markers.logDebug(message)
  veaf.logDebug(markers.Id .. message)
end

function markers.logTrace(message)
  if message and markers.Trace then 
    veaf.logTrace(markers.Id .. message)
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Event handler functions.
-------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Function executed when a mark has changed. This happens when text is entered or changed.
function markers.onEventMarkChange(eventPos, event)
  -- store the new marker data in the marker dictionary
  markers.logTrace(string.format("event=%s",veaf.p(event)))
  markers.userMarkers[event.idx] = { name=event.text, position=event.pos }
end

--- Function executed when a mark has been removed. This happens when text is entered or changed.
function markers.onEventMarkRemove(eventPos, event)
  -- remove the marker from the marker dictionary
  markers.logTrace(string.format("event=%s",veaf.p(event)))
  markers.userMarkers[event.idx] = nil
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PointOfInterest object - will be displayed as a map marker
-------------------------------------------------------------------------------------------------------------------------------------------------------------
PointOfInterest =
{
  -- the technical name of the point of interest
  name,
  -- position on the map
  position,
  -- the title that will be displayed in the point of interest
  title,
  -- the category that this point of interest belongs to (runway, parking spot, ...)
  category,
  -- the POI group that this point of interest belongs to
  group
}
PointOfInterest.__index = PointOfInterest

function PointOfInterest:new ()
  local self = setmetatable({}, PointOfInterest)
  self.name = nil
  self.position = nil
  self.title = nil
  self.category = nil
  self.group = nil
  return self
end

---
--- setters and getters
---

function PointOfInterest:setName(value)
  self.name = value
  return self
end

function PointOfInterest:getName()
  return self.name
end

function PointOfInterest:setPosition(value)
  markers.logTrace(string.format("PointOfInterest[%s]:setPosition(value=[%s])",self.name, veaf.p(value)))
  self.position = value
  return self
end

function PointOfInterest:getPosition()
  return self.position
end

function PointOfInterest:getAbsolutePosition()
  local result = { lat = self:getPosition().lat, lon = self:getPosition().lon}
  if result.lat == 0 then
    -- randomize the relative position if it's zero 
    if markers.randomization > 0 then
      markers.logTrace(string.format("PointOfInterest[%s]:getAbsolutePosition() - randomizing ",self.name))
      result.lat = (100 - math.random(0, 200)) / (markers.randomization * 100) 
      result.lon = (100 - math.random(0, 200)) / (markers.randomization * 100) 
    end
    markers.logTrace(string.format("PointOfInterest[%s]:getAbsolutePosition() - result = %s", self.name, veaf.p(result)))
    if self.group then
      if self.group:getPosition() then
        if self.group:getPosition().lat then
          markers.logTrace(string.format("PointOfInterest[%s]:getAbsolutePosition() - adding group lat ",self.name))
          result.lat = result.lat + self.group:getPosition().lat
        end
        if self.group:getPosition().lon then
          markers.logTrace(string.format("PointOfInterest[%s]:getAbsolutePosition() - adding group lon ",self.name))
          result.lon = result.lon + self.group:getPosition().lon
        end
      end
    end
  end
  markers.logTrace(string.format("PointOfInterest[%s]:getAbsolutePosition() = %s", self.name, veaf.p(result)))
  return result
end

function PointOfInterest:setTitle(value)
  markers.logTrace(string.format("PointOfInterest[%s]:setTitle(value=[%s])",self.name, veaf.p(value)))
  self.title = value
  return self
end

function PointOfInterest:getTitle()
  return self.title or self.name
end

function PointOfInterest:setCategory(value)
  markers.logTrace(string.format("PointOfInterest[%s]:setCategory(value=[%s])",self.name, veaf.p(value)))
  self.category = value
  return self
end

function PointOfInterest:getCategory()
  return self.category
end

function PointOfInterest:setGroup(value)
  self.group = value
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- POIGroup object - contains a position and a collection of PointOfInterest objects
-------------------------------------------------------------------------------------------------------------------------------------------------------------
POIGroup =
{
  -- the technical name of the PointOfInterest group
  name,
  -- position on the map
  position,
  -- the title that will be prepended to the name of the group's Points Of Interest
  title,
  -- the category of that this group belongs to (airbases, ...)
  category,
  -- the collection of PointOfInterest objects
  poiList,
}
POIGroup.__index = POIGroup

function POIGroup:new ()
  local self = setmetatable({}, POIGroup)
  self.name = nil
  self.position = nil
  self.title = nil
  self.category = nil
  self.poiList = {}
  return self
end

---
--- setters and getters
---

function POIGroup:setName(value)
  self.name = value
  return self
end

function POIGroup:getName()
  return self.name
end

function POIGroup:setPosition(value)
  markers.logTrace(string.format("POIGroup[%s]:setPosition(value=[%s])",self.name, veaf.p(value)))
  self.position = value
  return self
end

function POIGroup:getPosition()
  return self.position
end

function POIGroup:getAbsolutePosition()
  return self.position
end

function POIGroup:setTitle(value)
  markers.logTrace(string.format("POIGroup[%s]:setTitle(value=[%s])",self.name, veaf.p(value)))
  self.title = value
  return self
end

function POIGroup:getTitle()
  return self.title or self.name
end

function POIGroup:setCategory(value)
  markers.logTrace(string.format("POIGroup[%s]:setCategory(value=[%s])",self.name, veaf.p(value)))
  self.category = value
  return self
end

function POIGroup:getCategory()
  return self.category
end

function POIGroup:addPointOfInterest(poi)
  markers.logTrace(string.format("POIGroup[%s]:addPointOfInterest(value=[%s])",self.name, veaf.p(poi.name)))
  if not self.poiList then 
    self.poiList = {}
  end

  table.insert(self.poiList, poi)
  poi:setGroup(self)
  
  return self
end

function POIGroup:getPointsOfInterest()
  return self.poiList
end

function POIGroup:placeDCSMarkers()
  local function convertPositionToDCS(position)
    if not position then return nil end
    local dcsPosition = coord.LLtoLO(position.lat, position.lon)
    markers.logTrace(string.format("position [%s] converts to DCS [%s]",veaf.p(position), veaf.p(dcsPosition)))
    return dcsPosition
  end

  markers.markersCounter = veaf.logMarker(markers.markersCounter, nil, self:getTitle(), convertPositionToDCS(self:getAbsolutePosition()), markers.markersTable)
  markers.logTrace(string.format("markersCounter=%d", markers.markersCounter))
  
  for iPoi, poi in pairs(self:getPointsOfInterest()) do
    markers.markersCounter = veaf.logMarker(markers.markersCounter, nil, poi:getTitle(), convertPositionToDCS(poi:getAbsolutePosition()), markers.markersTable)
    markers.logTrace(string.format("markersCounter=%d", markers.markersCounter))
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Radio menu and help
-------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Build the initial radio menu
function markers.buildRadioMenu()
  markers.logDebug("markers.buildRadioMenu()")
  
  markers.radioRootPath = veafRadio.addMenu(markers.RadioMenuName)

  veafRadio.addCommandToSubmenu("HELP", markers.radioRootPath, markers.help, nil, veafRadio.USAGE_ForAll)
  veafRadio.addCommandToSubmenu("Get info", markers.radioRootPath, markers.GetInformations, nil, veafRadio.USAGE_ForAll)
  veafRadio.addCommandToSubmenu("Load", markers.radioRootPath, markers.LoadMarkers, nil, veafRadio.USAGE_ForAll)
  veafRadio.addCommandToSubmenu("Save", markers.radioRootPath, markers.SaveMarkers, nil, veafRadio.USAGE_ForAll)

  
  veafRadio.refreshRadioMenu()
end

function markers.help(unitName)
  local text =
    'This module manages the loading and saving of map markers\n' ..
    '\n' ..
    'It was requested by rurounijones for OverlordBot (https://forums.eagle.ru/showthread.php?p=4413013)\n' ..
    'and coded by Zip (VEAF).\n' ..
    '\n' ..
    'All the file operations are done in either %JSON_DIR%, %TEMP%, or current lfs directory\n' ..
    '  current value : ' .. markers.jsonFilepath .. '\n' ..
    '\n' ..
    'Use the MARKERS radio menu located in the VEAF main menu.\n' ..
    ' - "Load" to load the "markers.json" file\n' ..
    ' - "Save" to save the additional user markers to a file named "markers-edited.json"\n' ..
    ' - "Get info" to count the markers and the additional user markers\n' 

  trigger.action.outText(text, 30)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Core business
-------------------------------------------------------------------------------------------------------------------------------------------------------------

function markers.GetInformations(unitName)
  markers.logDebug("markers.GetInformations()")

  local nbGroups = 0
  local nbMarkers = 0
  local nbUserMarkers = 0
  for iGroups, group in pairs(markers.poiGroups) do
    nbGroups = nbGroups + 1
    for iPoi, poi in pairs(group:getPointsOfInterest()) do
      nbMarkers = nbMarkers + 1
    end
  end
  for _, value in pairs(markers.userMarkers) do
    if value then 
      nbUserMarkers = nbUserMarkers + 1
    end
  end
  local msg = string.format("Loaded %d points of interest in %d groups, and user created %d new markers", nbMarkers, nbGroups, nbUserMarkers)
  trigger.action.outText(msg, 30)
end

function markers.LoadMarkers()
  markers.logDebug("markers.LoadMarkers()")
  
  veaf.cleanupLogMarkers(markers.markersTable)
 
  local filePath = markers.jsonFilepath .. "/" .. markers.jsonFileName
  local msg = string.format("Successfully read markers from file [%s]", filePath)
  local poiGroup = readMarkersInJsonFile(filePath)
  if not(poiGroup) then
    msg = string.format("Could not read markers in file [%s]", filePath)
  else
    markers.poiGroups = { poiGroup }
    poiGroup:placeDCSMarkers()
  end
  trigger.action.outText(msg, 15)
end

function markers.SaveMarkers()
  markers.logDebug("markers.SaveMarkers()")
  local fileOutPath = markers.jsonFilepath .. "/" .. markers.jsonFileName:match("(.+)%..+") .. "-edited.json"
  local msg = string.format("Successfully saved markers to file [%s]", fileOutPath)
  local result = saveMarkersToJsonFile(fileOutPath)
  if not(result) then
    msg = string.format("Could not save markers to file [%s]", fileOutPath)
  end
  trigger.action.outText(msg, 15)
end

local function interpretPosition(luaData)
  markers.logTrace(string.format("interpretPosition([%s])",veaf.p(luaData)))
  local position = nil
  if luaData then
    position = {}
    if luaData.lat then
      position.lat = luaData.lat
    end
    if luaData.lon then
      position.lon = luaData.lon
    end
  end
  return position
end

function readMarkersInJsonFile(filePath)
  markers.logTrace(string.format("reading markers from file [%s]",tostring(filePath)))
  
  -- read the file
  local data = nil
  local f = io.open(filePath, "rb")
  if f then
    data=f:read("*all")
    f:close()
  else
    markers.logWarning(string.format("Could not load markers from file [%s]. File might not exist.", tostring(filePath)))
    return nil
  end
  
  markers.logTrace(string.format("read JSON : %s",veaf.p(data)))
  
  -- convert the JSON data
  local luaData = JSON:decode(data)
  if not luaData then
    markers.logWarning(string.format("Could not interpret JSON from file [%s].", tostring(filePath)))
    return nil
  end
  
  markers.logTrace(string.format("decoded JSON : %s",veaf.p(luaData)))
  
  -- process the lua data
  local poiGroup = 
  POIGroup:new()
          :setName(luaData.name)
          :setCategory("airbase")
          :setPosition(interpretPosition(luaData))
          :setTitle(luaData.name)

  local function processElement(luaData, poiGroup, elementName)
    for key, value in pairs(luaData[elementName]) do
      local poi = 
      PointOfInterest:new()
                     :setName(value.name)
                     :setCategory(elementName)
                     :setPosition(interpretPosition(value))
      poiGroup:addPointOfInterest(poi)
    end
    return poiGroup
  end

  -- process the runways
  processElement(luaData, poiGroup, "runways")
  -- process the junctions
  processElement(luaData, poiGroup, "junctions")
  -- process the parking spots
  processElement(luaData, poiGroup, "parkingSpots")
  
  return poiGroup
end

function saveMarkersToJsonFile(fileOutPath)
  markers.logTrace(string.format("saving markers to file [%s]",tostring(fileOutPath)))
   
  -- process the markers
  local luaData = {}
  luaData.savedPoints = {}
  for iMarker, marker in pairs(markers.userMarkers) do
    if marker then
      markers.logTrace(string.format("iMarker = %s",veaf.p(iMarker)))
      markers.logTrace(string.format("marker = %s",veaf.p(marker)))
      local point = { name = marker.name}
      point.lat, point.lon = coord.LOtoLL(marker.position)
      table.insert(luaData.savedPoints, point)
    end
  end
  markers.logTrace(string.format("processed data : %s",veaf.p(luaData)))

  -- convert the data into JSON
  data = JSON:encode_pretty(luaData)  
  if not data then
    markers.logWarning(string.format("Could not convert data back to JSON."))
    return nil
  end

  -- save the JSON data to the file
  local f = io.open(fileOutPath, "w+")
  if f then
    f:write(data)
    f:close()
    markers.logTrace(string.format("saved JSON in file [%s]",tostring(fileOutPath)))
  else
    markers.logWarning(string.format("Could not save markers to file [%s].", tostring(fileOutPath)))
    return nil
  end
  
  return true
end

function markers.initialize()
  markers.logInfo(string.format("Loading version %s", markers.Version))

  local veafSanitized_lfs = veafSanitized_lfs
  if not veafSanitized_lfs then veafSanitized_lfs = lfs end
  
  local veafSanitized_io = veafSanitized_io
  if not veafSanitized_io then veafSanitized_io = io end
  
  local veafSanitized_os = veafSanitized_os
  if not veafSanitized_os then veafSanitized_os = os end
  
  markers.jsonFilepath = veafSanitized_os.getenv("JSON_DIR")
  if not markers.jsonFilepath then
      markers.jsonFilepath = veafSanitized_os.getenv("TEMP")
  end
  if not markers.jsonFilepath then
      markers.jsonFilepath = veafSanitized_lfs.writedir()
  end
  
  markers.buildRadioMenu()
  markers.LoadMarkers()
  veafMarkers.registerEventHandler(veafMarkers.MarkerChange, markers.onEventMarkChange)
  veafMarkers.registerEventHandler(veafMarkers.MarkerRemove, markers.onEventMarkRemove)
end