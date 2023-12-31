# PlayerSript: script que controla o personagem do jogador

extends KinematicBody2D


# Guarda informações gerais sobre o jogo (Tamanho da janela, escala, etc..)
onready var Game              = get_node("/root/Singleton") 
onready var state             = SwimmingState.new(self)
onready var health_bar = $Healthbar
var enemys = ["BigEnemy Body", "LittleEnemyBody"]

# Estados em que o personagem do player pode se encontrar
enum STATE {SWIMMING, FALLING, DASHING}

# Variaveis importantes para o personagem
# Lista de variaveis internas do player
var total_time: float  = 0
var speed: float       = 0
var pushBackSpeed = 35
var velocity: Vector2  = Vector2(0,0)
var acceleration: float = 0.2

var hp: int = 100

# Funções gerais que são chamadas em todos os estados
func _ready():
	set_process_input(true)
	set_process(true)
	pass
	
func _process(delta):
	state._process(delta)
	if hp<0:
		die()
	pass
	
func _physics_process(delta):
	total_time += delta
	rotate_child_sprite(1, total_time, 0.03, 0.5*PI, 0)
	rotate_child_sprite(2, total_time, 0.01, PI, 0)
	rotate_child_sprite(3, total_time, 0.015, PI, 0)
	rotate_child_sprite(4, total_time, 0.015, PI, 0)
	rotate_child_sprite(5, total_time, 0.015, 0.66*PI, 0)
	rotate_child_sprite(6, total_time, 0.015, 0.5*PI, 0)
		
	state._input()
	state._physics_process(delta)
	var colision = move_and_collide(velocity)
	if colision:
		
		if enemys.has(colision.get_collider().name):
			if state.canHurt:
			#if timer_dash > -30:
				colision.get_collider().hurt(20)
				
#				colision.collider.pushBack(self.global_position) #new
#				self.pushBack(colision.collider.global_position) #new

# Troca o estado do peixe
func set_state(new_state):
	state.exit()
	if(new_state == STATE.SWIMMING):
		state = SwimmingState.new(self)
	elif(new_state == STATE.FALLING):
		state = FallingState.new(self)
	elif(new_state == STATE.DASHING):
		state = DashingState.new(self)
	pass
	
# Estado em que o peixe está nadando dentro de uma região de água
class SwimmingState:
	var fish
	var gravity_on_water: Vector2  = Vector2(0, 0.001)
	var max_speed_on_water: float  = 4.5
	var friction_on_water: float   = 0.97
	var canBInjured: bool = true
	var canHurt: bool = false
	
	func _init(fish):
		self.fish = fish
		canHurt = false

	func _process(delta):
		if(fish.Game.gameplay_type == fish.Game.GAMEPLAY_TYPE.MOUSE):
			var mouse_position_on_viewport = fish.get_viewport().get_mouse_position()/fish.Game.window_scale - fish.Game.size/2
			fish.look_at(mouse_position_on_viewport + fish.global_position)
		elif(fish.Game.gameplay_type == fish.Game.GAMEPLAY_TYPE.KEYBOARD):
			fish.look_at(fish.velocity + fish.global_position)
		pass
	
	func _physics_process(delta):		
		fish.velocity += gravity_on_water
		fish.speed = min(fish.velocity.length(), max_speed_on_water)
		fish.velocity = fish.velocity.normalized()*fish.speed*friction_on_water
		pass
	
	func _input():
		if(fish.Game.gameplay_type == fish.Game.GAMEPLAY_TYPE.MOUSE):
			fish.move_with_mouse()
			if(Input.is_mouse_button_pressed(2)):
				fish.set_state(STATE.DASHING)
			
		elif(fish.Game.gameplay_type == fish.Game.GAMEPLAY_TYPE.KEYBOARD):
			fish.move_with_keyboard()
		pass
		
	func exit():
		pass
	
class FallingState:
	var fish
	var gravity_in_air: Vector2  = Vector2(0, 0.18)
	var friction_on_air: float   = 0.96
	var max_speed_on_air: float  = 10
	var canBInjured: bool = true
	var canHurt: bool = false
	
	func _init(fish):
		self.fish = fish
		
	func _process(delta):
		if(fish.Game.gameplay_type == fish.Game.GAMEPLAY_TYPE.MOUSE):
			var mouse_position_on_viewport = fish.get_viewport().get_mouse_position()/fish.Game.window_scale - fish.Game.size/2
			fish.look_at(mouse_position_on_viewport + fish.global_position)
		elif(fish.Game.gameplay_type == fish.Game.GAMEPLAY_TYPE.KEYBOARD):
			fish.look_at(fish.velocity + fish.global_position)
		
	func _physics_process(delta):
		fish.velocity += gravity_in_air
		fish.speed = fish.velocity.length()
		fish.speed = min(fish.velocity.length(), max_speed_on_air)
		#print(fish.velocity.length())
		fish.velocity = fish.velocity.normalized()*fish.speed*friction_on_air
		pass
	
	func _input():
		pass
		
	func exit():
		pass

class DashingState:
	
	var fish
	var gravity_on_water: Vector2  = Vector2(0, 0.001)
	var max_speed_on_water: float  = 10
	var friction_on_water: float   = 0.97
	var canBInjured: bool = false
	var canHurt: bool = true
	var timer_dash: int = 4
	var upspeed: int = 2
	
	func _init(fish):
		self.fish = fish
	
	func _process(delta):
		pass
	
	func _physics_process(delta):
		fish.velocity += gravity_on_water
		fish.speed = min(fish.velocity.length(), max_speed_on_water)
		fish.velocity = fish.velocity.normalized()*fish.speed*friction_on_water*upspeed
		
		timer_dash-=1
		if timer_dash < 0:
			max_speed_on_water = 4.5
			
		if timer_dash < -20:
			canHurt = false
			
		if timer_dash < -50:
			canBInjured = true
			
		if timer_dash < 0:
			self.upspeed = 1
			
			
		if(fish.Game.gameplay_type == fish.Game.GAMEPLAY_TYPE.MOUSE):
			if timer_dash < -60:
				fish.set_state(STATE.SWIMMING)
		elif(fish.Game.gameplay_type == fish.Game.GAMEPLAY_TYPE.KEYBOARD):
			if timer_dash < -32:
				fish.set_state(STATE.SWIMMING)
				
	func _input():
		pass
	
	func exit():
		pass
			
		

# Funções utilidades que podem ser usadas em qualquer estado
func rotate_child_sprite(sprite_index, time, amplitude, period, phase_shift):
	get_child(sprite_index).rotate(amplitude*sin(time * (2*PI/period) + phase_shift))	
	pass
	
# Funções relacionadas ao movimento do player
func move_with_mouse():
	if(Input.is_mouse_button_pressed(1)):
		var mouse_position_on_viewport = get_viewport().get_mouse_position()/Game.window_scale - Game.size/2
		var mouse_position = mouse_position_on_viewport + global_position 
		speed += acceleration
		velocity = (global_position.direction_to(mouse_position).normalized() * speed)

func move_with_keyboard():
	if(Input.is_action_pressed("ui_up")):
		velocity.y -= acceleration
	if(Input.is_action_pressed("ui_down")):
		velocity.y += acceleration
	if(Input.is_action_pressed("ui_left")):
		velocity.x -= acceleration
	if(Input.is_action_pressed("ui_right")):
		velocity.x += acceleration
	if(Input.is_action_pressed("ui_right")):
		velocity.x += acceleration
	if(Input.is_action_pressed("dash")):
		set_state(STATE.DASHING)

func hurt(dano = 1):
	if state.canBInjured:
		hp -= dano
		health_bar._on_health_updated(hp,0)
		

func pushBack(enemyPosition):#new
	var pushBackDirection = (self.global_position - enemyPosition).normalized()
	velocity = pushBackDirection * pushBackSpeed

func die():
	get_tree().change_scene("res://Scenes/GameOver.tscn")
	pass
	
# Funções relacionadas a entrar e sair da agua
func _on_Water_body_entered(body):
	if(body.name == "PlayerBody"):
		set_state(STATE.SWIMMING)
	
func _on_Water_body_exited(body):
	if(body.name == "PlayerBody"):
		velocity *= 2.7
		set_state(STATE.FALLING)

func heal(amount,show  = true):
	if typeof(amount) == 2:
		var old_hp = hp
		hp += amount
		if (hp > 100):
			hp = 100
		if show: 
			health_bar._on_health_updated(hp,0)
		return (hp - old_hp)
	else:
		return "Entrada invalida para a função."
		
