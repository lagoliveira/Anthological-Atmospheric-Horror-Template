# Relatório de Bugs — Anthological Atmospheric Horror Template

**ID**: BUG-0001
**Severidade**: S1-Critical
**Prioridade**: P1-Immediate
**Status**: Resolvido
**Reportado**: 2026-11-27
**Repórter**: Auditoria automatizada (OpenCode / Lead Programmer)
**Build**: commit `9c4d4eb` (Godot 4.7.2-stable)

---

## Resumo

A auditoria completa do template encontrou **38 defeitos**, distribuídos em
três camadas:

| Camada | Qtd | Efeito |
|---------|-----|--------|
| Compilação / parsing | 8 | O projeto **não abria** no editor |
| Cabeamento de cenas | 4 | Todas as referências de nós ficavam `null` em runtime |
| Lógica de jogo | 26 | Comportamento incorreto em gameplay |

**Causa raiz estrutural**: o projeto foi escrito para a API do Godot 3 e
migrado para o Godot 4 por substituição textual, sem validação com o
motor. Nenhum script havia sido executado — os erros só apareciam quando o
usuário abria o editor.

**Correção**: 38 defeitos corrigidos e uma suíte de 77 verificações
automatizadas adicionada (`tests/functional_test.tscn`), que impede a
regressão.

---

## Ambiente

- **Motor**: Godot 4.7.2-stable (Linux x86_64, headless)
- **Plataforma**: Linux / WSL
- **Cena principal**: `res://scenes/TestScene.tscn`
- **Estado**: projeto recém-migrado do Godot 3, ainda sem nenhum teste

### Ferramenta de validação

A auditoria não pode depender de leitura de código. Foi baixado o binário
oficial do Godot 4.7.2 e passa-se a validar com três níveis:

1. **Carga de recursos** — carrega todos os `.gd` e `.tscn` do projeto
2. **Smoke test** — instancia cada cena e a executa por 30 frames
3. **Teste funcional** — 77 asserções sobre o comportamento real

```bash
godot --headless --path . res://tests/functional_test.tscn
```

---

## Classificação

- **Categoria**: Crash / Gameplay / UI
- **Sistema**: Template base (interação, inventário, save, sanity, lanterna, UI)
- **Frequência**: Sempre (100%)
- **Regressão**: Não (defeitos introduzidos na migração)

---

## Defeitos de Compilação (S1 — bloqueiam a abertura do projeto)

### BUG-01 — `get_owner_or_null()` não existe no Godot 4
**Arquivo**: `src/components/base/Component.gd:16`

API da Godot 3 removida na 4.x. O script base de todos os componentes
não compilava.

```gdscript
# antes
var owner_node: Node = get_owner_or_null()

# depois
var owner_node: Node = get_parent()
```

---

### BUG-02 — `PointLight3D` não existe no Godot
**Arquivo**: `scenes/TestScene.tscn`

```
ERROR: Cannot get class 'PointLight3D'.
```

O tipo correto é `OmniLight3D`. O nó inteiro (`LampLight`) e o componente
que dependem dele (`LampComponent`) foram recriados.

---

### BUG-03 — `LampComponent`: nó `Node` com script que estende `Node3D`
**Arquivo**: `scenes/TestScene.tscn`

```
Script inherits from native type 'Node3D', so it can't be assigned to an object of type: 'Node'
```

O script `LightSource.gd` estende `Node3D`, mas o nó da cena era do tipo
`Node`. O nó passou a ser `Node3D`.

---

### BUG-04 — `AmbientSoundComponent`: nó `Node` com script que estende `AudioStreamPlayer3D`
**Arquivo**: `scenes/TestScene.tscn`

Mesma causa de BUG-03. Como `AudioEmitter.gd` já **é** um player 3D, o
componente foi fundido no próprio nó `AmbientSound` (um script por nó),
eliminando a classe wrapper.

---

### BUG-05 — `DarkZoneComponent`: nó `Node` com script que estende `Area3D`
**Arquivo**: `scenes/TestScene.tscn`

Mesma causa. O `TriggerZone` foi fundido no próprio `Area3D`.

---

### BUG-06 — `FlashlightComponent`: nó `Node` com script que estende `Node3D`
**Arquivo**: `scenes/Player.tscn`

Mesma causa de BUG-03.

---

### BUG-07 — `rotation_quaternion` não existe no Godot 4
**Arquivos**: `src/components/interaction/Door.gd`, `src/managers/SaveSystem.gd`

Em Godot 4 a propriedade é `quaternion`. A porta animava uma propriedade
inexistente e o save gravava uma rotação sempre zerada.

```gdscript
# antes
closed_rotation = door_node.rotation_quaternion
tween.tween_property(door_node, "rotation_quaternion", target, ...)

# depois
closed_rotation = door_node.quaternion
tween.tween_property(door_node, "quaternion", target, ...)
```

---

### BUG-08 — `get_node_or_null()` incompatível com variáveis tipadas
**Arquivos**: `scenes/TestScene.gd`, `src/ui/MainMenu.gd`, `src/components/player/FPController.gd`

`get_node_or_null()` devolve `Node`, que não é atribuível a `TriggerZone`,
`LightSource`, `Node3D`, `Camera3D`, `Label` ou `Button`. Nove pontos
corrigidos com cast explícito:

```gdscript
@onready var dark_zone: TriggerZone = get_node_or_null("DarkZone") as TriggerZone
@onready var camera: Camera3D = get_node_or_null("CameraPivot/Camera") as Camera3D
```

---

## Defeitos de Cabeamento de Cenas (S2 — runtime silencioso)

### BUG-09 — Referências `NodePath` exportadas sempre resolviam para `null`
**Arquivos**: `scenes/Player.tscn`, `scenes/TestScene.tscn`

**Este era o bug mais silencioso do projeto.** O Godot 4 só converte
`NodePath` → `Node` no loader quando o nó declara o atributo
`node_paths=PackedStringArray(...)`. Sem esse atributo, **todas** as
referências exportadas ficavam `null` — sem erro, sem aviso.

```gdscript
# NodePath exportado, mas nunca resolvido:
[ext_resource type="Script" path="res://src/components/player/Flashlight.gd" id="2_fl"]

[node name="FlashlightComponent" type="Node3D" parent="."]
script = ExtResource("2_fl")
light_node = NodePath("../CameraPivot/Flashlight")   # -> null
```

```gdscript
# Correto:
[node name="FlashlightComponent" type="Node3D" parent="." node_paths=PackedStringArray("light_node")]
script = ExtResource("2_fl")
light_node = NodePath("../CameraPivot/Flashlight")
```

Impacto: lanterna sem luz, porta sem malha para animar, lâmpada sem
referência.

---

### BUG-10 — `unique_name_in_owner` como atributo do cabeçalho do nó
**Arquivo**: `scenes/Player.tscn`

O atributo no cabeçalho (`[node name="X" type="Y" parent="." unique_name_in_owner=true]`)
não é aplicado — a propriedade tem de ser uma linha própria:

```gdscript
[node name="Camera" type="Camera3D" parent="CameraPivot"]
unique_name_in_owner = true
```

Verificado empiricamente: `is_unique_name_in_owner()` retornava `false`.

---

### BUG-11 — Busca por `%Nome` dependia da cadeia de `owner`
**Arquivos**: `src/components/player/FPController.gd`, `src/components/player/InteractionManager.gd`

`%Camera` só resolve dentro do `owner` da cena. Quando o `Player.tscn` é
instanciado dentro de `TestScene.tscn`, o `owner` do jogador é a cena
pai e o lookup falha. Substituído por resolução **por tipo**, que é
independente da estrutura da cena:

```gdscript
func _find_camera() -> Camera3D:
	var found: Array[Node] = entity.find_children("*", "Camera3D", true, false)
	if found.is_empty():
		return null
	return found[0] as Camera3D
```

---

### BUG-12 — Geometria e colliders desalinhados
**Arquivo**: `scenes/TestScene.tscn`

| Elemento | Mesh | Collider | Problema |
|----------|------|----------|----------|
| Piso | `y = 0.25` (topo em `0.5`) | `y = 0.25` | Jogador empurrado para cima |
| Porta | `y = 1.1` | `y = 0` (centro) | Raycast não atingia a porta |
| Nota | `y = 0.3` | `y = 0` | Volume de interação deslocado |

O piso foi rebaixado (`y = -0.25`, topo em `0`) e os colliders foram
alinhados às respective malhas.

---

## Defeitos de Lógica (S2/S3 — gameplay)

### Movimento e câmera

| # | Defeito | Correção |
|---|---------|----------|
| 13 | **BUG-13**: `_get_move_direction` usava a basis completa da câmera (inclui pitch) → ao olhar para cima o jogador *flutuava* ao andar | Projeção no plano horizontal (`direction.y = 0`) antes de normalizar |
| 14 | **BUG-14**: `move_velocity.y` nunca era zerado no chão → velocidade descendente residual após aterrissar | `move_velocity.y = 0.0` no ramo `on_floor` |
| — | `player_sprinted` era emitido todo frame, afogando listeners | Emissão apenas na transição |

### Sanidade

| # | Defeito | Correção |
|---|---------|----------|
| 15 | **BUG-15**: `sanity_critical` era **inalcançável** — o `elif sanity <= 10` nunca era verdadeiro, pois o ramo anterior (`sanity <= 30 and sanity > 0`) capturava todo valor entre 0 e 10 | Reordenação: crítico é testado primeiro |
| 16 | **BUG-16**: `low_sanity_reached` era emitido **todo frame** enquanto a sanidade ficava abaixo do limiar | Detecção de borda (`_was_low`) |
| 37 | **BUG-37**: `Component._component_process` / `_component_physics_process` nunca eram chamados — o padrão de hooks era código morto | `Component` implementa `_process` / `_physics_process` e despacha para os hooks |
| 38 | **BUG-38**: `SanityComponent` sobrescrevia `_process` em vez de usar o hook | Migrado para `_component_process` |

### GameManager

| # | Defeito | Correção |
|---|---------|----------|
| 17 | **BUG-17**: `player_registered` **só** era emitido se existisse um filho chamado exatamente `SanityComponent` | Emissão incondicional + busca recursiva na subárvore |
| 18 | **BUG-18**: sem auto-descoberta do jogador — sem `InteractionManager`, `GameManager.player` ficava `null` para sempre | Descoberta por grupo `Player` com retry por frame |

### Save / Load

| # | Defeito | Correção |
|---|---------|----------|
| 19 | **BUG-19**: `SaveSystem.load_game` **nunca restaurava o inventário** — o corpo era `pass` | `InventoryManager.from_save_data()` |
| 20 | **BUG-20**: `get_save_list()` devolvia `["slot.save"]` mas `delete_save()` esperava `["slot"]` — API inconsistente | `get_save_list()` devolve IDs; `get_save_slots()` devolve metadados |
| — | `store_var` **não serializa Resources**: o inventário seria perdido ao salvar | `InventoryManager.to_save_data()` achata os metadados em primitivos |
| 21 | **BUG-21**: `get_all_items()` devolvia cópia rasa — `items[id]["count"]` era compartilhado entre a cópia e o original | Cópia do dicionário interno por entrada |

### Interação

| # | Defeito | Correção |
|---|---------|----------|
| 22 | **BUG-22**: `highlight_on_look` e `highlight_color` eram **código morto** — `set_highlight()` não aplicava nada visual | `material_overlay` (overlay por instância, não destrutivo) nas malhas vizinhas |
| 23 | **BUG-23**: eco de teclado disparava a interação repetidamente (`is_action_pressed` casa com eventos `echo`) | `event.is_echo()` |
| 24 | **BUG-24**: `current_target` apontava para um objeto **liberado** (a Nota se auto-destrói) → *Invalid access to freed object* | Validação com `is_instance_valid()` |
| 25 | **BUG-25**: `interaction_distance` do interativo era ignorado — o `ray_length` global sempre vencia | Distância do hit comparada com a do interativo |
| 26 | **BUG-26**: `Note` emitia `interacted` **duas vezes** (na subclasse e na classe base) | Removida a emissão duplicada |

### Áudio

| # | Defeito | Correção |
|---|---------|----------|
| 27 | **BUG-27**: `AudioEmitter` atribuía `autoplay` em `_ready()` (tarde demais) **e** tinha um segundo `play()` no ramo do `await` → som tocava duas vezes | `play()` explícito após o atraso |
| 28 | **BUG-28**: `"loop" in stream` não casa com a API real — `AudioStreamWAV` usa `loop_mode`, `AudioStreamOggVorbis`/`MP3` usam `loop` | Despacho por tipo de stream |
| 29 | **BUG-29**: `AudioManager.set_ambient(null)` chamava `play()` com stream nulo | Guarda + `stop()` |
| 30 | **BUG-30**: `finished.connect()` era feito **depois** de `play()` → som muito curto podia vazar um player órfão | Conexão antes do `play()` |
| — | `volume_db` recebia um ganho linear (0.0–1.0) em vez de decibels | `_gain_to_db()` com `linear_to_db()` |

### Visual / UI

| # | Defeito | Correção |
|---|---------|----------|
| 31 | **BUG-31**: a lanterna esgotava a bateria mas **não parava o flicker** — o flicker podia reacender a luz visualmente com a lanterna "desligada" | `is_flickering = false` + `visible = false` no esgotamento |
| 32 | **BUG-32**: `LightSource.turn_on()` não restaurava a energia original, mantida alterada pelo flicker | `light_energy = original_energy` |
| 33 | **BUG-33**: `Crosshair._ready()` sobrescrevia os offsets com `size.x` — que é **0** na `_ready()` (layout ainda não resolvido) → crosshair colapsado para tamanho zero | Offsets derivados do tamanho da textura |
| 34 | **BUG-34**: o wobble do crosshair **nunca era restaurado** ao recuperar a sanidade (só o alpha) | Offsets base restaurados |
| 35 | **BUG-35**: `FadeManager` usava `layer = 1`, a **mesma** camada da HUD → o fade podia ficar atrás da HUD | `layer = 100` (`fade_layer` exportável) |
| 36 | **BUG-36**: `change_scene_fade()` usava dois tweens independentes → sobreposição de estados, fade travado | Tween único encadeando fade-out → troca → fade-in |

---

## Procedimento de Reprodução (antes da correção)

1. Abrir o projeto no Godot 4.7
2. O editor falha ao carregar `src/components/base/Component.gd`:
   `Parse Error: Function "get_owner_or_null()" not found in base self.`
3. Ao remover o erro de parsing, aparecem em cascata:
   - `Cannot get class 'PointLight3D'`
   - `Script inherits from native type 'Node3D', so it can't be assigned to an object of type: 'Node'` (×3)
   - `Identifier not found: GameManager`
4. Após a compilação, ao **executar**:
   - Nenhuma referência de nó resolve → lanterna/porta/lâmpada inertes
   - O crosshair não aparece
   - A porta não abre ao interagir
   - O inventário não é restaurado ao carregar

**Resultado esperado**: o projeto abre, executa e todos os componentes
respondem.

**Resultado atual**: 77/77 verificações passam, zero erros em runtime.

---

## Verificação

```bash
# Suite funcional
godot --headless --path . res://tests/functional_test.tscn
# -> === RESULTADO: 77 passaram, 0 falharam ===  (exit code 0)

# Jogo real, 300 frames
godot --headless --path . --quit-after 300
# -> sem saída (zero erros)
```

---

## Recomendações

1. **Não confiar em leitura de código** para validar um motor. O binário do
   Godot headless (`--headless --path . --quit-after N`) é um validador
   completo e leve.
2. **Manter a suíte em `tests/`** e executá-la em toda alteração. Ela
   cobre exatamente as 38 regressões corrigidas.
3. **Ao exportar um `Node`/`NodePath`**, declarar `node_paths=PackedStringArray(...)`
   no nó da cena — sem isso o valor é silenciosamente `null`.
4. **Ao migrar da Godot 3 para a 4**, os pontos de maior risco são:
   `rotation_quaternion`, `get_owner_or_null`, `setget`, `onready`,
   `export`, `yield`, `Spatial`/`KinematicBody`/`PointLight`,
   `rotation_quaternion`, `OS.get_*`, `Pool*Array`, `instance()`.
5. **Evitar `%Nome`** para componentes críticos. A resolução por tipo
   (`find_children("*", "Camera3D", true, false)`) é independente da
   estrutura da cena e sobrevive à instanciação aninhada.
