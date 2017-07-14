
local it = 0
kMapUsedPrefix = ""
local mmp_table = {
  [ "mvm_sg_" ] = function()
    kMapUsedPrefix = "mvm"
    return "34aa8aec"
  end,
  [ "ava_sg_" ] = function()
    kMapUsedPrefix = "ava"
    return "34aa8aec"
  end,
  [ "at_sg_" ] = function()
    return "34aa8aec"
  end
}

do
  local function string_starts(String,Start)
     return string.sub(String,1,string.len(Start))==Start
  end
  local oldServerStartWorld = Server.StartWorld
  Server.StartWorld = function( mods, mapName )
    if (it % 2 == 0) then
      it = it + 1
      for prefix, publish_id in pairs(mmp_table) do
        if string_starts( mapName and mapName or "", prefix ) then
          mapName = "sg_" .. string.sub( mapName, string.len( prefix ) + 1 )
          kMapUsedPrefix = ""
          Log("Mod Map prefix is replacing load with: " .. mapName)
          mods[#mods + 1] = publish_id()
        end
      end
      oldServerStartWorld(mods, mapName and mapName or "")
      it = it + 1
    end
  end
end

do
  Event.Hook( "ClientConnect", 
    function(client)

      local infIndex = Server.GetNumMaps() + 1
      for i = 1, Server.GetNumMaps() do

         for prefix, publish_id in pairs(mmp_table) do
            local mapName = prefix .. string.sub( Server.GetMapName(i), string.len( "sg_" ) + 1 )
            if MapCycle_GetMapIsInCycle(mapName) then
               Server.SendNetworkMessage( client, "AddVoteMap", { name = mapName, index = infIndex }, true )
               infIndex = infIndex + 1
            end
         end

      end
    end
  )

  local kExecuteVoteDelay = 10
  local function OnChangeMapVoteSuccessful(data)

    if data.map_index > Server.GetNumMaps() then
      local infIndex = Server.GetNumMaps() + 1
      for i = 1, Server.GetNumMaps() do
        for prefix, publish_id in pairs(mmp_table) do
          local mapName = prefix .. string.sub( Server.GetMapName(i), string.len( "sg_" ) + 1 )
          if MapCycle_GetMapIsInCycle(mapName) then
            if infIndex == data.map_index then
              MapCycle_ChangeMap(mapName)
              return
            end
            infIndex = infIndex + 1
          end
        end
      end
    end

  MapCycle_ChangeMap(Server.GetMapName(data.map_index))
  end
  SetVoteSuccessfulCallback("VoteChangeMap", kExecuteVoteDelay, OnChangeMapVoteSuccessful)

end
