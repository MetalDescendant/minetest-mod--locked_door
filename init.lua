local function doorOpen(pos,node, hitter)
    --get the metadata since set_node removes it
    local meta = minetest.env:get_meta(pos)
    local name = meta:get_string("owner")
    local open = meta:get_int("open")
    local close = meta:get_int("close")
    local otherHalf
    local otherHalfNode
    local doorState
    if hitter:get_player_name() == name then
        if string.find(node.name, "open") then
            doorState = close
        else
            doorState = open
        end
        if string.find(node.name,"Top") then
            otherHalf= {x = pos.x, y = pos.y-1, z = pos.z}
            if node.name == "locked_door:lockedDoorTop" then
                newName = "locked_door:openDoorTop"
                otherNewName = "locked_door:openDoor"
            elseif node.name == "locked_door:openDoorTop" then
                newName = "locked_door:lockedDoorTop"
                otherNewName = "locked_door:lockedDoor"
            end
        else
            otherHalf = {x = pos.x, y = pos.y+1, z = pos.z}
            if node.name == "locked_door:lockedDoor" then
                newName = "locked_door:openDoor"
                otherNewName = "locked_door:openDoorTop"
            elseif node.name == "locked_door:openDoor" then
                newName = "locked_door:lockedDoor"
                otherNewName = "locked_door:lockedDoorTop"
            end
        end
        minetest.env:set_node(pos,{name=newName, param1=node.param1, param2 = doorState})
        otherHalfNode = minetest.env:get_node(otherHalf)
        minetest.env:set_node(otherHalf,{name=otherNewName, param1=otherHalfNode.param1, param2 = doorState})
        --reset metadata
        meta:set_string("owner",name)
        meta:set_int("open",open)
        meta:set_int("close",close)
        if string.find(otherHalfNode.name,"locked_door") then
            meta = minetest.env:get_meta(otherHalf)
            meta:set_string("owner",name)
            meta:set_int("open",open)
            meta:set_int("close",close)
        end
    end
end

local function doorInit(pos, placer)
    local meta = minetest.env:get_meta(pos)
    local above = {x=pos.x,y=pos.y+1,z=pos.z}
    local aboveNode = minetest.env:get_node(above) 
    if aboveNode.name ~= "air" then
        above.y = pos.y
        pos = {x=above.x,y=above.y-1,z=above.z}
        local node = minetest.env:get_node(pos)
        if  node.name ~= "air" then
            --needs to be fixed. just makes door disappear and doesn't
            --add back to inventory
            minetest.env:set_node(above,{name="locked_door:lockedDoor"})
            aboveNode = minetest.env:get_node(above)
            minetest.node_dig(above,aboveNode,placer)
            return
        end
    end
    local dir = placer:get_look_dir()
    local doorDir = minetest.dir_to_wallmounted({x=dir.x,y=0,z=dir.z})
    local doorOpenDir = minetest.dir_to_wallmounted({x=-dir.z,y=0,z=dir.x})
    minetest.env:set_node(pos,{name="locked_door:lockedDoor", nil, param2 = doorDir})
    meta:set_string("owner",placer:get_player_name())
    meta:set_int("open",doorOpenDir)
    meta:set_int("close",doorDir)
    meta = minetest.env:get_meta(above)
    minetest.env:set_node(above,{name="locked_door:lockedDoorTop", nil, param2 = doorDir})
    meta:set_string("owner",placer:get_player_name())
    meta:set_int("open",doorOpenDir)
    meta:set_int("close",doorDir)
end

local function doorDig (pos, node, digger)
    if node.name == "locked_door:openDoor" or 
       node.name == "locked_door:lockedDoor" then
        local above = {x=pos.x,y=pos.y+1,z=pos.z}
        aboveNode = minetest.env:get_node(above)
        minetest.node_dig(above,aboveNode,digger)
    else
        local below= {x=pos.x,y=pos.y-1,z=pos.z}
        belowNode = minetest.env:get_node(below)
        minetest.node_dig(below,belowNode,digger)
    end
    minetest.node_dig(pos,node,digger)
end

local function doorDigCheck(pos, player)
    local owner = minetest.env:get_meta(pos):get_string("owner")
    return owner == player.name
end

local lockedDoorProperties = {
    description = "locked door",
    tiles = {"locked_door_bottom.png"},
    inventory_image = "locked_door.png",
    sunlight_propagates = true, 
    paramtype="light",
    paramtype2 = "wallmounted",
    groups = {immortal=1},
    walkable = true,
    diggable = true,
    climbable = false,
    drop = "locked_door:lockedDoor",
    drawtype = "signlike",
    on_punch = doorOpen,
    on_dig = doorDig,
    can_dig = doorDigCheck,
    after_place_node = doorInit}

local unlockedDoorProperties = {}
local lockedDoorTopProperties = {}
local unlockedDoorTopProperties = {}
--creates a deep copy since they're all similar except
--for a couple of properties
for key, value in pairs(lockedDoorProperties) do
    unlockedDoorProperties[key] = value
    lockedDoorTopProperties[key] = value 
    unlockedDoorTopProperties[key] = value 
end

unlockedDoorProperties.walkable = false
unlockedDoorProperties.groups = {crumbly=3}
unlockedDoorTopProperties.walkable = false
unlockedDoorTopProperties.groups = {crumbly=3}
lockedDoorTopProperties.tiles = {"locked_door_top.png"}
lockedDoorTopProperties.drop = ""
unlockedDoorTopProperties.tiles = {"locked_door_top.png"}
unlockedDoorTopProperties.drop = ""


minetest.register_node("locked_door:lockedDoor", lockedDoorProperties)
minetest.register_node("locked_door:lockedDoorTop", lockedDoorTopProperties)
minetest.register_node("locked_door:openDoor", unlockedDoorProperties)
minetest.register_node("locked_door:openDoorTop", unlockedDoorTopProperties)

minetest.register_craft({
    output = "locked_door:lockedDoor",
    recipe = {
        {'default:wood', 'default:wood'},
        {'default:wood', 'default:steel_ingot'},
        {'default:wood', 'default:wood'}
    },
})
