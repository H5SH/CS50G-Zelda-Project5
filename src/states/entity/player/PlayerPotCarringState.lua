



PlayerPotCarringState = Class{__includes = EntityWalkState}

function PlayerPotCarringState:init(player, dungeon)
    self.entity = player
    self.dungeon = dungeon

    self.entity.offsetY = 5
    self.entity.offsetX = 0

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
        self.entity:changeState('idle')
    end

    EntityWalkState.update(self, dt)
end

function PlayerPotCarringState:render()
    local anim = self.entity.currentAnimation
    love.graphics.draw(gTextures[anim.texture], gFrames[anim.texture][anim:getCurrentFrame()], 
math.floor(self.entity.x - self.entity.offsetX), math.floor(self.entity.y - self.entity.offsetY))
end