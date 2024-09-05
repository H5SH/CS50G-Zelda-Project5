--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

GameObject = Class{}

function GameObject:init(def, x, y)
    
    -- string identifying this object type
    self.type = def.type

    self.texture = def.texture
    self.frame = def.frame or 1

    -- whether it acts as an obstacle or not
    self.solid = def.solid
    self.destroyed = false

    self.defaultState = def.defaultState
    self.state = self.defaultState
    self.states = def.states
    self.thrownDirection = nil
    self.picked = false


    -- dimensions
    self.dx = 100
    self.dy = 100
    self.x = x
    self.y = y
    self.width = def.width
    self.height = def.height

    -- default empty collision callback
    self.onCollide = function() end
    self.onDestroyed = function () end
end

function GameObject:update(dt)
    if not (self.thrownDirection == nil) then
        if self.thrownDirection == 'left' then
            self.x = self.x - self.dx * dt
        elseif self.thrownDirection == 'right' then
            self.x = self.x + self.dx * dt
        elseif self.thrownDirection == 'up' then
            self.y = self.y - self.dy * dt
        else
            self.y = self.y + self.dy * dt
        end
    end
end

function GameObject:render(adjacentOffsetX, adjacentOffsetY)
    if not self.destroyed and (not (self.solid) or not (self.picked) or not (self.thrownDirection == nil)) then
        love.graphics.draw(gTextures[self.texture], gFrames[self.texture][self.states[self.state].frame or self.frame],
            self.x + adjacentOffsetX, self.y + adjacentOffsetY)
    end
end