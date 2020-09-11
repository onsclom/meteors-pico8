pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
--main
function _init()
 particles={}

 meteors={}
 ticks=0
 player=character()
	blocks={}
	fills={
		◆-.5,
		∧-.5,
		◆-.5,
		웃-.5,
		✽-.5,
		⧗-.5,
		⌂-.5,
		♥-.5,
		●-.5,
		★-.5
	}
	curfill=1

	add(blocks,
	 new_block(0,86,20,127,true))
   --testing rad
	add(blocks,
	 new_block(127-20,86,127,127,true))
	add(blocks,
	 new_block(128/2-5,97,128/2+5,127))
	blocks[3].top_left.x-=17
	blocks[3].bot_right.x-=17
	add(blocks,
	 new_block(128/2-5,97,128/2+5,127))
	blocks[4].top_left.x+=17
	blocks[4].bot_right.x+=17


	block3off=0
	block4off=0
	block3_og_tl=blocks[3].top_left.x
	block4_og_tl=blocks[4].top_left.x
	block3_og_br=blocks[3].bot_right.x
	block4_og_br=blocks[4].bot_right.x

	controls=new_controls()

	water={}
	for i=0,127,5 do
		new=create_circle(i,127-3,10)
		add(water,new)
	end

	shake=0
end

function _update()
	ticks+=1

	if (controls.❎just_pressed) _init()

 update_particles()
 meteors_update()
	blocks_move()
 controls:update()

 for block in all(blocks) do
 	block:update()
 end
	player:update()
	collision_check(player,blocks)
end

function _draw()
	draw_background()
	do_shake(3)
	--draw_background()
 --cls(1)
 for block in all(blocks) do
 	block:draw()
 end


 draw_bg_water(water)
 draw_particles()
 meteors_draw()

 player:draw()

 draw_water(water)


 color(2)
 print(stat(1))

end


function draw_background()
 cls(0)
 --mset(0,0,0,0,16,16)
	--fillp(0b0011001111001100)
	--rectfill(0,0,127,127,16+3)
	local size=8

	for x=-size*2,127+size*2,size do
		for y=-size*2,127+size*2,size do
			if (x)%(size*2)==(y)%(size*2) then
				--fillp(fills[(curfill+6)%#fills+1])
				color(0)
			else
				fillp(fills[(curfill+4)%#fills+1])
				color(1)
			end

			local offsetx=sin(time()/6.333)*size
			local offsety=cos(time()/8)*size

			rectfill(x+offsetx,y+offsety,
			offsetx+x+size-1,
			y+offsety+size-1)
			fillp()
		end
	end
end
-->8
--utility

--print center
function printc(msg,x,y,col)
	local size = #msg
	if (x==nil) x=64
	if (y==nil) y=64
	if (col!=nil) color(col)
	print(msg,x-#msg*2+1,y-2)
end

--vec2 for x and y stuff
function vec2(x,y)
	local vec = {}
	if (x==nil) x=0
	if (y==nil) y=0
	vec.x=x
	vec.y=y
	return vec
end

--for comparing table
function equals(t1,t2)
	for k,v in pairs(t1) do
		if (t2[k]!=v) return false
	end
	return true
end

function do_shake(amt)
	local shakey=amt-rnd(amt*2)
	local shakex=amt-rnd(amt*2)

	shakex*=shake
	shakey*=shake

	camera(shakex,shakey)

	shake=shake*.7
	if (shake<.05) shake=0
end
-->8
--char

function character()
	local char={}

	char.pos=vec2(5,3)
	char.vel=vec2(0,0)
	char.y_vel=0
	char.size=8 --keep this odd
	char.width=4
	char.half=flr(char.size/2)
	char.color=15
	char.outline=15
	char.gravity=.4
	char.jump_strength=-4.0
	char.points={}
	char.grounded=false
	char.speed=1.5

	char.coyote_time=5
	char.time_since=char.coyote_time

	char.update = function(self)
	 self.vel=vec2(0,self.vel.y)
		if (btn(⬅️)) self.vel.x=-1*self.speed
		if (btn(➡️)) self.vel.x=1*self.speed

		self.vel.y+=self.gravity

		if self.grounded then
			self.time_since=0
		else
			self.time_since+=1
		end

		--jump
		if (controls.🅾️just_pressed and self.time_since<self.coyote_time) then
			self.vel.y=self.jump_strength
			self.time_since=self.coyote_time
			sfx(0)
		end

		if (self.vel.y<0 and controls.🅾️just_released) then
			self.vel.y/=2
		end

		self.pos=vec2(
		 self.pos.x+self.vel.x,
		 self.pos.y+self.vel.y
		)

		char.points={}
		for x=-1,1,2 do
			for y=-1,1,2 do
				add(char.points,
					vec2(
						char.pos.x+self.half*x,
						char.pos.y+self.half*y
					)
				)
			end
		end
	end

	char.draw = function(self)
--	 rectfill(self.pos.x-char.half,
--	 self.pos.y+char.half,
--	 self.pos.x+char.half,
--	 self.pos.y-char.half,
--	 self.color)
--	 rect(self.pos.x-char.half,
--	 self.pos.y+char.half,
--	 self.pos.x+char.half,
--	 self.pos.y-char.half,
--	 self.outline)
	if (self.grounded)	spr(1,self.pos.x-char.half,self.pos.y-char.half,1,1)
	if (not self.grounded)	spr(2,self.pos.x-char.half,self.pos.y-char.half,1,1)

	end

	return char
end

--collisions and resolution done here
--to get prev just subtract vel
function collision_check(char,blocks)
 char.grounded=false
 for block in all(blocks) do
 	local x_dist=char.pos.x-block.center.x
 	x_dist=abs(x_dist)
 	local y_dist=char.pos.y-block.center.y
 	y_dist=abs(y_dist)
 	local x_col=char.width/2+block.x_size/2
 	x_col=abs(x_col)
 	local y_col=char.size/2+block.y_size/2
 	y_col=abs(y_col)

 	local check=0
 	if (x_dist<x_col) check+=1
 	if (y_dist<y_col) check+=1

 	if (check==2) then
 		--colliding
 		--look at previous
 		local prev_pos=vec2(
 			char.pos.x-char.vel.x,
 			char.pos.y-char.vel.y
 		)

 		local bot_char=prev_pos.y+char.size/2-1
 		local top_block=block.top_left.y

 	 local leniancy=0
 		if bot_char-leniancy<top_block then
 			char.pos.y=
 			 top_block-char.size/2
 			char.grounded=true

 			--if was untouched, add score
 			if block.touched==false then
 				block.touched=true
 				--reset other blocks if end
 				if block.is_end then
 				 curfill+=1
 				 block_randomize()
 					for b in all(blocks) do
 						if (b!=block) b.touched=false
						end
					end
				end


 			if char.vel.y>1 then
 				sfx(1)
				end

 			char.vel.y=min(0,char.vel.y)
			end
			--we dont need to check
			-- other collisions if
			-- one hits
			break
 	end
 end

 if char.pos.x-char.width/2<0 then
 	char.pos.x=char.width/2
 elseif char.pos.x+char.width/2>128 then
 	char.pos.x=128-char.width/2
 end
end
-->8
--block

rnd_amount=15
lrp_speed=.2

function new_block(x1,y1,x2,y2,is_end)
	block={}
	block.top_left=vec2(x1,y1)
	block.bot_right=vec2(x2,y2)
	block.touched=false
	block.x_size=x2-x1+1
	block.y_size=y2-y1+1

	block.is_end=is_end

	block.center=vec2(
	 (block.top_left.x+
	  block.bot_right.x)/2,
	 (block.top_left.y+
	  block.bot_right.y)/2)

	block.color=9*16+15
	block.touched_col=4*16+15
	block.outline=4

	block.update=function(self)
		self.x_size=self.bot_right.x-self.top_left.x+1
		self.y_size=self.bot_right.y-self.top_left.y+1

		self.center=vec2(
		 (self.top_left.x+
		  self.bot_right.x)/2,
		 (self.top_left.y+
		  self.bot_right.y)/2)
	end

	block.draw=function(self)
	 fillp(fills[curfill%#fills+1])
		if self.touched==true then
			rectfill(self.top_left.x,
		 self.top_left.y,
		 self.bot_right.x,
		 self.bot_right.y,
		 self.touched_col)
		else
			rectfill(self.top_left.x,
		 self.top_left.y,
		 self.bot_right.x,
		 self.bot_right.y,
		 self.color)
		end
		fillp()

		rect(self.top_left.x,
		 self.top_left.y,
		 self.bot_right.x,
		 self.bot_right.y,
		 self.outline)
	end

	return block
end

function blocks_move()
	blocks[3].top_left.x =
	 blocks[3].top_left.x*(1-lrp_speed)
	 +
	 (block3_og_tl+block3off)*lrp_speed
	blocks[3].bot_right.x =
	 blocks[3].bot_right.x*(1-lrp_speed)
	 +
	 (block3_og_br+block3off)*lrp_speed

	blocks[4].top_left.x =
	 blocks[4].top_left.x*(1-lrp_speed)
	 +
	 (block4_og_tl+block4off)*lrp_speed
	blocks[4].bot_right.x =
	 blocks[4].bot_right.x*(1-lrp_speed)
	 +
	 (block4_og_br+block4off)*lrp_speed


end

function block_randomize()
 shake+=.5
	block3off=rnd(rnd_amount)-rnd_amount/2
	block4off=rnd(rnd_amount)-rnd_amount/2
end
-->8
--controls

function new_controls()
	controls = {}

	controls.🅾️just_pressed=false
	controls.❎just_pressed=false
	controls.🅾️=false
	controls.❎=false
	controls.🅾️just_released=false
	controls.❎just_released=false


	controls.update=function(self)
   self.🅾️just_pressed=false
   self.❎just_pressed=false
   self.🅾️just_released=false
   self.❎just_pressed=false

		if (not self.🅾️ and btn(🅾️)) then
		 self.🅾️just_pressed=true
		elseif (self.🅾️ and not btn(🅾️)) then
			self.🅾️just_released=true
		end

		if (not self.❎ and btn(❎)) then
		 self.❎just_pressed=true
		elseif (self.❎ and not btn(❎)) then
			self.❎just_released=true
		end

		self.🅾️=btn(🅾️)
		self.❎=btn(❎)
	end

	return controls
end
-->8
--water
circ_color=3
bg_water=7

function create_circle(x,y,size)
	local circle={}
	circle.x=x
	circle.y=y
	circle.size=size
	return circle
end

function draw_bg_water(_water)
 for c in all(_water) do
  local off=sin(time()/4+c.x/12)*5
	 circfill(c.x,c.y+off,c.size+1,bg_water)
	end
end
--water={}
--this draws circles as water
function draw_water(_water)
	for c in all(_water) do
	 local off=sin(time()/4+c.x/12)*5
	 circfill(c.x,c.y+off,c.size,circ_color)
	end

		pal({
		[0]=12,12,13,7,15,13,7,7,14,10,7,7,7,12,14,9
	})

 local distort={}
 --wreflection
 for x=0,127 do
  local num=0
  for y=90,127 do
  	if pget(x,y)==3 then
  	 num+=1
  	 local curd=0
  	 if distort[y] then
  	 	curd=distort[y]
    else
    	curd=sin(time()/4+y/16)*1.25
    	distort[y]=curd
    end


  		pset(x,y,
  			pget(
  				curd+x
  				,y-num*3+3)
  				)
			end
  end
 end

 pal()

end
-->8
-- meteors
meteor_spawn_time=16

part_cols={8,9,10,5,6}

function new_meteor(x,y,dx,dy,rad)
 meteor={}
 meteor.x=x
 meteor.y=y
 meteor.dx=dx
 meteor.dy=dy
	meteor.color=5
	meteor.border=6
	meteor.radius=rad
	meteor.splashed=false

	meteor.part_time=0
	meteor.part_rate=0


	meteor.update=function(self)
		self.x+=self.dx
		self.y+=self.dy
		self.part_time+=1
		self.fill=fills[ceil(rnd(100))%#fills+1]
		if (self.part_time>self.part_rate) then
			self.part_time=0
			add(particles,
			 new_particle(self.x+cos(rnd(1))*2,
			 	self.y+sin(rnd(1))*2,
			 	1,20+rnd(10))
			 )
		end

		if (self.splashed==false and self.y>113) then
			add(particles,
				new_particle(self.x,self.y,
				self.radius*3,30,3,true)
			)
			shake+=.025
			self.splashed=true
		end

	end
	meteor.draw=function(self)
		--fillp(self.fill)
		fillp(self.fill)
		circfill(self.x,self.y,self.radius,8*16+10)
		fillp()
		circ(self.x,self.y,self.radius,7)
	end

	return meteor
end

function meteors_update()
	if ticks>meteor_spawn_time then
		ticks=0
		add(meteors,new_meteor(
			rnd(127),-10,rnd(1)-.5,1,4+rnd(1)-.5))
	end


	for i=#meteors,1,-1 do
	 meteors[i]:update()

	 if meteors[i].y>140 then
	 	del(meteors,meteors[i])
  end
	end
end

function meteors_draw()
	for m in all(meteors) do
		m:draw()
	end
end

function new_particle(x,y,r,life,col,water)
	part={}
	part.x=x
	part.y=y
	part.r=r
	part.life=life
	part.time=0
	part.is_water=water
	if col == nil then
		part.color=part_cols[ceil(rnd(#part_cols))]
	else
		part.color=col
	end

	part.draw=function(self)
		if self.is_water then
		 color(7)
		 	circfill(self.x,self.y,
					1+self.r*(1-(self.time/self.life))+.5)
		end
		color(self.color)
		circfill(self.x,self.y,
			self.r*(1-(self.time/self.life))+.5)
	end
	part.update=function(self)
		self.time+=1
	end

	return part
end

function update_particles()
	for i=#particles,1,-1 do
		local p=particles[i]
		p:update()

		if p.time>p.life then
			del(particles,p)
		end
	end
end

function draw_particles()
	for p in all(particles) do
		p:draw()
	end
end

__gfx__
00000000000770000707707011111111333333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000770000707707011111111333333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700077777700077770011111111333333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000700770070007700011111111333333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000700770070007700011111111333333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700007777000777777011111111333333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007007000000000011111111333333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007007000000000011111111333333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0304030403040304030403040304030400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0403040304030403040304030403040300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0304030403040304030403040304030400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0403040304030403040304030403040300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0304030403040304030403040304030400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0403040304030403040304030403040300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0304030403040304030403040304030400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0403040304030403040304030403040300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0304030403040304030403040304030400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0403040304030403040304030403040300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0304030403040304030403040304030400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0403040304030403040304030403040300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0304030403040304030403040304030400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0403040304030403040304030403040300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0304030403040304030403040304030400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0403040304030403040304030403040300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00020000035500555005550075500a5500f5501655000500025002650027500265002650025500255002550025500245002450024500245002450024500245001850016500165001350011500115000f5000f500
0101000015751127510f7510375100750017000070000700017000070000700007000070000700007002c70000700007000070000700007000070000700007000070000700007000070000700007000070000700
011e00200217502175021750217505175051750517505175001750017500175001750917509175071750b17502175021750217502175051750517505175051750c1750c1750c1750c1750717507175071750b175
010f00202352224522235221d52223522215221c5221f5221d5221c5221a5221c5221f52224522265222452223522215221f5221d5221c5221a52223522215221f52224522245222452223522235222352223522
010f002018621036250000000600006002e6002e60000600286250060000600006002862500600006000000018620016250000000600006000060000600000000000000600286250000028625006000060000600
__music__
06 02434444
