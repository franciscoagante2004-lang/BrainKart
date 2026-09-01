# 🏎️ BrainKart

Jogo de kart no Roblox Studio inspirado no Mario Kart.

## 📁 Estrutura

```
src/
├── ServerScriptService/
│   ├── GameManager.server.lua      ← Gere corrida, voltas, posições
│   └── KartSpawner.server.lua      ← Cria e liga karts aos jogadores
├── StarterPlayer/
│   └── StarterPlayerScripts/
│       └── KartController.client.lua ← Física do kart + câmara
└── StarterGui/
    ├── MainMenuScript.client.lua   ← Menu de jogo animado
    └── RaceHUDGui/
        └── HudScript.client.lua    ← HUD: posição, volta, velocidade
```

## 🎮 Controlos

| Tecla | Ação |
|-------|------|
| W / ↑ | Acelerar |
| S / ↓ | Travar / Ré |
| A / ← | Virar esquerda |
| D / → | Virar direita |
| SPACE / LShift | Drift + Boost |

## 🚀 Setup

### 1. Instalar Rojo
```bash
# Rojo já instalado como plugin no Studio
# CLI em C:\Users\franc\AppData\Local\rojo\rojo.exe
```

### 2. Servir o projeto
```bash
cd C:\Users\franc\BrainKart
rojo serve
```

### 3. Ligar no Studio
- Abre Roblox Studio
- Plugin Rojo → **Connect** → `localhost:34872`

### 4. Criar a pista
- No Studio, executa `FullRebuildBrainKart.lua` via plugin Execute Luau
- Isto cria a pista oval, spawn points e KartTemplate

### 5. Jogar!
1. Clica **Play**
2. Espera 2-3 segundos (kart a criar)
3. Clica **JOGAR** no menu
4. **3-2-1-GO!** 🏁

## 🔧 Desenvolvimento

```bash
# Ver alterações em tempo real no Studio:
rojo serve

# Commit de alterações:
git add .
git commit -m "feat: descrição da alteração"
git push
```
