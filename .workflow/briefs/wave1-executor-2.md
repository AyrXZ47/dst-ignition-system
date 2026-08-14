# Brief: Wave 1 · Executor 2

> Documentación y repo hygiene — texto puro. No tocas NINGÚN archivo KiCad.
> Puedes correr en paralelo con el trabajo del humano y del executor-1.

## Task

1. **Crear `docs/design-notes.md`** — la referencia de diseño del sistema.
   Contenido mínimo (todo en español, como el repo):
   - **Topología**: RP2040 (Pico) + TP4056 (carga Li-ion) + AOD4184A (NMOS
     de ignición) + 2 conectores LoRa/nRF24 + display I2C + LEDs. Mapa de
     bloques en ASCII.
   - **Mapa de pines RP2040** (fuente: netlist exportado — ver read-first):
     GPIO13=BTN_FIRE, GPIO15=IGNITION_GATE, GPIO10/11/12=LED_LINK/MODO/
     ARMADO, GPIO26/ADC0=ADC_Bateria, GPIO4/5=I2C display, GPIO16-22=SPI
     LORA, VBUS/VSYS/3V3/GND.
   - **Decisiones de diseño** (del decision log en `.workflow/plan.md`):
     CE→VBUS, TEMP→GND (con `ponytail:` naming el techo y upgrade path),
     labels DIO eliminados, human-in-the-loop como modelo de trabajo.
   - **BOM preliminar**: componentes, valores, footprints (extraerlos del
     `.kicad_sch` — puedes LEERLO, nunca escribirlo).
   - **Estado del PCB**: no ruteado (0 pistas/vias), DRC 34 violaciones
     (6 drill 0.2mm < 0.3mm min + 28 silk) y 59 pads sin conectar —
     pendiente ola 3.
   - **Pendientes/riesgos**: margen Vto del AOD4184A vs 3.3V (ola 2),
     firmware `src/` aún vacío, confirmar tipo de ignitor y módulos.
2. **Añadir `*.lck` a `.gitignore`** — los `~*.kicad_sch/pcb/pro.lck` son
   locks de KiCad abierto y ensucian `git status`.
3. **Actualizar `README.md`** — el README promete firmware Rust/Embassy que
   aún no existe en `src/` (vacío). Añade sección "Estado del hardware"
   apuntando a `docs/design-notes.md` y a los artefactos. No inventes
   features ni inventes un estado que no sea cierto.

## Definition of done

- `docs/design-notes.md` existe y cubre los 6 bloques del task.
- `.gitignore` ignora `*.lck` y `git status` queda limpio de `.lck`.
- `README.md` refleja el estado real (sin prometer firmware inexistente).
- La verify command pasa.

## Files you own

- `docs/design-notes.md` (nuevo)
- `.gitignore`
- `README.md`

## Files forbidden

- `hardware/Kicad/ignition-system/*` (todo el árbol KiCad — LEER sí,
  ESCRIBIR nunca; ni siquiera el PDF, ese es del executor-1)
- `docs/ignition-system.pdf` (executor-1)
- `docs/.gitkeep`
- `.workflow/*`, `AGENTS.md`, `src/*`

## Read first

- `.workflow/plan.md` — decision log con las decisiones ya tomadas.
- `hardware/Kicad/ignition-system/ignition-system.kicad_sch` — instancias
  de componentes (Reference/Value/Footprint) ≈líneas 6300-9800.
- `hardware/Kicad/ignition-system/DRC.rpt` — estado del PCB.
- `README.md` actual.

Para el mapa de pines usa el netlist exportado:

```bash
kicad-cli sch export netlist --format kicadsexpr --output /tmp/opencode/net-e2.net \
  hardware/Kicad/ignition-system/ignition-system.kicad_sch
```

## Verify command

```bash
# 1. design-notes existe y no está vacío:
test -s docs/design-notes.md

# 2. .gitignore cubre los .lck:
grep -q 'lck' .gitignore

# 3. README actualizado menciona el estado del hardware:
grep -q 'design-notes' README.md

# 4. git status limpio de .lck:
git status --short | grep -c 'lck' ; echo "esperado: 0"
```

Ejecuta las 4 antes de commitear.

## Commit

- Conventional commits, una línea, imperativo. Ejemplos:
  `docs: add design notes for ignition system`,
  `chore: ignore kicad lock files`,
  `docs: update readme hardware status`.
  Tres cambios lógicos → tres commits.
- Commit ONLY your owned files.
- BRANCH ISOLATION: commit AND push ONLY a `wave1-executor-2`.
- Nunca `cd` fuera de tu worktree ni `git checkout|switch|branch|worktree|stash`.

## Report back

- Archivos creados/modificados y resumen.
- Salida de la verify command (4 checks).
- Discrepancias encontradas entre netlist/DRC y lo documentado.
