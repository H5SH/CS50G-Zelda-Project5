--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

Room = Class {}

function Room:init(player)
    self.width = MAP_WIDTH
    self.height = MAP_HEIGHT

    self.tiles = {}
    self:generateWallsAndFloors()

    -- entities in the room
    self.entities = {}
    self:generateEntities()

    -- game objects in the room
    self.objects = {}
    self:generateObjects()

    -- doorways that lead to other dungeon rooms
    self.doorways = {}
    table.insert(self.doorways, Doorway('top', false, self))
    table.insert(self.doorways, Doorway('bottom', false, self))
    table.insert(self.doorways, Doorway('left', false, self))
    table.insert(self.doorways, Doorway('right', false, self))

    -- reference to player for collisions, etc.
    self.player = player
    self.projectTilePicked = false

    -- used for centering the dungeon rendering
    self.renderOffsetX = MAP_RENDER_OFFSET_X
    self.renderOffsetY = MAP_RENDER_OFFSET_Y

    -- used for drawing when this room is the next room, adjacent to the active
    self.adjacentOffsetX = 0
    self.adjacentOffsetY = 0
end

--[[
    Randomly creates an assortment of enemies for the player to fight.
]]
function Room:generateEntities()
    local types = { 'skeleton', 'slime', 'bat', 'ghost', 'spider' }

    local lifeUp = GameObject(GAME_OBJECT_DEFS['heart'], 0, 0)

    lifeUp.onCollide = function()
        if lifeUp.state == 'full' then
            lifeUp.state = 'empty'
            self.player.health = self.player.health + 2
        end
    end

    for i = 1, 10 do
        local type = types[math.random(#types)]

        if i == 5 then
            table.insert(self.entities, Entity {
                animations = ENTITY_DEFS[type].animations,
                walkSpeed = ENTITY_DEFS[type].walkSpeed or 20,

                -- ensure X and Y are within bounds of the map
                x = math.random(MAP_RENDER_OFFSET_X + TILE_SIZE,
                    VIRTUAL_WIDTH - TILE_SIZE * 2 - 16),
                y = math.random(MAP_RENDER_OFFSET_Y + TILE_SIZE,
                    VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE) + MAP_RENDER_OFFSET_Y - TILE_SIZE - 16),

                width = 16,
                height = 16,

                health = 1,

                onHit = function(x, y)
                    lifeUp.x = x
                    lifeUp.y = y
                    lifeUp:render(self.adjacentOffsetX, self.adjacentOffsetY)
                    if self.player:collides(lifeUp) then
                        lifeUp:onCollide()
                    end
                end
            })
        else
            table.insert(self.entities, Entity {
                animations = ENTITY_DEFS[type].animations,
                walkSpeed = ENTITY_DEFS[type].walkSpeed or 20,

                -- ensure X and Y are within bounds of the map
                x = math.random(MAP_RENDER_OFFSET_X + TILE_SIZE,
                    VIRTUAL_WIDTH - TILE_SIZE * 2 - 16),
                y = math.random(MAP_RENDER_OFFSET_Y + TILE_SIZE,
                    VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE) + MAP_RENDER_OFFSET_Y - TILE_SIZE - 16),

                width = 16,
                height = 16,

                health = 1,
            })
        end

        self.entities[i].stateMachine = StateMachine {
            ['walk'] = function() return EntityWalkState(self.entities[i]) end,
            ['idle'] = function() return EntityIdleState(self.entities[i]) end
        }

        self.entities[i]:changeState('walk')
    end
end

--[[
    Randomly creates an assortment of obstacles for the player to navigate around.
]]
function Room:generateObjects()
    local switch = GameObject(
        GAME_OBJECT_DEFS['switch'],
        math.random(MAP_RENDER_OFFSET_X + TILE_SIZE,
            VIRTUAL_WIDTH - TILE_SIZE * 2 - 16),
        math.random(MAP_RENDER_OFFSET_Y + TILE_SIZE,
            VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE) + MAP_RENDER_OFFSET_Y - TILE_SIZE - 16)
    )

    local pot = GameObject(
        GAME_OBJECT_DEFS['pot'],
        math.random(MAP_RENDER_OFFSET_X + TILE_SIZE,
            VIRTUAL_WIDTH - TILE_SIZE * 2 - 16),
        math.random(MAP_RENDER_OFFSET_Y + TILE_SIZE,
            VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE) + MAP_RENDER_OFFSET_Y - TILE_SIZE - 16)
    )

    pot.onCollide = function()
            -- to make the barel solid
            if love.keyboard.isDown('return') and not self.projectTilePicked then
                pot.picked = false
                self.player:changeState('carry-pot')
            elseif love.keyboard.isDown('return') and self.projectTilePicked then
                self.player:changeState('walk')
            end
    
            if pot.picked == true then
            elseif self.player.direction == 'left' then
                self.player.x = pot.x + 12
            elseif self.player.direction == 'right' then
                self.player.x = pot.x - 12
            elseif self.player.direction == 'down' then
                self.player.y = pot.y - 20
            elseif self.player.direction == 'up' then
                self.player.y = pot.y + 8
            elseif love.keyboard.isDown('enter') then
                self.player:changeState('carry-pot')  
            end
    end

    pot.onDestroyed = function ()
        pot.destroyed = true
    end

    -- define a function for the switch that will open all doors in the room
    switch.onCollide = function()
        if switch.state == 'unpressed' then
            switch.state = 'pressed'

            -- open every door in the room if we press the switch
            for k, doorway in pairs(self.doorways) do
                doorway.open = true
            end

            gSounds['door']:play()
        end
    end

    -- add to list of objects in scene (only one switch for now)
    table.insert(self.objects, pot)
    table.insert(self.objects, switch)
end

--[[
    Generates the walls and floors of the room, randomizing the various varieties
    of said tiles for visual variety.
]]
function Room:generateWallsAndFloors()
    -- local potGenrated = false
    for y = 1, self.height do
        table.insert(self.tiles, {})

        for x = 1, self.width do
            local id = TILE_EMPTY

            if x == 1 and y == 1 then
                id = TILE_TOP_LEFT_CORNER
            elseif x == 1 and y == self.height then
                id = TILE_BOTTOM_LEFT_CORNER
            elseif x == self.width and y == 1 then
                id = TILE_TOP_RIGHT_CORNER
            elseif x == self.width and y == self.height then
                id = TILE_BOTTOM_RIGHT_CORNER

                -- random left-hand walls, right walls, top, bottom, and floors
            elseif x == 1 then
                id = TILE_LEFT_WALLS[math.random(#TILE_LEFT_WALLS)]
            elseif x == self.width then
                id = TILE_RIGHT_WALLS[math.random(#TILE_RIGHT_WALLS)]
            elseif y == 1 then
                id = TILE_TOP_WALLS[math.random(#TILE_TOP_WALLS)]
            elseif y == self.height then
                id = TILE_BOTTOM_WALLS[math.random(#TILE_BOTTOM_WALLS)]
                -- elseif x == math.random(self.width) and not (potGenrated) then
                --     potGenrated = true
                --     id = 110
            else
                id = TILE_FLOORS[math.random(#TILE_FLOORS)]
            end

            table.insert(self.tiles[y], {
                id = id
            })
        end
    end
end

function Room:update(dt)
    -- don't update anything if we are sliding to another room (we have offsets)
    if self.adjacentOffsetX ~= 0 or self.adjacentOffsetY ~= 0 then return end

    self.player:update(dt)

    for i = #self.entities, 1, -1 do
        local entity = self.entities[i]

        -- remove entity from the table if health is <= 0
        if entity.health <= 0 then
            entity.dead = true
        elseif not entity.dead then
            entity:processAI({ room = self }, dt)
            entity:update(dt)
        end

        for k, object in pairs(self.objects) do
            if entity:collides(object) and (object.solid and not (object.picked)) and not (object.thrownDirection == nil) then
                entity:damage(1)
                gSounds['hit-enemy']:play()
                object:onDestroyed()
            end
        end

        -- collision between the player and entities in the room
        if not entity.dead and self.player:collides(entity) and not self.player.invulnerable then
            gSounds['hit-player']:play()
            self.player:damage(1)
            self.player:goInvulnerable(1.5)

            if self.player.health == 0 then
                gStateMachine:change('game-over')
            end
        end
    end

    for k, object in pairs(self.objects) do
        object:update(dt)
        -- trigger collision callback on object
        if self.player:collides(object) and (not object.solid or  not self.projectTilePicked)then
            object:onCollide()
        end
    end
end

function Room:render()
    for y = 1, self.height do
        for x = 1, self.width do
            local tile = self.tiles[y][x]

            -- add floor before placing the pot
            if tile.id == 110 then
                love.graphics.draw(gTextures['tiles'], gFrames['tiles'][TILE_FLOORS[1]],
                    (x - 1) * TILE_SIZE + self.renderOffsetX + self.adjacentOffsetX,
                    (y - 1) * TILE_SIZE + self.renderOffsetY + self.adjacentOffsetY)
            end

            love.graphics.draw(gTextures['tiles'], gFrames['tiles'][tile.id],
                (x - 1) * TILE_SIZE + self.renderOffsetX + self.adjacentOffsetX,
                (y - 1) * TILE_SIZE + self.renderOffsetY + self.adjacentOffsetY)
        end
    end

    -- render doorways; stencils are placed where the arches are after so the player can
    -- move through them convincingly
    for k, doorway in pairs(self.doorways) do
        doorway:render(self.adjacentOffsetX, self.adjacentOffsetY)
    end

    for k, object in pairs(self.objects) do
            object:render(self.adjacentOffsetX, self.adjacentOffsetY)            
    end

    for k, entity in pairs(self.entities) do
        if not entity.dead then
            entity:render(self.adjacentOffsetX, self.adjacentOffsetY)
        else
            entity.onHit(entity.x, entity.y)
        end
    end

    -- stencil out the door arches so it looks like the player is going through
    love.graphics.stencil(function()
        -- left
        love.graphics.rectangle('fill', -TILE_SIZE - 6, MAP_RENDER_OFFSET_Y + (MAP_HEIGHT / 2) * TILE_SIZE - TILE_SIZE,
            TILE_SIZE * 2 + 6, TILE_SIZE * 2)

        -- right
        love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH * TILE_SIZE),
            MAP_RENDER_OFFSET_Y + (MAP_HEIGHT / 2) * TILE_SIZE - TILE_SIZE, TILE_SIZE * 2 + 6, TILE_SIZE * 2)

        -- top
        love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH / 2) * TILE_SIZE - TILE_SIZE,
            -TILE_SIZE - 6, TILE_SIZE * 2, TILE_SIZE * 2 + 12)

        --bottom
        love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH / 2) * TILE_SIZE - TILE_SIZE,
            VIRTUAL_HEIGHT - TILE_SIZE - 6, TILE_SIZE * 2, TILE_SIZE * 2 + 12)
    end, 'replace', 1)

    love.graphics.setStencilTest('less', 1)

    if self.player then
        self.player:render()
    end

    love.graphics.setStencilTest()

    --
    -- DEBUG DRAWING OF STENCIL RECTANGLES
    --

    -- love.graphics.setColor(255, 0, 0, 100)

    -- -- left
    -- love.graphics.rectangle('fill', -TILE_SIZE - 6, MAP_RENDER_OFFSET_Y + (MAP_HEIGHT / 2) * TILE_SIZE - TILE_SIZE,
    -- TILE_SIZE * 2 + 6, TILE_SIZE * 2)

    -- -- right
    -- love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH * TILE_SIZE),
    --     MAP_RENDER_OFFSET_Y + (MAP_HEIGHT / 2) * TILE_SIZE - TILE_SIZE, TILE_SIZE * 2 + 6, TILE_SIZE * 2)

    -- -- top
    -- love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH / 2) * TILE_SIZE - TILE_SIZE,
    --     -TILE_SIZE - 6, TILE_SIZE * 2, TILE_SIZE * 2 + 12)

    -- --bottom
    -- love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH / 2) * TILE_SIZE - TILE_SIZE,
    --     VIRTUAL_HEIGHT - TILE_SIZE - 6, TILE_SIZE * 2, TILE_SIZE * 2 + 12)

    -- love.graphics.setColor(255, 255, 255, 255)
end
