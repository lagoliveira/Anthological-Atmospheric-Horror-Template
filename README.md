# Anthological Atmospheric Horror — Template Godot

Template modular baseado em componentes para jogos de **terror atmosférico antológico** em **3D primeira pessoa**, desenvolvido na **Godot 4.x**.

## Estrutura do Projeto

```
res://
├── autoloads/            # Singletons globais (GameManager, etc.)
├── scenes/               # Cenas base (Player, MainMenu)
├── src/
│   ├── components/
│   │   ├── base/         # Classe base Component
│   │   ├── player/       # FPController, Flashlight, SanityComponent
│   │   ├── interaction/  # Interactable, Door, Note
│   │   ├── environment/  # LightSource, AudioEmitter, TriggerZone
│   │   └── inventory/    # InventoryItem, InventoryManager
│   ├── managers/         # SaveSystem, AudioManager, FadeManager, NotesManager
│   └── ui/               # Crosshair, SanityBar
└── project.godot
```

## Arquitetura Baseada em Componentes

Cada responsabilidade é um **componente** (um `Node` com `class_name`) que pode ser anexado a qualquer entidade. A comunicação entre componentes ocorre via **sinais**, evitando hierarquias de herança profundas.

### Componentes principais

| Componente | Responsabilidade |
|------------|------------------|
| `FPController` | Movimento e câmera em primeira pessoa |
| `Flashlight` | Lanterna com bateria, consumo e flicker |
| `SanityComponent` | Sanidade do jogador; afeta áudio e UI |
| `Interactable` | Base para objetos interagíveis |
| `Door` | Porta trancável/abrir-fechar |
| `Note` | Nota colecionável (lore) |
| `LightSource` | Luz ambienteToggleável |
| `AudioEmitter` | Áudio posicional 3D |
| `TriggerZone` | Zona de gatilho para eventos |
| `InventoryItem` | Dado de item de inventário |
| `InventoryManager` | Gerenciador de inventário |
| `SaveSystem` | Salvar/carregar partida |
| `AudioManager` | Gerenciador global de áudio |
| `FadeManager` | Fade de tela para trocas de capítulo |
| `NotesManager` | Controle de notas coletadas |

## Configuração no Godot

1. Abra o projeto no Godot 4.x.
2. Vá em **Projeto > Configurações do Projeto > Autoloads** e adicione `GameManager.gd` como `GameManager`.
3. Configure as Ações de Input no **Mapa de Input**:
   - `move_forward`, `move_back`, `move_left`, `move_right`
   - `jump`
   - `Flashlight`
4. Defina `scenes/MainMenu.tscn` como cena principal (ou `scenes/Player.tscn` para teste direto).

## Uso em Novos Projetos (Antologia)

Cada capítulo de um jogo antológico pode ser uma cena separada. Use o `FadeManager` e o `GameManager.switch_chapter()` para transitar entre capítulos:

```gdscript
var game_manager: GameManager = get_node("/root/GameManager")
game_manager.switch_chapter("Capítulo 2", "res://scenes/chapter2.tscn")
```

## Git e GitHub

Este projeto está versionado com Git. Para vincular ao seu repositório GitHub:

```bash
git remote add origin https://github.com/SEU_USUARIO/SEU_REPOSITORIO.git
git branch -M main
git push -u origin main
```

## Licença

Template livre para uso em projetos de terror atmosférico antológico.
