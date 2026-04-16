extends Node


@export_category("Dungeon Info")
@export var dungeon_size:int = 20
@export var tile_scene: PackedScene
var dungeon = []

const WALL = "#"
const PATH = "•"
const POTION = "P"
const ENEMY = "@"
const CHEST = "$"
const EXIT = "X"
const AGENT = "0"
#just added
const GATE = "H"
const KEY = "+"


# =========================
# 🚀 START
# =========================
func _ready():
	randomize()
	generate_until_valid()
	print_dungeon()
	clear_tiles()
	build_dungeon_visual() 
# =========================
# 🔁 LOOP PRINCIPAL
# =========================
func generate_until_valid():
	var attempts = 0

	while true:
		attempts += 1

		create_empty_dungeon()
		create_basic_paths()
		add_extra_paths()
		place_entities()

		if not place_exit():
			continue

		place_agent()

		if is_valid():
			print("✅ Dungeon válida após ", attempts, " tentativas")
			break

# =========================
# 🧱 MATRIZ
# =========================
func create_empty_dungeon():
	dungeon.clear()

	for y in range(dungeon_size):
		var row = []
		for x in range(dungeon_size):
			row.append(WALL)
		dungeon.append(row)

# =========================
# 📍 RANDOM
# =========================
func get_random_points(amount):
	var points = []

	while points.size() < amount:
		var p = Vector2i(
			randi() % (dungeon_size - 2) + 1,
			randi() % (dungeon_size - 2) + 1
		)

		if not points.has(p):
			points.append(p)

	return points

# =========================
# 🛣️ CORREDORES
# =========================
func carve_corridor(a:Vector2i, b:Vector2i):
	var current = a

	while current.x != b.x:
		if is_inside_inner(current.x, current.y):
			dungeon[current.y][current.x] = PATH
		current.x += sign(b.x - current.x)

	while current.y != b.y:
		if is_inside_inner(current.x, current.y):
			dungeon[current.y][current.x] = PATH
		current.y += sign(b.y - current.y)

	if is_inside_inner(b.x, b.y):
		dungeon[b.y][b.x] = PATH

func is_inside_inner(x, y):
	return x > 0 and y > 0 and x < dungeon_size - 1 and y < dungeon_size - 1

func create_basic_paths():
	var num_points = clamp(dungeon_size / 3, 3, 10)
	var points = get_random_points(num_points)

	for i in range(points.size() - 1):
		carve_corridor(points[i], points[i + 1])

func add_extra_paths():
	var extra = randi() % 5

	for i in range(extra):
		var new_point = get_random_points(1)[0]
		var existing = get_random_existing_path()
		carve_corridor(new_point, existing)

func get_random_existing_path():
	var paths = get_all_paths()
	return paths.pick_random()

func get_all_paths():
	var paths = []

	for y in range(dungeon_size):
		for x in range(dungeon_size):
			if dungeon[y][x] in [PATH, AGENT]:
				paths.append(Vector2i(x,y))

	return paths

# =========================
# 📦 ENTIDADES
# =========================

func place_entities():
	# 1. Tenta colocar os portões PRIMEIRO
	var target_gates = max(1, dungeon_size / 6)
	var actual_gates_placed = place_gates(target_gates)
	
	# 2. Agora sim pegamos os caminhos livres (o get_all_paths não vai pegar as posições dos portões)
	var paths = get_all_paths()

	var num_enemies = dungeon_size / 4
	var num_potions = num_enemies
	var num_chests = dungeon_size / 5
	
	# 3. Colocamos o mesmo número de chaves correspondente aos portões que deram certo
	var num_keys = actual_gates_placed 

	if num_keys > 0:
		place_random(paths, KEY, num_keys)
		
	place_random(paths, ENEMY, num_enemies)
	place_random(paths, POTION, num_potions)
	place_random(paths, CHEST, num_chests)

func place_random(paths, type, amount):
	var available = paths.duplicate()

	for i in range(amount):
		if available.is_empty():
			return

		var pos = available.pick_random()
		available.erase(pos)

		dungeon[pos.y][pos.x] = type

# =========================
# 🚪 PORTÕES (GATES)
# =========================
func place_gates(amount):
	var candidates = []
	
	# Evitamos as bordas extremas (0 e dungeon_size-1) para não dar erro de Index Out of Bounds
	for y in range(1, dungeon_size - 1):
		for x in range(1, dungeon_size - 1):
			if dungeon[y][x] == PATH:
				# Checa os vizinhos diretos
				var top_is_wall = dungeon[y-1][x] == WALL
				var bottom_is_wall = dungeon[y+1][x] == WALL
				var left_is_wall = dungeon[y][x-1] == WALL
				var right_is_wall = dungeon[y][x+1] == WALL
				
				var top_is_path = dungeon[y-1][x] == PATH
				var bottom_is_path = dungeon[y+1][x] == PATH
				var left_is_path = dungeon[y][x-1] == PATH
				var right_is_path = dungeon[y][x+1] == PATH
				
				# Regra 1: Corredor Horizontal (Paredes em cima/embaixo, caminho esquerda/direita)
				var horizontal_corridor = top_is_wall and bottom_is_wall and left_is_path and right_is_path
				
				# Regra 2: Corredor Vertical (Paredes esquerda/direita, caminho em cima/embaixo)
				var vertical_corridor = left_is_wall and right_is_wall and top_is_path and bottom_is_path
				
				if horizontal_corridor or vertical_corridor:
					candidates.append(Vector2i(x, y))
					
	var placed_count = 0
	
	# Coloca os portões aleatoriamente dentro dos candidatos válidos
	while placed_count < amount and not candidates.is_empty():
		var pos = candidates.pick_random()
		candidates.erase(pos)
		
		# Opcional mas recomendado: Remover candidatos vizinhos para não colocar dois portões colados
		remove_neighbors_from_list(pos, candidates)
		
		dungeon[pos.y][pos.x] = GATE
		placed_count += 1
		
	return placed_count # Retorna quantos conseguiu colocar de fato

# Helper para evitar portões colados um no outro
func remove_neighbors_from_list(pos, list):
	var dirs = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	for d in dirs:
		var neighbor = pos + d
		if list.has(neighbor):
			list.erase(neighbor)

# =========================
# 🚪 EXIT
# =========================
func place_exit():
	var candidates = []

	for y in range(dungeon_size):
		for x in range(dungeon_size):
			if dungeon[y][x] == PATH:
				if count_neighbors(x,y) == 1:
					candidates.append(Vector2i(x,y))

	if candidates.is_empty():
		return false

	var pos = candidates.pick_random()
	dungeon[pos.y][pos.x] = EXIT
	return true

# =========================
# 🤖 AGENTE SPAWN
# =========================
func place_agent():
	var paths = get_all_paths()
	var exit_pos = get_positions(dungeon, EXIT)
	var enemies = get_positions(dungeon, ENEMY)

	var best = null
	var best_score = -INF

	for p in paths:
		var score = 0

		if not exit_pos.is_empty():
			score += abs(p.x - exit_pos[0].x) + abs(p.y - exit_pos[0].y)

		if not enemies.is_empty():
			var min_dist = INF
			for e in enemies:
				var d = abs(p.x - e.x) + abs(p.y - e.y)
				if d < min_dist:
					min_dist = d
			score += min_dist

		if score > best_score:
			best_score = score
			best = p

	if best != null:
		dungeon[best.y][best.x] = AGENT

# =========================
# 🔍 UTILS
# =========================
func count_neighbors(x,y):
	var count = 0
	var dirs = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

	for d in dirs:
		var nx = x + d.x
		var ny = y + d.y

		if is_inside(nx,ny) and dungeon[ny][nx] != WALL:
			count += 1

	return count

func is_inside(x,y):
	return x >= 0 and y >= 0 and x < dungeon_size and y < dungeon_size

# =========================
# 🧠 VALIDAÇÃO
# =========================
func is_valid():
	return simulate_agent()

# =========================
# 🤖 SIMULAÇÃO COM A*
# =========================
func simulate_agent():
	var pos = get_positions(dungeon, AGENT)[0]
	var hp = 2
	var keys = 0 # Inventário de chaves do agente

	var sim = []
	for row in dungeon:
		sim.append(row.duplicate())

	sim[pos.y][pos.x] = PATH

	while true:
		var enemies = get_positions(sim, ENEMY)
		var chests = get_positions(sim, CHEST)
		var potions = get_positions(sim, POTION)
		var key_objs = get_positions(sim, KEY)
		var gates = get_positions(sim, GATE)
		var exit_pos = get_positions(sim, EXIT)

		# Condição de vitória: limpou inimigos/baús e chegou na saída
		if enemies.is_empty() and chests.is_empty() and exit_pos.is_empty():
			return true

		var target = null

		# PRIORIDADE 1: Sobrevivência (Se tiver pouca vida, procura poção)
		if hp <= 1 and not potions.is_empty():
			target = get_closest(pos, potions, sim)

		# PRIORIDADE 2: Pegar chaves acessíveis (sempre útil acumular para não travar)
		if target == null and not key_objs.is_empty():
			target = get_closest(pos, key_objs, sim)

		# PRIORIDADE 3: Limpar a área acessível (Inimigos, Baús, Poções restantes)
		if target == null:
			var mixed = enemies + chests + potions
			if not mixed.is_empty():
				target = get_closest(pos, mixed, sim)

		# PRIORIDADE 4: Usar chave em um portão (Se já fizemos o resto e temos chave)
		if target == null and keys > 0 and not gates.is_empty():
			target = get_closest(pos, gates, sim)

		# PRIORIDADE 5: Ir para a saída (Tudo finalizado)
		if target == null and enemies.is_empty() and chests.is_empty() and not exit_pos.is_empty():
			target = get_closest(pos, exit_pos, sim)

		# Failsafe: Se não achou NENHUM alvo alcançável, o agente ficou preso. Dungeon inválida!
		if target == null:
			return false

		# Roteamento
		var path = astar(pos, target, sim)
		if path == null:
			return false

		# Move o agente fisicamente pelo caminho gerado
		for step in path:
			pos = step
			var cell = sim[pos.y][pos.x]

			match cell:
				ENEMY:
					hp -= 1
					if hp <= 0: return false
					sim[pos.y][pos.x] = PATH
				POTION:
					hp += 1
					sim[pos.y][pos.x] = PATH
				CHEST:
					sim[pos.y][pos.x] = PATH
				KEY:
					keys += 1
					sim[pos.y][pos.x] = PATH
				GATE:
					if keys > 0:
						keys -= 1
						sim[pos.y][pos.x] = PATH
					else:
						return false # Segurança (não deve ocorrer devido à lógica acima)
				EXIT:
					sim[pos.y][pos.x] = PATH # Posição consumida para encerrar no loop seguinte

	return true
# =========================
# ⭐ A* E HELPERS
# =========================
func astar(start:Vector2i, goal:Vector2i, grid):
	var open = [start]
	var came_from = {}
	var g_score = {}
	var f_score = {}

	g_score[start] = 0
	f_score[start] = heuristic(start, goal)

	while not open.is_empty():
		var current = get_lowest_f(open, f_score)

		if current == goal:
			return reconstruct_path(came_from, current)

		open.erase(current)

		# Passamos o 'goal' para o get_neighbors
		for neighbor in get_neighbors(current, grid, goal):
			var tentative_g = g_score.get(current, INF) + 1

			if tentative_g < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + heuristic(neighbor, goal)

				if not open.has(neighbor):
					open.append(neighbor)
	return null

# Atualizado para receber o goal_pos
func get_neighbors(pos, grid, goal_pos = Vector2i(-1, -1)):
	var result = []
	var dirs = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

	for d in dirs:
		var nx = pos.x + d.x
		var ny = pos.y + d.y

		if is_inside(nx, ny):
			var cell = grid[ny][nx]
			if cell != WALL:
				if cell == GATE and Vector2i(nx, ny) != goal_pos:
					continue
				result.append(Vector2i(nx, ny))
	return result

func heuristic(a:Vector2i, b:Vector2i):
	return abs(a.x - b.x) + abs(a.y - b.y)

func reconstruct_path(came_from, current):
	var path = []

	while came_from.has(current):
		path.push_front(current)
		current = came_from[current]

	return path



func get_lowest_f(open, f_score):
	var best = open[0]
	var best_score = f_score.get(best, INF)

	for n in open:
		var score = f_score.get(n, INF)
		if score < best_score:
			best = n
			best_score = score

	return best

# =========================
# 🎯 HELPERS
# =========================
func get_positions(grid, type):
	var result = []

	for y in range(dungeon_size):
		for x in range(dungeon_size):
			if grid[y][x] == type:
				result.append(Vector2i(x,y))

	return result

func get_closest(origin, targets, grid):
	var best = null
	var best_dist = INF

	for t in targets:
		var path = astar(origin, t, grid)
		if path != null and path.size() < best_dist:
			best_dist = path.size()
			best = t

	return best

# =========================
# 🖨️ PRINT
# =========================
func print_dungeon():
	for y in range(dungeon_size):
		var line = ""
		for x in range(dungeon_size):
			line += dungeon[y][x] + " "
		print(line)
func clear_tiles():
	for child in get_children():
		if child is DungeonTile:
			child.queue_free()
func build_dungeon_visual():
	var tile_size = 32
	
	for y in range(dungeon_size):
		for x in range(dungeon_size):
			var tile = tile_scene.instantiate() as DungeonTile
			var cell = dungeon[y][x]
			if cell == WALL:
				tile.type = DungeonTile.TileType.WALL
			else:
				tile.type = DungeonTile.TileType.PATH
			 # Conteúdo da célula			 
			match cell:
				AGENT:
					tile.contains = DungeonTile.ObjectType.AGENT
				POTION:
					tile.contains = DungeonTile.ObjectType.POTION
				ENEMY:
					tile.contains = DungeonTile.ObjectType.ENEMY
				CHEST:
					tile.contains = DungeonTile.ObjectType.CHEST
				EXIT:
					tile.contains = DungeonTile.ObjectType.EXIT
				KEY:
					tile.contains = DungeonTile.ObjectType.KEY
				GATE: 
					tile.contains = DungeonTile.ObjectType.GATE
				_:
					tile.contains = DungeonTile.ObjectType.EMPTY
				
			tile.position = Vector2(x * tile_size, y * tile_size)
			add_child(tile)
