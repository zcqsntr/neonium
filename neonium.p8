pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
function _init()
printh("started")
	//fix enemy wrap around movement
	cls()
	cartdata("neonium")
	high_score = dget(0)
	pi = 3.14159265359
	player_speed = 3
	map_width = 352

	map_height = 100

	// in frames
	bullet_time = 12
	bullet_speed = 8
	bullet_recharge = 15 // frames between shots
	since_bullet = bullet_recharge

	min_fuel = 20
	max_fuel = 20
	fuel = max_fuel
	fuel_recharge = 0.2


	enemy_speed = 1
	enemy_tracking = 0.5

	saucer_speed = 0.5
	jellyfish_speed = 0.5

	neon_radius = 20
	neon_speed = 5
	neon_time = 100
	neon_collector = {x = 123, y = 96,neons = 0, sprite = 19}
	dash_collector = {x = 246, y = 96,neons = 0, sprite = 39}
	required_neons = 5

	player = {x = 64, y = 64, width = 8, height = 7, forward = true, neons = 0, dashing = false, sprite = 1}
	bullets = {}
	lasers = {}

	enemies = {}

	warnings_timer = 30
	enemy_warnings = {}
	jelly_fishes = {}
	jellyfish_warnings = {}
	saucer_warnings = {}
	saucers = {}

	particle_time = 5
	particle_speed = 5
	particles = {}
	neons={}
	score = 0

	frame = 0

	spawn_chance = 0.005
end

function _update()
	frame += 1

	update_player()
	update_projectiles(bullets, bullet_speed)
	update_warnings(enemy_warnings,40,42, 0)
	update_warnings(jellyfish_warnings,43, 45, 1)
	update_warnings(saucer_warnings,66, 68, 2)

	update_enemies()
	update_jellyfishes()
	update_saucers()
	update_neons()
	update_particles()
	kill_enemies(enemies, bullets)
	kill_enemies(jelly_fishes, bullets)
	kill_enemies(saucers, bullets)

	if rnd(1) < spawn_chance then
		make_enemy_swarm(flr(rnd(map_width)), flr(rnd(map_height)))
	end

	if rnd(1) < spawn_chance then
		make_jellyfish_swarm(flr(rnd(map_width)), flr(rnd(map_height-50)))
	end

	if rnd(1) < spawn_chance then

		make_saucer_swarm(flr(rnd(map_width)), flr(rnd(map_height-50)))

	end

	if detect_hit(player, enemies) or detect_hit(player, jelly_fishes) or detect_hit(player, saucers) then
		printh('game over')
		if score > high_score then
			dset(0, score)
		end

		stop()
	end
end

function _draw()
	cls()

	camera(player.x - 64 , 0)
	map(0, 0, 0, 0,map_height, 32)

	draw_projectiles(bullets, 0, 7)
	draw_projectiles(neons, 0, 8)
	draw_particles()
	draw_warnings(jellyfish_warnings)
	draw_warnings(enemy_warnings)
	draw_warnings(saucer_warnings)
	draw_enemies(enemies)
	draw_enemies(jelly_fishes)
	draw_enemies(saucers)
	print("score: " .. score, player.x-64,115,7)
	print("score *: " .. high_score, player.x-64,123,7)
	//print("high score: " .. score, player.x-64,115,7)
	//print(player.neons)
	//print(neon_collector.neons)

	if fuel >= min_fuel then
		fuel_col = 12
	else
		fuel_col = 1

	end
	print("fuel: "..fuel, player.x-10,115,fuel_col)


	print("neons: " ..player.neons, player.x-10,123,8)


	//neon collector
	rel_x = neon_collector.x-player.x
	//r = 60

	//sin and cos between 0 and 1
	//theta = rel_x/(2*pi*r)


 draw_collector(neon_collector)
 draw_collector(dash_collector)

	spr(player.sprite, player.x, player.y, 1, 1)

end
-->8
function draw_collector(collector)
	rect(collector.x +3, collector.y + 6 - flr(collector.neons/required_neons), collector.x +4, collector.y +6,8)
 spr(collector.sprite, collector.x, collector.y) // neon collector
end

function draw_projectiles(projectiles, len, col)
 for proj in all(projectiles) do
 	rect(proj.x, proj.y, proj.x+len, proj.y, col)
 end
end

function draw_enemies(enemies)
	for enemy in all(enemies) do
		spr(enemy.sprite, enemy.x, enemy.y, 1, 1, not enemy.forward)
	end
end

function draw_warnings(warnings)
	for warning in all(warnings) do
		spr(warning.sprite, warning.x, warning.y)
	end
end

function draw_particles()
	for particle in all(particles) do
		rect(particle.x, particle.y, particle.x, particle.y, particle.colour)
	end
end
-->8
function update_player()
	moving = false

	dx = 0
	dy = 0
	if btn(0) then
	 dx = -1
	 player.forward = false
	 moving = true
	end
	if btn(1) then
		dx = 1
		player.forward = true
		moving = true
	end
	if btn(2) then
		dy = -1
		moving = true
	end

	if btn(3) then
		dy = 1
		moving = true
	end

	dx, dy = unit_vector(dx, dy)



	if player.dashing then
 	player.sprite -= 6
 end
	// start dashing
	if (not player.dashing and btn(4) and btn(5) and moving  and fuel >= min_fuel)
	or (player.dashing and btn(4) and btn(5) and moving  and fuel >= 0) then
		fuel -=1
		speed = 2*player_speed
		player.dashing = true
		sfx(2)
	else
		speed = player_speed
		fuel += fuel_recharge
		fuel = min(fuel, max_fuel)
		player.dashing=false
	end


 new_x = player.x + dx*speed
	new_y = player.y + dy*speed


	if not map_collision(new_x, new_y, player.width, player.height) then
		player.x = new_x
		player.y = new_y
	elseif not map_collision(player.x, new_y, player.width, player.height) then
		player.y = new_y
	elseif not map_collision(new_x, player.y, player.width, player.height) then
		player.x = new_x
	end


 if btn(0) and btn(1) and btn(2) and btn(3) then
		//explode
		//charging = true
	end

	if since_bullet >= bullet_recharge and not charging then
	 if btn(4) and not btn(5) then
	  make_bullet(player.x+7, player.y+3, true)
	 	since_bullet = 0
	 end

		if btn(5) and not btn(4) then
		 make_bullet(player.x+7, player.y+3, false)
			since_bullet = 0
		end
	end

	since_bullet += 1

	if not player.forward then
 	player.sprite -= 3
 end

 player.sprite += 1
 if player.sprite > 23
 	then player.sprite = 21
 end

 if not moving then
 	player.sprite = 23
 end


 if not player.forward then
 	player.sprite += 3
 end

 if player.dashing then
 	player.sprite += 6
 end

 if check_collector(neon_collector) then
 	required_neons = ceil(required_neons*1.5)
	 bullet_recharge = ceil(bullet_recharge/2)
 end

 if check_collector(dash_collector) then
 	required_neons = ceil(required_neons*1.5)
	 max_fuel = ceil(max_fuel*1.2)
 end
end

function update_neons()
	for neon in all(neons) do
		neon.t -= 1
		if neon.t == 0 then
			del(neons, neon)
		end
		distance = get_distance(player, neon)

		if distance < 5 then
			del(neons, neon)
			player.neons += 1
		elseif distance < neon_radius then
			dx, dy = unit_vector(diff_x, diff_y)
			neon.x += dx*neon_speed
			neon.y += dy*neon_speed
		end
	end
end

function update_projectiles(projectiles, speed)
	for projectile in all(projectiles) do

	 if projectile.forward then
	  projectile.x += speed
	 else projectile.x -= speed end

		projectile.t -= 1
		if projectile.t <=0 then
		 del(projectiles, projectile)
		end

	end
end

function update_warnings(warnings, min_spr, max_spr, enemy_type)

	for warning in all(warnings) do
		warning.timer -= 1
		warning.sprite += 1
		if warning.sprite > max_spr then

			warning.sprite = min_spr
		end

		if warning.timer == 0 then
			del(warnings, warning)

			if enemy_type == 0 then
				make_enemy(warning.x, warning.y)
			elseif enemy_type == 1 then
				make_jellyfish(warning.x, warning.y)
			elseif enemy_type == 2 then
				make_saucer(warning.x, warning.y)
			end
		end

	end
end

function update_enemies()

	for enemy in all(enemies) do

					diff_x = player.x+3-enemy.x
					diff_y = player.y+3-enemy.y

					dx, dy = unit_vector(diff_x, diff_y)

					enemy.forward = diff_x<0
					enemy.dx = (1-enemy_tracking)*enemy.dx + enemy_tracking * dx
					enemy.dy = (1-enemy_tracking)*enemy.dy + enemy_tracking * dy
					enemy.x +=enemy.dx*enemy_speed
					enemy.y +=enemy.dy*enemy_speed

					speed = 10


					if frame%(30/speed)==0 then
						enemy.sprite += 1
						//sfx(2)
						if enemy.sprite > 5 then
							enemy.sprite = 3
						end
					end
	end
end

function update_jellyfishes()

	speed = 2
	for jelly_fish in all(jelly_fishes) do
		if frame%(30/speed)==0 then
			dx = 0.5-rnd(1)
			dy = 0.5-rnd(1)

			dx,dy=unit_vector(dx, dy)
			jelly_fish.x += dx*jellyfish_speed
			jelly_fish.y += dy*jellyfish_speed
			jelly_fish.sprite += 1
			//sfx(2)
			if jelly_fish.sprite > 9 then
				jelly_fish.sprite = 6
			end
		end


	end
end

function update_saucers()
	speed = 10
	for saucer in all(saucers) do

					saucer.x += saucer_speed
					saucer.y = saucer.y + sin(saucer.x/30)*0.5
					if frame%(30/speed)==0 then
						saucer.sprite += 1
						//sfx(2)
						if saucer.sprite > 65 then
							saucer.sprite = 64
						end
					end
	end
end

function update_particles()
	for particle in all(particles) do
		particle.x += particle.dx
		particle.y += particle.dy
		particle.t -= 1
		if particle.t == 0 then
			del(particles, particle)
		end
		end

end

-->8

function unit_vector(dx, dy)
	if dx == 0 and dy == 0 then
		return 0, 0
	end
	dx/= (dx^2 + dy^2)^0.5
	dy/= (dx^2 + dy^2)^0.5
	return dx, dy
end

function make_bullet(x, y, forward)
	bullet = {x=x, y=y,width = 1, height=1, t = bullet_time, forward = forward}
	add(bullets, bullet)
	sfx(1)
end

function make_laser(x, y)
	laser = {x=x, y=y, width =1, height=1, t = laser_time, forward = not player.forward}
	add(lasers, laser)
	sfx(1)
end

function make_enemy(x,y)
	diff_x = player.x-x
	diff_y = player.y-y

	dx, dy = unit_vector(diff_x, diff_y)
	enemy = {x=x, y=y, width = 7, height=3, dx=dx, dy=dy,width = 7,  height = 3,forward = diff_x<0, sprite = 3, enemy_type=0}

	add(enemies, enemy)
end

function make_jellyfish(x,y)
	jelly_fish = {x=x, y=y, width = 6, height = 6, forward = false, sprite = 6, enemy_type=1}

	add(jelly_fishes, jelly_fish)
end

function make_saucer(x,y)
	saucer = {x=x, y=y, width = 8, height = 4, forward = false, sprite = 64, enemy_type=2}

	add(saucers, saucer)
end

function make_enemy_warning(x, y)
	warning = {x=x, y=y, sprite = 40, timer = warnings_timer}

	add(enemy_warnings, warning)

end

function make_jellyfish_warning(x, y)
	warning = {x=x, y=y, sprite = 43, timer = warnings_timer}

	add(jellyfish_warnings, warning)

end

function make_saucer_warning(x, y)
	warning = {x=x, y=y, sprite = 66, timer = warnings_timer}

	add(saucer_warnings, warning)

end

function make_enemy_swarm(x,y)
	for i=0,5 do
		make_enemy_warning(x+i*16, y)
	end
end

function make_jellyfish_swarm(x,y)
	for i=0,5 do
		make_jellyfish_warning(x+i*10, y+i*10)
	end
end

function make_saucer_swarm(x,y)
	for i=0,5 do
		make_saucer_warning(x+i*10,y )
	end
end


function detect_collision(a, b)
 // detects collision between two objects a and b
	hit=false

 local xd=abs((a.x+(a.width/2))-(b.x+(b.width/2)))
 local xs=a.width*0.5+b.width*0.5
 local yd=abs((a.y+(a.height/2))-(b.y+(b.height/2)))
 local ys=a.height/2+b.height/2
 if xd<xs and yd<ys then

   hit=true
 end
 return hit
end

function detect_hit(enemy, bullets)
 // detect collision between object obj and table of objs tab
 for bullet in all(bullets) do
 	if detect_collision(enemy, bullet) then
 		del(bullets, bullet)

 		return true
 	end
 end
 return false

end

function get_distance(a, b)

	diff_x = (a.x - b.x)/64
	diff_y = (a.y - b.y)/64
	return 64*(diff_x^2 + diff_y^2)^0.5
end

function kill_enemies(enemies, bullets)

	for enemy in all(enemies) do

	 if detect_hit(enemy, bullets) or (detect_collision(enemy, player) and player.dashing) then
			sfx(3)
			del(enemies, enemy)
			neon = {x=enemy.x+3, y = enemy.y + 1, t = neon_time}
			add(neons, neon)
			score += 1

			for i=1,13 do
	 		dx = 0.5-rnd(1)
	 		dy = 0.5-rnd(1)
	 		dx, dy = unit_vector(dx, dy)
	 		dx*= particle_speed
	 		dy*= particle_speed
	 		if enemy.enemy_type == 0 then
	 			col = 2
	 		elseif enemy.enemy_type == 1 then
	 			cols = {1,9,12}
	 			ind = flr(rnd(4))
	 			col=cols[ind]
	 		elseif enemy.enemy_type == 2 then
	 			col = 13
	 		end
	 		particle = {x=enemy.x +flr(rnd(7)), y = enemy.y + flr(rnd(3)),dx=dx ,dy=dy,t=particle_time,  colour = col }
	 		add(particles, particle)

	 	end
	 end



	 if detect_collision(enemy, player) and player.dashing then
	 	 fuel += 4
	 end

	end
end

function map_collision(x,y,w,h)
  collide=false
  for i=x,x+w,w do
    if (fget(mget(i/8,y/8),0)) or
         (fget(mget(i/8,(y+h)/8), 0)) then
          collide=true
    end
  end

  for i=y,y+h,h do
    if (fget(mget(x/8,i/8), 0)) or
         (fget(mget((x+w)/8,i/8), 0)) then
          collide=true
    end
  end

  return collide
end

function check_collector(collector)
	if get_distance(player,collector) < neon_radius then
	 	collector.neons += player.neons
	 	player.neons = 0
	 	if collector.neons > 6*required_neons then
	 		collector.neons -= 6*required_neons
	 		return true
	 	end
	 end
	 return false
end
__gfx__
0113b0000113b0000113b000222e0220222e0000222e0000000cc000000cc000000cc000000cc00020200202202002022020020220200202000d700000000000
00110000001100000011000002822000028222200282200000cc7c0000cc7c0000cc7c0000cc7c00030000300300003003000030030000300011d70000000000
a91111100011111009111110222200002222000022220220021111200211112008111180081111800038830000388300003883000038830001111d7000000000
98155128001551280815512800000000000000000000000000100100001001000010010000100100003333000033330000333300003333002111111200000000
a9111110001111100911111000000000000000000000000009000090009009000009900000900900020090200209002002009020020900200111111000000000
00110000001100000011000000000000000000000000000090000009009009000009900000900900000900000000900000090000000090000010010000000000
0113b0000113b0000113b00000000000000000000000000000000000000000000000000000000000000090000009000000009000000900000090090000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090090000000000
11122000111220001112200000d00d00000000001d0000001d0000001d0000000000001d0000001d0000001d1d0c00001d0c00001d0c00000000c01d0000c01d
a111000001110000011100000dd00d600000000001d0000001d0000001d00000000001d0000001d0000001d001d0c00001d0c00001d0c000000c01d0000c01d0
911111009111110001111100ddd0067600000000011d0000011d0000011d0000000011d0000011d0000011d0911d0c00011d0c00011d0c0000c011d900c011d0
915671129156711201567112ddd00d6d000000000011d0000011d0000011d0000001110000011100000111009811d0c09011d0c00011d0c00c0111890c011109
915661129156611201566112ddd00ddd000000000011167000111670001116700671110006711100067111009811167c9811167c0811167cc6711189c6711189
9111110091111100011111005dd00ddd0000000098111567081115670011156755611d8955611d8055611d009811156c9811156c0811156cc5611d89c5611d89
a1110000011100000111000005dddd5000000000911115560111155601111556555111d9555111d0555111d09111155c9111155c0111155cc55111d9c55111d9
111220001112200011122000005dd5000000000011dd000011dd000011dd00000000111d0000111d0000111d11dd0cc011dd0cc011dd0cc00cc0111d0cc0111d
0000c01d0005500000050000000050000005500000055000dddddddd00d00d000000000000000000000000000000000000000000000000000000000ee0000000
000c01d00000555000050000000050000555000005555000dddddddd0dd00d6000000000002222000e2222e000000000000cc000007cc7000000008e2e000000
00c011d00000005500050000000050005500000055005000ddd66dddddd006760088880002888820028888200001100000c11c0000c11c000000008e2e000000
0c0111000000000000050000000050000000000000005000dd6676ddddd00d6d00000000002222000e2222e00001100000c11c0000c11c000000088228e00000
c67111800000000000050000000050000000000000005000dd6666dd05d00d5000000000000000000000000000000000000cc000007cc70080008820028e000e
c5611d800000000000050000000050000000000000005000ddd66ddd05d00d500000000000000000000000000000000000000000000000002880282002880882
c55111d00000000000050000000050000000000000005000dddddddd00dddd000000000000000000000000000000000000000000000000000228822002288820
0cc0111d0000000000050000000050000000000000005000dddddddd005dd5000000000000000000000000000000000000000000000000000028220000228200
0000e0000000e0000028ee0000228e002888888e00288e00eeee00000000ee000000000e0000e000002e00000000288ee000000000e000000000000000000000
0000e00000008e0002288ee0022888e0028888e0028888e00288eee0000008e0000000e800008ee00280000002228ee08e000000028e00000000000000000000
00008e0000028e00222028e00288088e00288e00222888e0000288ee0000028e00eee8880880088e228000002288e00088ee0000288000000000000000000000
00028e0000028000200028e00282000e00288e000202808e0000228e00000028ee8888888282288888000000288e00008888e000888eee000000000000000000
00288e000202808e0000028e2820000000028e000002800000000088000022880002888800222888288e000088000000888888ee8888888e0000000000000000
00288e00222888200000008e2200000000008e0000028e00000008880002888800002288000002822288e0002880000088222200288002200000000000000000
028888e0028888200000002e2e0000000000e00000008e000000082008882220000000280000222002228ee00280000082000000022200000000000000000000
2888888e002882000000000ee00000000000e0000000e000000082008222000000000002000002000000222e002e000020000000000200000000000000000000
00066000000660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
005dd600005dd6000000000000dddd0006dddd600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05dddd6005dddd60005555000d5555d00d5555d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5d8282d65d2828d60000000000dddd0006dddd600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddmmddddmmdddmddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddmmddddmmdddmddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddmmddddmmddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddmdddddddddmdddddddddddddddddddddddmdddddddddddddmddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddmdddddddddddddddddmdddddddddddddddddddddddddmdmddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddmmddddddddmddddddmddddddddddddddddddddmdddmdmddddddddddmdmdddddddmdddddmdddddddmddmddddmddddddmdddmdddmddmdddmd
ddddmddddddmmdddmddmdddddddddddmddddmddddddddddddddddddmddddddmdmmdddddddddddmddddddddddddddddddmddddddddddmdmmdmmdmmmmdmmdddddd
ddddddddddddddddddddmddddddddmdmmmdddddddddddddddmddmddddddddddmdddmmdmddddddddddmddddddddddmdmdmddddddmmdmdddmddddddmddddmddddd
ddddddmdddmmdddddmdddmmmddddddddddmdmmdddddddmddddmddddddddmmmddddddddmmmddddmmddddddddddddmdddddddddmmddddddddmdddddddmdddddmdd
ddddddmddddddmmddddmdmddddddddmddmddddddddddddddmdmdmdmdddddmdmdddddddmdddddddddmddddddddmdddddddddddddddddmddmdddmddddddddmdmdm
dddmddmddddmmddmdddmmddmmddddddmddddddddmddddddddddddddddddddddddddddddddmddddmdmdddddmdddmmdmddddddmmdmdmmddddmdddmmdddddddddmm
dmddddmdddddddddddddddmdddmdddddddmdmdddddddddmdddddddmdddddddddddddddmdmddddmdddddddddddmddddddmdmddddddddmddmmddddmdmddddddddd
ddddddmddddddddddmmddmdmdmdmmddmdddddddddddddmmddmdmddddddddmddddddddmdddddddddmdmddddddmddddmddddddddmddddddddddddddddmddddmddd
dddmdddddddddddmddddddmdddddmddddmddddddmddddmdmdmmmdmddddddddddddddddmmdddmddddddddmddddmmdddmmdddddddddddmdddddddddmdddddddddd
ddddddmddddmmddmmdmddddddddddddmddmdddddmddddddddmddmmdmdddddddmddddddddddddddddddddddddddmddmddddddddddmddddmdddmddmddmmddddmdd
ddddddddmddddddddmdddddmddmddddddddddmddddmmddmmdddddddddmddmdddddddmdmddddddmmddddddddddmdmddddddddddddddmdmdddmddmddmddddmmdmm
mdddddddddddddddddmdddmmddmmdmddddmddddmddmdmddmddddddddddddmmdddmddddddddmddddddmdddddddddddmdmddmddddddddddddddmddmddddddmdmdd
dmdmdddmmddmddddmdmddddddddddddddddddmdmddmdmddddddmddddddmdddddddmmdmddmdddmmddddmdmddddddddddddddmdmddddddmdmdmddddddddddddmdd
ddmddddddddmmmmmdddddddmdddddmdmdmdddddddmddddddddddmddddmmdddddmmdddddddmdmddddddddddddddddddmddddddmmdddddmddmdddddddmdddddddd
dddmdddddddddddddddddddddddddddddddddddmddddddddddmdmdddddmdddmmddddddddmdddddmddmdddmdddddmdddmdmdddddmddddddddddddmddmddmddddd
dddddddmddddddddddddddddmdddmmdddmdddddddmmdddddmdmddmddmddddddddmdddddddddddddddmdmdddddddddddmdddddddmmmmdddddmdddddddddddmdmd
mdddddmdddddddmddddddddmdmdddmdddddmdddddmddmdddddddddddddddddddddddmdddddddddddddddddddmmddddddmddddddddmddmddddddddddmdmdmddmd
dddmddddmdddddddmddmdddmmdddmdddddddddmdmmdddddddmmdmddmdddddddmddddddddddddddddmddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
2626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2600000000003300003200000000003500000000000000000000003400000000320000000000000000000000260000000000000000000000000000000000000000000000000000000000002600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
263d000000000000000000000000000000000000000000000000000000000000000000000000000000000000260000000000000000000000000000000000000000000000000000000000002600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2600000000000000000000000000000000000000000000000000000000000000000000000000000000000037260000000000000000000000000000000000000000000000000000000000002600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2600000000000000000000000000000000000000000000000000000000000000000000000000000000000000260000000000000000000000000000000000000000000000000000000000002600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2600000000000000000000000000000000000000000000000000000000000000000000000000000000000000260000000000000000000000000000000000000000000000000000000000002600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2600000000000000000000000000000000000000000000000000000000000000000000000000000000000000260000000000000000000000000000000000000000000000000000000000002600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2600000000000000000000000000000000000000000000000000000000000000000000000000000000000000260000000000000000000000000000000000000000000000000000000000002600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2600000000000000000000000000000000000000000000000000000000000000000000000000000000000039260000000000000000000000000000000000000000000000000000000000002600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2600000000000000000000000000000000000000000000000000000000000000000000000000000000000000260000000000000000000000000000000000000000000000000000000000002600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
263b000000000000000000000000000000000000000000000000000000000000000000000000000000000000260000000000000000000000000000000000000000000000000000000000002600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2600000000000000000000000000000000000000000000000000000000000000000000000000000000000000260000000000000000000000000000000000000000000000000000000000002600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2600002e0000000000002f000000000000003000000000000000003100000000000000000000000000002e00260000000000000000000000000000000000000000000000000000000000002600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100001c0711d0711d0611a061180611503112021100210e0110a00107001100010f0010e0010e0010e001190011a0011b0011b0011b0011d0011f00121001230012300123001190013f001320012900124001
000100002a750227501e7501975015750127500d7500b75005700047000a70013700187001e700287002f7003570033700337003570037700397003a7003a7000000000000000000000000000000000000000000
000300001075010050107500f7500d0500d0500c7500c7400a0400a74009730087300403003030057300202003720017100070000700027000270002700027000270002700027000270002700027000270002700
0001000005670066700665006650066400663006630066200662004620076200662005610046100461003610036100361001600016000160001600016001b20008100091000c100151001d100201002c20034200
000100000061002610016100061000610006100161001610006100061002610006000060000600006000060001600016000060000600016000260000600006000060000600006000060000600006000060000600
