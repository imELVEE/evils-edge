pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
function _init()
	cls()
	floor = 100
	init_player()
	mouse.init()
	
	bullets = {}
	grapple_points = {init_grapple(80,40,40)}
	
	init_level_1()
end

function _update()
	if (player.x > 120) then
		floor = level_1_floor[ceil(player.x/8)]*8 - 15
	else
		floor = 100
	end
	gravity(player)
	bullet_travel()

	grapple(player)
	move(player)
	jump(player)
	shoot(player)
	
	camera_follow()
	restart_check()
end

function _draw()
	cls()
	map()
	draw_map(level_1_floor)
	draw_sprite(player)
	draw_target()
	draw_bullets()
	draw_grapple_points(grapple_points)
	draw_grapple_line(player)

	//print(player.grapple_to, player.x, player.y, 7)
	//print(player.state,32,60, 7)
	//print(player.x,32,80,7)
	//print (player.gravity, player.x + 20, player.y, 7)
	//if (player.x >= 10) then
	//	print(floor,player.x,floor,7)
	//end
end
-->8
// world logic
function gravity(unit)
	if (unit.jump_cycle >= unit.cycle_limit or unit.state != 'jump') then
		unit.gravity = true
	end

	if (unit.gravity) then
		if (floor_check(unit)) then
			unit.jump_cycle = 0
			unit.y = floor
		else
			unit.y += 5
		end
	end
end

function bullet_travel()
	for i,b in ipairs(bullets) do
		b.x += b.x_inc
		b.y = b.formula(b.x)
		if (b.x >= 120 or b.x <= -1 or b.y >= floor+5 or b.y <= -1) then
			del(bullets,b)
		end
	end
end

function camera_follow()
	cam_x = player.x  - 34
	if (cam_x < 0) then
		cam_x = 0
	end
	if (cam_x > 1024-34) then
		cam_x = 1024-34
	end
	
	camera(cam_x)
end

function restart_check()
	if (player.y > 120) then
		_init()
	end
end
-->8
// animation logic
function draw_sprite(unit)
	palt(0, false)
	palt(15, true)
	
	if (unit.state == 'idle') then
		cycle_idle_frames(unit)
	elseif (unit.state == 'move') then
		cycle_move_frames(unit)
	elseif (unit.state == 'jump') then
		cycle_jump_frames(unit)
	else
		spr(96,unit.x,unit.y,2,2)
	end
	
	palt()
end

function cycle_idle_frames(unit)
	spr(unit.idle_frames[flr(unit.idle_frame)], unit.x, unit.y, 2, 2, unit.flip_bool)
	unit.idle_frame += unit.idle_inc
	if (unit.idle_frame >= unit.idle_limit) then
		unit.idle_frame = 1
	end
end
		
function cycle_move_frames(unit)
	spr(unit.run_frames[flr(unit.run_frame)], unit.x, unit.y, 2, 2, unit.flip_bool)
	unit.run_frame += unit.run_inc
	if (unit.run_frame >= unit.run_limit) then
		unit.run_frame = 1
	end
end

function cycle_jump_frames(unit)
	if (unit.y >= floor-3) then
		spr(unit.crouch_frames[1], unit.x, unit.y, 2, 2, unit.flip_bool)
	else
		spr(unit.jump_style[flr(unit.jump_frame)], unit.x, unit.y, 2, 2, unit.flip_bool)
		unit.jump_frame += unit.jump_inc
		if (unit.jump_frame >= unit.jump_limit) then
			unit.jump_frame = 1
		end
	end
end

function draw_target()
	mx,my = mouse.pos()
	rect(mx,my,mx+9,my+9,7)
end

function draw_bullets()
	for i,b in ipairs(bullets) do
		spr(16,b.x,b.y)
	end
end

function draw_grapple_points()
	for i,g in ipairs(grapple_points) do
		spr(1, g.x-4, g.y-4)
		circ(g.x, g.y, g.radius, 10)
	end
end

function draw_grapple_line(unit)
	if (unit.grapple_to != nil) then
		local g_point = unit.grapple_to
		line(unit.x, unit.y, g_point.x, g_point.y, 7)
	end
end

function draw_map(floor_map)
	for i,v in ipairs(floor_map) do
		if (i > 15) then
			mset(i,v,129)
			for h = 0, 16 do
				if (h != v) then
					mset(i,h,128)
				end
			end
		end
	end
end
-->8
// char logic
function move(unit)
	x_increment = 0
	
	if (floor_check(unit)) then
		unit.state = 'move'
		unit.jumps = 2
	end
	
	//right
	if (btn(1)) then
		unit.flip_bool = false
		x_increment = 3
	// left
	elseif (btn(0)) then
		unit.flip_bool = true
		x_increment = -3
	elseif (unit.state == 'move') then
		unit.state = 'idle'
	end
	
	// actually change character values
	//if (unit.x + x_increment >= 112) then
		//unit.x = 112
	if (unit.x + x_increment <= 0) then
		unit.x = 0
	else
		unit.x += x_increment
	end
end

function jump(unit)
	// randomize jump every call on floor
	if (floor_check(unit)) then
		unit.jump_style = rnd(unit.jump_frames)
		unit.jumps = 2
	end
	
	// initial jump
	if (btn(2)) then
		unit.state = 'jump'
	end

	// double jump reset
	if (unit.jumps > 0 and btnp(2)) then
		unit.jump_style = rnd(unit.jump_frames)
		unit.jumps -= 1
		unit.jump_cycle = 0
	end

	// jump gravity
	if (unit.state == 'jump' and unit.jump_cycle < unit.cycle_limit) then
		unit.gravity = false
		unit.jump_cycle += 1
		unit.y -= (10-unit.jump_cycle*1.25)
	end
end	
		
function grapple(unit)
	g_point = checkInGrappleDist(unit)
	if (g_point != nil) then
		unit.grapple_to = g_point
	else
		unit.grapple_to = nil
	end
end

function shoot(unit)
	if (mouse.button() == 1 and unit.shoot_timer == unit.shoot_delay) then
		mx,my = mouse.pos()
		add(bullets,init_bullet(unit.x,unit.y,mx,my))
		unit.shoot_timer = 1
	elseif (unit.shoot_timer < unit.shoot_delay) then
		unit.shoot_timer += 1	
	end
end	
-->8
// init functions

// player init
function init_player()
	player = {
		x = 10,
		y = floor,
		flip_bool = false,
		state = 'idle',
		gravity = true,
		jumps = 2,
		
		idle_frames = {2,4},
		idle_frame = 1,
		idle_inc = 0.05,
		idle_limit = 3,
		
		run_frames = {32,34,36,38,40,42,44,46},
		run_frame = 1,
		run_inc = 0.25,
		run_limit = 8.9,
		
		
		crouch_frames = {6},
		
		jump_cycle = 0,
		cycle_limit = 8,
		jump_frames = {
			[1] = {8,10},
			[2] = {12,14},
			[3] = {64,66}
		},
		jump_style = rnd(jump_frames),
		jump_frame = 1,
		jump_inc = 0.1,
		jump_limit = 3,
		
		shoot_delay = 5,
		shoot_timer = 5,

		grapple_to = nil,
	}
	return player
end

function init_bullet(startx,starty,endx,endy)
	bullet = {
		x = startx,
		y = starty,
		formula = function(x_pos)
			return ((endy-starty)/(endx-startx))*(x_pos-endx)+endy
		end,
		x_inc = (endx-startx)/(abs(endy-starty)+abs(endx-startx)) * 15
	}
	return bullet
end

 function init_grapple(gx,gy,gradius)
	grapple_point = {
		x = gx,
		y = gy,
		radius = gradius,
		distance = 0,
		attached = false,
	}
	return grapple_point;
end

-->8
//mouse
//from: https://www.lexaloffle.com/bbs/?tid=3549

mouse = {
  init = function()
    poke(0x5f2d, 1)
  end,
  -- return int:x, int:y, onscreen:bool
  pos = function()
    local x,y = stat(32)-1,stat(33)-1
    return stat(32)-1,stat(33)-1
  end,
  -- return int:button [0..4]
  -- 0 .. no button
  -- 1 .. left
  -- 2 .. right
  -- 4 .. middle
  button = function()
    return stat(34)
  end,
}


-->8
// map gen

function init_level_1()
	level_1_floor = {}
	for lvl_x = 1, 120 do
		y = rnd(14)
		if (y < 3) then
		 y = -1
		end
		length = rnd(4+2)
		for x_it = 0, length do
			add(level_1_floor,flr(y))
		end
	end
	
	return level_1_floor;
end

-->8
//Helper functions

function floor_check(unit)
	return (unit.y <= floor and unit.y >= floor-5)
end

function checkInGrappleDist(unit)
	print('function called', unit.x, unit.y, 7)
	for i,g in ipairs(grapple_points) do
		if ((unit.x - g.x)^2 + (unit.y - g.y)^2 < g.radius^2) then
			print('true', g.x, g.y, 7)
			return g;
		end
	end
	return nil;
end

__gfx__
0000000000888800fffffffff00fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
0000000008000080fffff0f00000fffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffff00fffff
0070070080088008ffff0ff0070fffffffff00f00000ffffffffffffffffffffffff0ffff00ffffffffffffff00fffffff70f0f00000f7ffff7f0ff00000f7ff
0007700080800808ffff0ff07b7ffffffff0fff0070fffffffff0ffffffffffffff0f0f00000fffffff0f0f00000fffffff80ff0070f2ffffff0f0f0070f2fff
0007700080800808fffffff777fffffffffffff07b7fffffffff0ffff00ffffffffffff0070fffffffff0ff0070fffffffff8ff07b72ffffffff8ff07b72ffff
0070070080088008ffffff88fffffffffffffff777fffffffffff0f00000fffffffffff07b7ffffffffffff07b7ffffffffff8f7772ffffffffff8f7772fffff
0000000008000080fffff8802fffffffffffff80fffffffffffffff0070ffffffffffff877fffffffffffff877ffffffffffff8828ffffffffffff8828ffffff
0000000000888800ffff8f808ffffffffffff8802ffffffffffffff07b7fffffffffff802fffffffffffff802fffffffffffff80ffffffffffffff80ffffffff
0009900088000088ffff8f802fffffffffff8f808ffffffffffffff777fffffffffff88052fffffffffff88052ffffffffffff80ffffffffffffff80ffffffff
000aa00080888808fffff8802fffffffffff8f802ffffffffffff8882fffffffffffff8c022fffffffffff8c022fffffffffff80ffffffffffffff80ffffffff
00a99a0008800880ffffff7cf7fffffffffff87c2fffffffffff8f802ffffffffffffff872fffffffffffff872ffffffffffff8cffffffffffffff8cffffffff
9a9aa9a908088080ffffffccffffffffffffffccf7ffffffffff8f80f2ffffffffffff0c7dffffffffffff0c7dffffffffffffcfdfffffffffffffcfdfffffff
9a9aa9a908088080ffffffcdffffffffffffffcdfffffffffffff7fcdf7fffffffffff00dfffffffffffff00dffffffffffffcfffcfffffffffffcfffcffffff
00a99a0008800880ffffffcdffffffffffffffcdffffffffffffffffcdfffffffffffff0fffffffffffffff0ffffffffff0fcfffffdf0fffff0fcfffffdf0fff
000aa00080888808ffffff00ffffffffffffff00ffffffffffffff0c0ffffffffffffffffffffffffffffffffffffffffff0fffffff0fffffff0fffffff0ffff
0009900088000088ffffff000fffffffffffff000fffffffffffff00f0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffff00ffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffff00fffffffffffffffffffff
fff0f0f00000fffffffffffff00fffffffff0ff00000fffffffffffff00ffffffff0f0f00000fffffffffffff00fffffffff0ff00000fffffffffffff00fffff
ffff0ff0070fffffffff00f00000fffffff0f0f0070ffffffff0fff00000ffffffff0ff0070fffffffff00f00000fffffff0f0f0070ffffffff0fff00000ffff
fffffff07b7ffffffff0fff0070ffffffffffff07b7fffffffff00f0070ffffffffffff07b7ffffffff0fff0070ffffffffffff07b7fffffffff00f0070fffff
ff888f8877fffffffffffff07b7fffffffffff8877fffffffffffff07b7fffffff228f8877ffffffffffffff7b7fffffffffff8877fffffffffffff07b7fffff
f7f888808fffffffffff888f77fffffffffff8808fffffffffff82ff77fffffff7f222808ffffffffffff2f877fffffffffff2808fffffffffff88f877ffffff
ffffff80228ffffffff8ff882fffffffffff88808fffffffffff2f888fffffffffffff80888fffffffff2f888fffffffffff22808ffffffffff8ff882fffffff
ffffff80f822f7fffff7fff802ffffffffff8f80ffffffffffff7ff808ffffffffffff80f888f7ffffff7ff808ffffffffff2f80ffffffffffff7ff802ffffff
fffff880fff82fffffffff88082f7fffffff88802fffffffffffff88088f7ffffffff880fff88fffffffff88088f7fffffff82808fffffffffffff88082f7fff
fffff8fccffffffffffff8dccff2fffffffff87cf27ffffffffff8fcfff8fffffffff8fcdffffffffffff8ccdff8fffffffff27cf86ffffffffff8fcfff2ffff
fffffffdfccccffffffffddffcccffffffffffcdffffffffffffffcfdffffffffffffffcfddddffffffffccffdddffffffffffdcffffffffffffffdfcfffffff
ff00ddddffffccffffffddfffffcffffffffffccdfffffffffffcccfddffffffff00ccccffffddffffffccfffffdffffffffffddcfffffffffffdddfccffffff
ff0ffffffffffcffffff0ffffff0fffffffffffcdffffffffff0fffffdffffffff0ffffffffffdffffff0ffffff0fffffffffffdcffffffffff0fffffcffffff
fffffffffffff0fffff0ffffff0ffffffffff00c0f0fffffff0fffffff0f0ffffffffffffffff0fffff0ffffff0ffffffffff00d0f0fffffff0fffffff0f0fff
fffffffffffff00fffff0ffffff0fffffffff0fff0fffffffff0fffffff0fffffffffffffffff00fffff0ffffff0fffffffff0fff0fffffffff0fffffff0ffff
fffffffff00fffffffff0ffff00fffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffff0f00000fffffffff0f00000ffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fff70ff00707ffffff7ffff0070fffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fff8fff07b78fffffff8fff07b7f7fff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffff8ff7772ffffffff88ff777f8ffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffff88822ffffffffff8888222fffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffff80ffffffffffffff80ffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffff80ffffffffffffff80ffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffff80ffffffffffff8880ffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffff8f0fffffffffffffff0ffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffff8ffcdffffffffffffffcdfffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffcdffffffffffffffcfffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffff00cffffffffffffff0f0f0ffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffff0f0f0fffffffffff0fff0fffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffffffff0fffffffffffff0ffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008777777800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00087777777780000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00877777787778000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00878778788778000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08778778787877800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08777887787877800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08777777777777800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08777887787777800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08778778788777800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00878778787878000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00877887787878000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00087777777780000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008777777800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666555555550000000000000000000000000000000000000000000000080808080808080808080808080808080808080808080808080808080808080808
66666666555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666555555550000000000000000000000000000000000000000000000080808080808080808080808080808080808080808080808080808080808080808
66666666555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
8080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080
8080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080
8080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080
8080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080
8080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080
8080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080
8080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080
8080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080
8080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080
8080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080
8080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080
8080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080
8080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080
8080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080
8181818181818181818181818181818180808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080
8181818181818181818181818181818180808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080
8080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080
8080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080
8080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080
8080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080
0000008080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080
0000008080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080
0000008080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080
0000008080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080
0000008080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080
0000008080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080
0000008080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080
0000008080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080
0000008080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080
0000008080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080
0000008080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000808080808080808080808080808080808080808080808080808080808080808080
