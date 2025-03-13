-- title:  Ball Up
-- author: Terry Brashaw
-- desc:   Throw splits with yuh brody.
-- script: lua

DEBUG = false
PLAY_P1 = true
PLAY_P2 = true
PSPEED = 56
WIDTH = 30 * 8
HEIGHT = 17 * 8
shakems = 0
shakestr = 0
bounds = { 1.5 * 8, 29 * 8, 15 * 8, 1 * 8 }

function enum(tbl)
	for i, val in ipairs(tbl) do
		tbl[val] = i
	end
	return tbl
end

Action = enum({ "None", "Hook", "Revive" })

function L(step)
	return bounds[4] + (bounds[2] - bounds[4]) / 16 * step
end
function R(step)
	return bounds[2] - (bounds[2] - bounds[4]) / 16 * step
end
function T(step)
	return bounds[1] + (bounds[3] - bounds[1]) / 16 * step
end
function B(step)
	return bounds[3] - (bounds[3] - bounds[1]) / 16 * step
end

function Radius(r)
	return 1 + 2 ^ r
end

function Player(x)
	return {
		pos = x,
		hook = nil,
		isHolding = false,
		isIdle = true,
		isAlive = true,
		dir = 0,
		intent = Action.None,
		safe = 0,
	}
end

function Ball(p, l, px, py, vx, vy)
	return { pos = { px, py }, vel = { vx, vy }, acc = { 0, 250 }, l = l, r = Radius(l), p = p, vis = 0 }
end

function Level01()
	return Player(L(1)), Player(R(1)), { Ball(2, 1, L(4), B(4), PSPEED, 0), Ball(1, 1, R(4), B(4), -PSPEED, 0) }
end

function Level02()
	return Player(L(1)), Player(R(1)), { Ball(1, 1, L(4), B(4), PSPEED, 0), Ball(2, 1, R(4), B(4), -PSPEED, 0) }
end

function Level03()
	return Player(L(3)), Player(R(3)), { Ball(2, 2, L(4), B(4), PSPEED, 0), Ball(1, 2, R(4), B(4), -PSPEED, 0) }
end

function Level04()
	return Player(L(3)),
		Player(R(3)),
		{
			Ball(1, 1, L(4), B(5), 0, 0),
			Ball(2, 1, R(4), B(5), 0, 0),
			Ball(2, 2, L(6), B(5), PSPEED, 0),
			Ball(1, 2, R(6), B(5), -PSPEED, 0),
		}
end

function Level05()
	return Player(L(3)), Player(R(3)), { Ball(2, 4, L(4), B(10), PSPEED, 0), Ball(1, 4, R(4), B(10), -PSPEED, 0) }
end

function Level06()
	return Player(L(5)),
		Player(R(5)),
		{
			Ball(1, 4, L(2), B(10), -PSPEED, 0),
			Ball(2, 4, R(2), B(10), PSPEED, 0),
			Ball(1, 4, R(5), B(10), -PSPEED, 0),
			Ball(2, 4, L(5), B(10), PSPEED, 0),
		}
end

function Level07()
	return Player(L(2)),
		Player(L(3)),
		{
			Ball(1, 4, R(2), B(13), 0, 0),
			Ball(2, 4, R(5), B(13), 0, 0),
			Ball(1, 4, R(8), B(13), 0, 0),
			Ball(2, 4, R(2), B(6), 0, 0),
		}
end

function Level08()
	return Player(L(3)),
		Player(L(4)),
		{
			Ball(2, 4, R(2), B(13), -PSPEED, 0),
			Ball(1, 4, R(3), B(11), -PSPEED, 0),
			Ball(2, 4, R(4), B(9), -PSPEED, 0),
			Ball(1, 4, R(5), B(7), -PSPEED, 0),
			Ball(2, 4, R(6), B(5), -PSPEED, 0),
			Ball(1, 4, R(7), B(3), -PSPEED, 0),
		}
end

function Level09()
	return Player(L(0.5)),
		Player(L(1)),
		{
			Ball(1, 4, R(2), B(10), PSPEED, 0),
			Ball(2, 4, R(4.5), B(9), PSPEED, 0),
			Ball(1, 4, R(7), B(8), PSPEED, 0),
			Ball(2, 4, R(9.5), B(7), PSPEED, 0),
			Ball(1, 4, R(12), B(6), PSPEED, 0),
			Ball(2, 4, R(14.5), B(5), PSPEED, 0),
		}
end

function Level10()
	return Player(L(3)), Player(R(3)), { Ball(1, 1, R(3), B(4), 0, 0) }
end

levels = { Level01, Level02, Level03, Level04, Level05, Level06, Level07, Level08, Level09
, Level10 }

Transition = enum({ "Up", "Down", "None" })

t = 0
balls = {}
deadballs = {}
level = 2
lstart = 1
p1, p2, balls = levels[level]()
ltrans = Transition.None
ttrans = 0

function PointSphere(p, s)
	local a = p[1] - (s.pos[1] + 1)
	local b = p[2] - (s.pos[2] + 1)
	local len = math.sqrt(a ^ 2 + b ^ 2)
	return len <= s.r
end

function Clamp(val, min, max)
	if val < min then
		return min
	end
	if val > max then
		return max
	end
	return val
end

function RectRect(a, b)
	return a.pos[1] < b.pos[1] + b.w
		and a.pos[2] < b.pos[2] + b.h
		and b.pos[1] < a.pos[1] + a.w
		and b.pos[2] < a.pos[2] + a.h
end

function RectSphere(r, s)
	local x = Clamp(s.pos[1] + 1, r.pos[1], r.pos[1] + r.w)
	local y = Clamp(s.pos[2] + 1, r.pos[2], r.pos[2] + r.h)
	return PointSphere({ x, y }, s)
end

function PlayerHitBox(p)
	return { pos = { p.pos - 3, bounds[3] - 4 }, w = 6, h = 4 }
end

function PlayerHelpBox(p)
	return { pos = { p.pos - 4, bounds[3] - 4 }, w = 8, h = 4 }
end

function Len(t)
	local len = 0
	for _ in pairs(t) do
		len = len + 1
	end
	return len
end

function IsEmpty(t)
	for _ in pairs(t) do
		return false
	end
	return true
end

-------- UPDATE --------

function UpdateGame(dt)
	shakems = shakems - dt * 1000
	lstart = Clamp(lstart + dt * 1, 0, 1)

	if not p1.isAlive and not p2.isAlive then
		ttrans = 1
		ltrans = Transition.Down
	elseif IsEmpty(balls) and IsEmpty(deadballs) then
		ttrans = 1
		ltrans = Transition.Up
	end

	-- Update the dead balls
	for i, ball in pairs(deadballs) do
		ball.hit = ball.hit - dt / 0.2
		if ball.hit <= 0 then
			deadballs[i] = nil
			if ball.l >= 2 then
				local l = ball.l - 1
				local cvel = 1.2
				local cacc = 1.1
				table.insert(
					balls,
					{
						pos = { ball.pos[1], ball.pos[2] },
						vel = { ball.vel[1], -150 },
						acc = { ball.acc[1], ball.acc[2] * cacc },
						l = l,
						r = Radius(l),
						p = ball.p,
					}
				)
				table.insert(
					balls,
					{
						pos = { ball.pos[1], ball.pos[2] },
						vel = { ball.vel[1] * -1, -150 },
						acc = { ball.acc[1], ball.acc[2] * cacc },
						l = l,
						r = Radius(l),
						p = ball.p,
					}
				)
			end
		end
	end

	-- Update the alive balls
	function HitTime(dist, vel, acc)
		if acc == 0 then
			return dist / vel
		else
			return (-2 * vel + math.sqrt(4 * vel ^ 2 + 8 * acc * dist)) / (2 * acc)
		end
	end
	for i, ball in pairs(balls) do
		--break
		local htBot = HitTime(bounds[3] - (ball.pos[2] + ball.r), ball.vel[2], ball.acc[2])
		local rt = dt
		if htBot <= dt then
			ball.pos[2] = ball.pos[2] + ball.vel[2] * htBot + ball.acc[2] * htBot * htBot * 0.5
			--ball.vel[2]=ball.vel[2]+ball.acc[2]*htBot
			--ball.vel[2]=ball.vel[2]*-1
			ball.vel[2] = -75 - (ball.l - 1) * 25
			rt = dt - htBot
		end

		ball.pos[2] = ball.pos[2] + ball.vel[2] * rt + ball.acc[2] * rt * rt * 0.5
		ball.vel[2] = ball.vel[2] + ball.acc[2] * rt

		local htLeft = HitTime(bounds[4] - (ball.pos[1] - ball.r), ball.vel[1], ball.acc[1])
		local rt = dt
		if htLeft > 0 and htLeft <= dt then
			ball.pos[1] = ball.pos[1] + ball.vel[1] * htLeft + ball.acc[1] * htLeft * htLeft * 0.5
			ball.vel[1] = ball.vel[1] + ball.acc[1] * htLeft
			ball.vel[1] = ball.vel[1] * -1
			rt = dt - htLeft
		end

		local htRight = HitTime(bounds[2] - (ball.pos[1] + ball.r), ball.vel[1], ball.acc[1])
		local rt = dt
		if htRight > 0 and htRight <= dt then
			ball.pos[1] = ball.pos[1] + ball.vel[1] * htRight + ball.acc[1] * htRight * htRight * 0.5
			ball.vel[1] = ball.vel[1] + ball.acc[1] * htRight
			ball.vel[1] = ball.vel[1] * -1
			rt = dt - htRight
		end

		ball.pos[1] = ball.pos[1] + ball.vel[1] * rt + ball.acc[1] * rt * rt * 0.5
		ball.vel[1] = ball.vel[1] + ball.acc[1] * rt
	end

	-- update player
	p1.isIdle = true
	p2.isIdle = true

	if btn(2) then
		if p1.isAlive then
			p1.pos = p1.pos - PSPEED * dt
			p1.isIdle = false
		end
		p1.dir = 1
	end
	if btn(3) then
		if p1.isAlive then
			p1.pos = p1.pos + PSPEED * dt
			p1.isIdle = false
		end
		p1.dir = 0
	end

	if btn(11) or key(4) then
		if p2.isAlive then
			p2.pos = p2.pos + PSPEED * dt
			p2.isIdle = false
		end
		p2.dir = 0
	end
	if btn(10) or key(1) then
		if p2.isAlive then
			p2.pos = p2.pos - PSPEED * dt
			p2.isIdle = false
		end
		p2.dir = 1
	end

	p1.pos = Clamp(p1.pos, bounds[4] + 4, bounds[2] - 4)
	p2.pos = Clamp(p2.pos, bounds[4] + 4, bounds[2] - 4)

	p1.safe = p1.safe - dt * 1000
	p2.safe = p2.safe - dt * 1000

	function ShootHook(p, op, press, sfxoffset)
		if not press then
			p.isHolding = false
			return
		end
		if not p.isAlive then
			return
		end

		if not op.isAlive and not p.isHolding and RectRect(PlayerHelpBox(p), PlayerHelpBox(op)) then
			sfx(8, "C-5")
			op.isAlive = true
			op.safe = 150
			p.isHolding = true
		elseif p.hook == nil and not p.isHolding then
			sfx(6, 60 + sfxoffset)
			p.hook = { p.pos, 0 }
			p.isHolding = true
		end
	end

	ShootHook(p1, p2, btn(4) or key(58), 2)
	ShootHook(p2, p1, btn(12) or key(23), -4)

	function IntersectHook(p, pt)
		if p.hook ~= nil then
			p.hook[2] = p.hook[2] + 120 * dt
			if bounds[3] - p.hook[2] <= bounds[1] then
				p.hook = nil
				return
			end

			local hook = { pos = { p.hook[1] - 2, bounds[3] - p.hook[2] }, w = 4, h = p.hook[2] }
			for i, ball in pairs(balls) do
				if ball.p == pt and RectSphere(hook, ball) then
					p.hook = nil
					sfx(6, nil, 0)
					sfx(2, 50 - math.floor(ball.r * 1.5), 20, 1)
					ball.hit = 1.0
					balls[i] = nil
					table.insert(deadballs, ball)
					shakems = math.max(shakems, ball.l * 50)
					shakestr = ball.l
					break
				end
			end
		end
	end

	IntersectHook(p1, 1)
	IntersectHook(p2, 2)

	-- ball ceiling collision
	for i, ball in pairs(balls) do
		if ball.pos[2] - ball.r <= bounds[1] then
			sfx(2, 50 - math.floor(ball.r * 1.5), 20, 1)
			ball.hit = 1.0
			balls[i] = nil
			table.insert(deadballs, ball)
			shakems = math.max(shakems, ball.l * 50)
			shakestr = math.max(shakestr, ball.l)
		end
	end

	-- Ball/player collisions
	for _, ball in pairs(balls) do
		if p1.isAlive and p1.safe <= 0 and PLAY_P1 and RectSphere(PlayerHitBox(p1), ball) then
			p1.isAlive = false
			p1.isIdle = false
			p2.isIdle = true
			shakems = 0
			sfx(2, "C-8", -1, 1)
			sfx(5, "C-6")
		end
		if p2.isAlive and p2.safe <= 0 and PLAY_P2 and RectSphere(PlayerHitBox(p2), ball) then
			p2.isAlive = false
			p2.isIdle = false
			p1.isIdle = true
			shakems = 0
			sfx(2, "C-8", -1, 1)
			sfx(5, "C-5")
		end
	end
end

function RenderGame()
	cls(0)
	function background(tile)
		if fget(tile, 0) then
			return tile
		else
			return 0
		end
	end
	map(0, 0, 30, 17, 0, 0, 0, 1, background)

	if shakems > 0 then
		local istr = math.ceil(shakestr)
		poke(0x3FF9 + 0, math.random(-istr, istr))
		poke(0x3FF9 + 1, math.random(-istr, istr))
	else
		poke(0x3FF9 + 0, 0)
		poke(0x3FF9 + 1, 0)
	end

	print(level, 16, 20, 9, false, 5)

	-- render balls
	function RenderBall(i, ball, body, tail)
		if lstart >= 1.0 then
			for t = 0, 3 do
				circ(
					ball.pos[1] - ball.vel[1] * (t + 1) * (1.0225 ^ ball.r) * dt,
					ball.pos[2] - ball.vel[2] * (t + 1) * (1.0225 ^ ball.r) * dt,
					ball.r * 0.915 ^ t,
					tail
				)
			end
		end
		circ(ball.pos[1], ball.pos[2], Clamp(i * 0.05 + lstart, 0, 1) * ball.r, body)
	end

	for i, ball in pairs(balls) do
		if ball.p == 1 then
			RenderBall(i, ball, 3, 4)
		elseif ball.p == 2 then
			RenderBall(i, ball, 11, 12)
		end
	end

	function RenderDeadBall(ball, c)
		local a = 66
		if t % a > a / 2 then
			c = 8
		end
		circ(ball.pos[1], ball.pos[2], ball.r, c)
	end

	for _, ball in pairs(deadballs) do
		if ball.p == 1 then
			RenderDeadBall(ball, 3)
		elseif ball.p == 2 then
			RenderDeadBall(ball, 11)
		end
	end

	-- render hook
	function RenderHook(p, tip, shaft)
		if p.hook ~= nil then
			spr(tip, p.hook[1] - 4, bounds[3] - p.hook[2], 0)
			local len = p.hook[2] - 8
			while len > -8 do
				spr(shaft, p.hook[1] - 4, bounds[3] - len, 0)
				len = len - 8
			end
		end
	end

	RenderHook(p1, 273, 289)
	RenderHook(p2, 272, 288)

	-- render map
	function foreground(tile)
		if fget(tile, 0) then
			return 0
		else
			return tile
		end
	end

	map(0, 0, 30, 17, 0, 0, 0, 1, foreground)

	-- render player
	function RenderPlayer(p, idle)
		if not p.isAlive then
			spr(idle + 1 + t / 250 % 2, p.pos - 4, bounds[3] - 8, 0, 1, p.dir)
		elseif p.isIdle then
			spr(idle, p.pos - 4, bounds[3] - 8, 0, 1, p.dir)
		else
			local y = (1 - math.abs(math.cos(t / 80) ^ 5)) * 2 - 1
			spr(idle, p.pos - 4, bounds[3] - 8 - y, 0, 1, p.dir)
		end
	end

	RenderPlayer(p1, 274)
	RenderPlayer(p2, 290)

	-- render revive
	if not p1.isAlive and RectRect(PlayerHelpBox(p1), PlayerHelpBox(p2)) then
		spr(277 + t / 80 % 5, p1.pos - 4, bounds[3] - 16, 0)
	end
	if not p2.isAlive and RectRect(PlayerHelpBox(p1), PlayerHelpBox(p2)) then
		spr(293 + t / 80 % 5, p2.pos - 4, bounds[3] - 16, 0)
	end

	-- render hit
	local hx = 20
	local hy = 28
	if not p1.isAlive and not p2.isAlive then
		local c = hx
		c = c + print("Red", c, hy, 2)
		c = c + print(" and ", c, hy, 7)
		c = c + print("Blue", c, hy, 10)
		c = c + print(" down", c, hy, 7)
	elseif not p1.isAlive then
		local c = hx
		c = c + print("Red", c, hy, 2)
		c = c + print(" down", c, hy, 7)
	elseif not p2.isAlive then
		local c = hx
		c = c + print("Blue", c, hy, 10)
		c = c + print(" down", c, hy, 7)
	end
end

function RenderTransition() end

function TIC()
	local now = time()
	dt = (now - t) / 1000
	t = now

	-- RENDERING --
	if ltrans == Transition.None then
		UpdateGame(dt)
		RenderGame()
	elseif ltrans == Transition.Up then
		ttrans = ttrans - 1.05 * dt
		if ttrans <= 0 then
			ltrans = Transition.None
			level = Clamp(level + 1, 1, #levels)
			p1, p2, balls = levels[level]()
			shakems = 0
			deadballs = {}
		else
			cls(0)
			map(0, 0, 30, 17, 0, (-ttrans ^ 2 + 1) * HEIGHT)
			map(0, 0, 30, 17, 0, (-ttrans ^ 2 + 1) * HEIGHT - HEIGHT)
		end
	elseif ltrans == Transition.Down then
		ttrans = ttrans - 1.05 * dt
		if ttrans <= 0 then
			ltrans = Transition.None
			level = Clamp(level - 1, 1, #levels)
			p1, p2, balls = levels[level]()
			deadballs = {}
		else
			cls(0)
			map(0, 0, 30, 17, 0, (-ttrans ^ 2 + 1) * -HEIGHT)
			map(0, 0, 30, 17, 0, (-ttrans ^ 2 + 1) * -HEIGHT + HEIGHT)
		end
	end
end
