PlayerPotCarringState = Class { __includes = EntityWalkState }

function PlayerPotCarringState:init(player, dungeon)
    self.entity = player
    self.dungeon = dungeon

    self.entity.offsetY = 5
    self.entity.offsetX = 0

    self.projectile = nil

    -- self.player:changeAnimation('pot-' .. self.player.direction)
end

function PlayerPotCarringState:update(dt)
    if love.keyboard.isDown('left') then
        self.entity.direction = 'left'
        self.entity:changeAnimation('pot-left')
    elseif love.keyboard.isDown('right') then
        self.entity.direction = 'right'
        self.entity:changeAnimation('pot-right')
    elseif love.keyboard.isDown('up') then
        self.entity.direction = 'up'
        self.entity:changeAnimation('pot-up')
    elseif love.keyboard.isDown('down') then
        self.entity.direction = 'down'
        self.entity:changeAnimation('pot-down')
    else
        self.entity:changeState('pot-idle')
    end

    if love.keyboard.wasPressed('return') then
        for k, object in pairs(self.dungeon.currentRoom.objects) do
            if object.solid and not (object.picked) then
                self.projectile = object
            end
        end
        if not (self.projectile == nil) then
            if love.keyboard.isDown('left') then
                self.projectile.thrownDirection = 'left'
            elseif love.keyboard.isDown('right') then
                self.projectile.thrownDirection = 'right'
            elseif love.keyboard.isDown('up') then
                self.projectile.thrownDirection = 'up'
            else
                self.projectile.thrownDirection = 'down'
            end
        end
        self.entity:changeState('walk')
    end

    EntityWalkState.update(self, dt)
end

function PlayerPotCarringState:render()
    local anim = self.entity.currentAnimation
    love.graphics.draw(gTextures[anim.texture], gFrames[anim.texture][anim:getCurrentFrame()],
        math.floor(self.entity.x - self.entity.offsetX), math.floor(self.entity.y - self.entity.offsetY))
        for k, object in pairs(self.dungeon.currentRoom.objects) do
            if object.solid and not (object.picked) then
                object.x = self.entity.x
                object.y = self.entity.y - 12
            end
    end
end
