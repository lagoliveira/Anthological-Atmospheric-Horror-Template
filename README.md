# Anthological Atmospheric Horror — Template Godot

Template modular baseado em componentes para jogos de **terror atmosférico antológico** em **3D primeira pessoa**, desenvolvido na **Godot 4.x** (Forward Plus + Jolt Physics).

## ▶️ Executar

Abra o projeto no Godot 4.7 e pressione **F5**. A cena principal já está configurada como `scenes/TestScene.tscn`.

### Controles

| Tecla | Ação |
|-------|------|
| `W` `A` `S` `D` | Mover |
| `Shift` | Correr |
| `Space` | Pular |
| `F` | Lanterna |
| `E` | Interagir |

> O mapa de ações já está definido em `project.godot` (`move_forward`, `move_back`, `move_left`, `move_right`, `jump`, `sprint`, `flashlight`, `interact`).

## 📁 Estrutura do Projeto

```
res://
├── assets/icons/         # Ícones da UI (crosshair)
├── autoloads/            # GameManager (único autoload)
├── docs/                 # Relatório de bugs e arquitetura
├── scenes/               # Player, MainMenu, TestScene
├── src/
│   ├── components/
│   │   ├── base/         # Component.gd (classe base)
│   │   ├── player/       # FPController, Flashlight, SanityComponent, InteractionManager
│   │   ├── interaction/  # Interactable, Door, Note
│   │   ├── environment/  # LightSource, AudioEmitter, TriggerZone
│   │   └── inventory/    # InventoryItem, InventoryManager
│   ├── managers/         # SaveSystem, AudioManager, FadeManager, NotesManager
│   └── ui/               # Crosshair, SanityBar, MainMenu
├── tests/                # Suíte funcional de autoverificação
└── project.godot
```

## 🧩 Arquitetura Baseada em Componentes

Cada responsabilidade é um **componente** (um `Node` com `class_name`) que pode ser anexado a qualquer entidade. A comunicação ocorre via **sinais**, evitando hierarquias de herança profundas.

### Componentes principais

| Componente | Responsabilidade |
|------------|------------------|
| `Component` | Classe base: ciclo de vida e referência à entidade |
| `FPController` | Movimento, câmera, pulo, sprint e passos |
| `Flashlight` | Lanterna com bateria, consumo, recarga e flicker |
| `SanityComponent` | Sanidade do jogador; drena na escuridão/perigo |
| `InteractionManager` | Raycast de interação e prompt do objeto focado |
| `Interactable` | Base para objetos interagíveis (`Area3D`) |
| `Door` | Porta trancável, abrir/fechar com tween |
| `Note` | Nota colecionável de lore |
| `LightSource` | Luz ambiente toggleável com flicker |
| `AudioEmitter` | Áudio posicional 3D em loop |
| `TriggerZone` | Zona de gatilho para eventos |
| `InventoryItem` / `InventoryManager` | Dados e inventário do jogador |
| `SaveSystem` | Salvar/carregar partida |
| `AudioManager` | Áudio global e camadas ambientais |
| `FadeManager` | Fade de tela para trocas de capítulo |
| `NotesManager` | Controle de notas coletadas |
| `Crosshair` / `SanityBar` | HUD que reage à sanidade |

### Managers e o GameManager

Existe **um único autoload**: `GameManager`. Ele cria e possui os demais gerenciadores (`SaveSystem`, `AudioManager`, `FadeManager`, `NotesManager`, `InventoryManager`) como filhos, e expõe acessores:

```gdscript
GameManager.get_inventory_manager().has_item("chave_rustica")
GameManager.get_audio_manager().play_sound(stream)
GameManager.get_notes_manager().add_note("nota_01", "Diário", "...")
GameManager.switch_chapter("Capítulo 2", "res://scenes/chapter2.tscn")
```

> **Nota:** o script `autoloads/GameManager.gd` **não** declara `class_name`. Um autoload já ocupa o identificador global `GameManager`, e declarar uma classe com o mesmo nome gera o erro *"Class hides an autoload singleton"*. Acesse o singleton diretamente pelo nome global, sem anotação de tipo.

## 🧪 Cena de Testes

`scenes/TestScene.tscn` reúne todos os componentes em um ambiente fechado:

- **Jogador** em 1ª pessoa com lanterna, sanidade e interação
- **Porta** interativa e **nota** colecionável
- **Lâmpada** com flicker e **som ambiente** em loop
- **Zona escura** que drena a sanidade do jogador
- **HUD** com crosshair e barra de sanidade

## 🎮 Reuso em Novos Projetos (Antologia)

Cada capítulo de um jogo antológico pode ser uma cena separada. Use o `FadeManager` e o `GameManager.switch_chapter()` para transitar entre capítulos:

```gdscript
GameManager.switch_chapter("Capítulo 2", "res://scenes/chapter2.tscn")
```

Como a arquitetura é modular, você pode adicionar ou remover componentes conforme a necessidade de cada capítulo.

## 🧪 Testes

O template traz uma suíte de autoverificação com **77 verificações** que exercitam os componentes e as integrações entre eles:

```bash
godot --headless --path . res://tests/functional_test.tscn
```

O processo sai com código `0` quando tudo passa e `1` quando há falhas.
No editor, abra `tests/functional_test.tscn` e pressione **F6**.
Detalhes em [`tests/README.md`](tests/README.md).

## ⚠️ Armadilhas da Godot 4 (ao estender o template)

**Referências de nó em cenas**: para que um `NodePath` exportado seja
convertido em `Node` pelo loader, o nó **precisa** declarar o atributo
`node_paths`. Sem isso o valor fica silenciosamente `null`:

```gdscript
[node name="FlashlightComponent" type="Node3D" parent="." node_paths=PackedStringArray("light_node")]
script = ExtResource("2_fl")
light_node = NodePath("../CameraPivot/Flashlight")
```

**Busca por `%Nome`**: o lookup por unique name é escopado ao `owner` da
cena e falha quando a cena é instanciada dentro de outra. Para componentes
críticos (câmera, luz), prefira resolver **por tipo**:

```gdscript
var found: Array[Node] = entity.find_children("*", "Camera3D", true, false)
```

**Propriedades renomeadas na Godot 4**: `rotation_quaternion` → `quaternion`,
`get_owner_or_null` → `get_parent`, `PointLight3D` → `OmniLight3D`,
`energy` → `light_energy`, `enabled` → `visible`, `range` → `spot_range` /
`omni_range`, `shadows_enabled` → `shadow_enabled`.

## 📄 Licença

Template livre para uso em projetos de terror atmosférico antológico.
