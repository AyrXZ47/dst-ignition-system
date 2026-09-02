# Plan: DST Ignition System — diseño hardware listo para fabricación

> Single source of truth for the work. Committed, survives any session.
> ONLY the next wave is detailed (rolling plan). When a session dies, a new
> instance resumes from this file — never from memory.

## Goal

Sistema de ignición remota para cohetería experimental (Dragons Space Team):
esquemático y PCB (RP2040 + TP4056 + MOSFET AOD4184A + 2×LoRa/nRF24 + display
I2C) listos para fabricar. "Done" = ERC 0 errores, DRC 0 errores, disparo del
ignitor validado por simulación SPICE, y Gerbers + BOM generados.

## Stack & constraints

- KiCad 8.x/10 (formatos `.kicad_sch` / `.kicad_pcb` = S-expression, texto).
- Verificación headless: `kicad-cli` v10.0.5 (sch erc, sch export netlist,
  sch export pdf, pcb drc, pcb export gerbers).
- Modelo SPICE local: `hardware/Kicad/ignition-system/Local Spice/AOD4184A.lib`
  (VDMOS, Vto=2.61V, Ron=5.8mΩ).
- Simulación: ngspice-45 (instalado globalmente 2026-09-01, gate de la ola 2
  desbloqueado). Auxiliares del humano: `spice-find` / `spice-get`
  (kicad-spice-library, ~50k modelos; `spice-get aod4184a` extrae un modelo
  saneado y validado en ngspice a `localSpice.lib` del proyecto).
- Ignitor/e-match estándar (~1-2Ω, ~1A) — pendiente confirmar con el humano.
- Licencias: hardware CERN-OHL-P-2.0, software Apache-2.0.
- **Modelo de trabajo: HUMAN-IN-THE-LOOP (adaptación del flujo AGENTS.md a
  hardware).** El humano es el único que edita archivos en la GUI de KiCad
  (esquemático y PCB). Los agentes: planifican, instruyen paso a paso,
  verifican con kicad-cli, documentan, simulan. Ningún agente "edita por
  texto" archivos KiCad salvo los cambios quirúrgicos explícitamente
  marcados como seguros; y siempre con verificación headless posterior.
- Regla ponytail: mínimo cambio que funciona; no añadir drivers/partes hasta
  que la simulación demuestre que hacen falta.

## Waves

| Wave | Focus | Status |
|------|-------|--------|
| 1 | Esquemático limpio: ERC 0, fixes TP4056 (CE→VBUS, TEMP), labels DIO, artefactos docs | [x] integrated (ERC 0 verificado 2026-08-18) |
| 2 | Validación de potencia por SPICE (gate 3.3V vs Vto 2.61V, disparo del ignitor) | [x] audited 2026-09-01 (APPROVED WITH EXCEPTIONS, ver `.workflow/audits/wave2.md`) |
| 3 | PCB: reglas, planos de cobre, ruteo (HUMANO en GUI), DRC 0 | [ ] planned |
| 4 | Release: Gerbers, BOM, PDF final, security-audit | [ ] planned |

> Status legend: planned → in-flight → integrated → audited → done.
> Update after each step, by whoever ran the step.

---

## Wave 1 (current)

### Cómo se ejecuta esta ola (orden estricto)

1. **Humano (GUI):** hace los 3 fixes del esquemático siguiendo el brief
   manual `wave1-human-schematic.md` — son ~5 minutos de clics.
2. **Executor-1 (agente):** verifica el trabajo del humano con kicad-cli
   (ERC 0 + netlist correcto), regenera el PDF y lo commitea.
3. **Executor-2 (agente, puede correr en paralelo):** documentación,
   .gitignore, README — texto puro, no toca KiCad.
4. **Integrador:** merge en el orden indicado + verificación final.

### File ownership map

| File/glob | Owner |
|-----------|-------|
| `hardware/Kicad/ignition-system/ignition-system.kicad_sch` | HUMANO (GUI) — ediciones en wave 1 |
| `hardware/Kicad/ignition-system/ignition-system.kicad_pcb` | prohibido en wave 1 (ola 3, GUI) |
| `docs/ignition-system.pdf` | executor-1 (regenerado, verificado) |
| `docs/design-notes.md` (nuevo), `README.md`, `.gitignore` | executor-2 |
| `hardware/Kicad/ignition-system/Local Spice/*`, `.history/`, `DRC.rpt`, `*.lck`, `*.kicad_pro` | prohibido |

### Tasks

- [ ] H1: Humano (GUI): CE del TP4056 → net VBUS (el "VCC" no tiene fuente);
      TEMP (pin 1) → GND; borrar labels DIO1-DIO5 →
      brief: `.workflow/briefs/wave1-human-schematic.md`
- [ ] T1: executor-1: verificar (ERC 0 + netlist VBUS/GND sin VCC huérfano),
      regenerar `docs/ignition-system.pdf` → brief: `.workflow/briefs/wave1-executor-1.md`
- [ ] T2: executor-2: `docs/design-notes.md` (topología, mapa de pines,
      decisiones, BOM, estado PCB), `*.lck` a `.gitignore`, README →
      brief: `.workflow/briefs/wave1-executor-2.md`

### Integration plan

Orden: **executor-2** (docs, sin dependencias) y **trabajo del humano** en
paralelo; luego **executor-1** verifica/regenera el PDF; por último merge e
integración. Ramas: humano commitea en su rama `wave1-human` (o en main si
prefiere; el integrador decide), executor-1 → `wave1-executor-1`,
executor-2 → `wave1-executor-2`.

```bash
# 1. merge wave1-executor-2 -> main   (docs, sin conflicto)
# 2. humano: fixes en GUI + commit en wave1-human (o main)
# 3. executor-1: verifica ERC + regenera PDF (tras el fix humano)
# 4. merge humano (wave1-human o main) + wave1-executor-1 -> main
# 5. verificación final en el árbol integrado:
kicad-cli sch erc --output /tmp/opencode/erc-final.rpt \
  hardware/Kicad/ignition-system/ignition-system.kicad_sch   # "Errors 0"
```

En conflicto: STOP y reportar. Nunca resolver con criterio propio.

### Audit gate

Correr `.workflow/audit-checklist.md` en el árbol integrado. Específico:

- Solo se modificaron archivos del ownership map.
- ERC en el árbol integrado: 0 errores (evidencia: erc-final.rpt).
- Netlist integrado: net `VBUS` incluye `ModuloDeCarga1.8`; net `GND`
  incluye `ModuloDeCarga1.1`; el net "VCC" huérfano ya no existe.
- `docs/design-notes.md` existe y cubre: topología, mapa de pines, decisiones.
- El PDF regenerado es más reciente que el commit `0df3d5b`.

---

## Wave 2 (current — next wave)

### Por qué ANTES del ruteo (orden crítico)

El AOD4184A tiene Vto=2.61V y el gate viene de 3.3V → Vgs−Vto≈0.7V. Si el
MOSFET no conduce suficiente corriente para el ignitor (~1-2Ω, 1A), hay que
cambiar de MOSFET o añadir un driver de gate — y ESO cambia el ruteo de toda
la zona de potencia. Rutear sin validar = re-spin de 2 semanas en China.
SPICE primero; el ruteo (ola 3) no empieza hasta que esta ola dé verde.

### Qué se simula (y qué NO)

- **NO** se simula la placa completa ni el RP2040: un GPIO digital es una
  fuente pulsada 0→3.3V; el Pico no entra en SPICE.
- **NO** se simula el TP4056 (cargador lineal, no crítico para el disparo).
- **SÍ** se simula el subcircuito de ignición: fuente pulsada 3.3V → R11 220Ω
  → gate (R7 10k a GND) → AOD4184A (modelo local en `Local Spice/`) → ignitor
  (~1-2Ω) entre VSYS y drain. Corriente de disparo, caída en el MOSFET,
  slew rate, requisito mínimo de corriente del ignitor.

### File ownership map

| File/glob | Owner |
|-----------|-------|
| `sim/wave2/*.cir`, `sim/wave2/*.cpp` (nuevos), informe | executor-3 |
| `hardware/Kicad/ignition-system/*` | prohibido para executor-3 (ni lectura requerida salvo el .lib y el .kicad_sch) |
| `hardware/Kicad/ignition-system/ignition-system.kicad_sch` | HUMANO, SOLO para H4 (borrar stubs; nada más) |
| `docs/design-notes.md` | prohibido salvo añadir §7 "Validación SPICE" (revisar con planner si hace falta) |

### Tasks

- [ ] H4 (humano, GUI, paralelo con executor-3): borrar los 4 stubs de cable
      sueltos junto a CHRG1/STDBY1 → ERC 0/0 (ver brief manual H4 en el
      decision log; causas y coordenadas documentadas 2026-09-01)
- [x] T3: Generar netlist SPICE del subcircuito de ignición, casos de test
      (corriente de ignitor a 3.3V, a 3.6V LiPo, con R11=220Ω), correr en
      ngspice, escribir informe con veredicto → brief:
      `.workflow/briefs/wave2-executor-3.md`
- Requisito: instalar ngspice — **hecho** (ngspice-45 global, 2026-09-01).

### Integration plan

- Executor-3 en rama `wave2-executor-3`; merge a `main`; revisar informe.
- Veredicto del informe = gate de la ola 3: si Vgs es insuficiente, el humano
  decide (driver vs MOSFET) y se ajusta el esquemático ANTES de rutear.

### Audit gate

- El informe existe, ngspice corrió (salida transitoria/dc adjunta), y el
  veredicto tiene números: corriente de ignitor, Vds, potencia disipada.

---

## Wave 3 (current — next wave)

### Objetivo

PCB listo para fabricar: reglas de board setup corregidas (executor-4),
placement + ruteo hechos por el HUMANO en GUI, DRC 0 errores, y datos
reales del ignitor incorporados (condición del audit de wave 2).

### Orden estricto

1. **T6 (executor-4):** board setup `min_through_hole_diameter` 0.3 → 0.2mm
   en `.kicad_pro` (JSON, clave `"design_settings.rules.min_through_hole_diameter"`,
   línea ~155) + DRC: las 6 violaciones `drill_out_of_range` del TP4056
   desaparecen. **ANTES de que el humano abra la GUI** (evita pisar el
   `.kicad_pro` con KiCad abierto).
2. **H5 (humano, mundo físico):** protocolo de medición del ignitor con
   multímetro (Fase A no destructiva + Fase B destructiva opcional) →
   reportar R_min/R_typ/R_max, R_wire y, si hace Fase B, I_fire medido.
3. **T7 (executor-4):** incorporar los números reales a `docs/design-notes.md`
   (§6 ignitor) y re-chequeo de margen: `I_worst = 3.3/(R_max + R_wire + 0.034)`
   debe ser ≥ 1.1A (condición del informe SPICE). Si falla → ESCALAR al
   planner inmediatamente (revive veredicto b/c de wave 2).
4. **H6 (humano, GUI):** placement por bloques lógicos + ruteo (guía paso a
   paso del planner al llegar aquí: plano GND, anchos de pista de potencia).
5. **T8 (executor-4):** `kicad-cli pcb drc` loop hasta 0 errores y 0
   unconnected.

### File ownership map

| File/glob | Owner |
|-----------|-------|
| `.kicad_pro` (SOLO la clave min_through_hole_diameter) | executor-4 (T6) |
| `ignition-system.kicad_pcb` | HUMANO (GUI) — placement y ruteo |
| `docs/design-notes.md` (§ ignitor, § estado PCB) | executor-4 (T7) |
| `ignition-system.kicad_sch` | congelado en wave 3, salvo decisión post-ignitor del planner |
| `sim/wave2/*`, `.workflow/*` | prohibidos para executor-4 |

> Nota (práctica observada en `a9de791`): si la GUI de KiCad reordena el
> `.kicad_pro` al guardar, commitearlo como `chore(kicad):` separado.

### Integration plan

Rama única de executor: `wave3-executor-4` (worktree análogo a la ola 2).
El humano commitea `.kicad_pcb` directamente en main. Secuencia: T6 →
H5+T7 → H6 (ruteo) → T8 → DRC final en main:

```bash
kicad-cli pcb drc --output /tmp/opencode/drc-final.rpt \
  hardware/Kicad/ignition-system/ignition-system.kicad_pcb   # "Errors 0"
```

En conflicto: STOP y reportar.

### Audit gate

- DRC en main: 0 errores, 0 unconnected (evidencia: drc-final.rpt).
- Las 6 drill_out_of_range ya no existen.
- design-notes tiene los datos REALES del ignitor y el chequeo de margen.
- Archivo de auditoría `.workflow/audits/wave3.md` (cierra la excepción 2
  de wave 2: cada ola termina con su audit).

## Wave 4 (future — not detailed yet)

Gerbers + BOM + PDF final — 100% headless con kicad-cli (agente) +
`skills/security-audit` (release gate) + docs de operación.

---

## Decision log

| Date | Decision | Why |
|------|----------|-----|
| 2026-08-14 | CE del TP4056 irá a VBUS, no al net "VCC" | ERC: `power_pin_not_driven`; el símbolo VCC no tiene fuente en el esquemático |
| 2026-08-14 | TEMP del TP4056 a GND en v1 | Sin NTC en el BOM; `ponytail:` — si se usa LiPo con NTC, añadir divisor en ola 3 |
| 2026-08-14 | Labels DIO1-DIO5 se eliminan | Cuelgan sin destino; si se necesitan en ola 2/3, se re-añaden con propósito |
| 2026-08-14 | `*.lck` a .gitignore | Archivos lock de KiCad abierto, ruido en git status |
| 2026-08-14 | Drill 0.2mm del TP4056 se corrige en ola 3 | Es problema del footprint/board setup, no del esquemático |
| 2026-08-14 | **Human-in-the-loop**: el humano edita en GUI, los agentes planifican/verifican/documentan/simulan | El ruteo y las ediciones visuales de KiCad no son automatizables de forma fiable por texto; 3 clics en GUI > cirugía de texto frágil (ponytail). Adaptación explícita de AGENTS.md a hardware |
| 2026-08-14 | **Wave 1 autorizada** por el humano — plan confirmado sin cambios; arranque inmediato | Las 3 decisiones (CE→VBUS, TEMP→GND, DIO fuera) fueron confirmadas |
| 2026-08-18 | **Wave 1 integrada** — ERC 0 (2 warnings de wire endpoint menores), PDF regenerado, docs/design-notes.md, README corregido (firmware indicado como planeado) | Commits 728ab0c, 1f5a174, e658fdf, 0875346 |
| 2026-08-18 | **Una placa, dos roles (RX/TX)** | El usuario confirma: un solo diseño con todas las secciones; al llegar de China una placa se arma como RX y otra como TX (diferente firmware/DNP según rol). Esto NO cambia el esquemático ni el ruteo: las secciones (radio, ignición, carga) ya existen en una placa |
| 2026-08-18 | **SPICE ANTES del ruteo** (ola 2 → ola 3) | Si el AOD4184A no conduce a 3.3V, cambia la zona de potencia y el ruteo entero; evitar re-spin |
| 2026-08-18 | `*.kicad_pro` prohibido en wave 1 | Los fixes de board setup (min hole) son de ola 3; mantener ola 1 mínima |
| 2026-09-01 | Designators renombrados con sufijo de chip: `LORA1-Sx1278`, `LORA2-Sx1278`, `Display1-SSD1306`, `RaspberryPi_Pico1-RP2040` (commit 40ce5ba) | Cierra 2 preguntas abiertas de design-notes §6: radio = LoRa SX1278, display = SSD1306. ERC re-verificado hoy: 0 errores / 2 warnings menores conocidos |
| 2026-09-01 | ngspice-45 + spice-find/spice-get instalados globalmente; ola 2 desbloqueada y lista para lanzar | Executor-3 usa el modelo local `Local Spice/AOD4184A.lib`; fallback: `spice-find aod4184a` + `spice-get aod4184a` (crea `localSpice.lib`) si el modelo local falla en ngspice |
| 2026-09-01 | **Wave 2 integrada** — merge `wave2-executor-3` (2c1a827) a main, sin conflictos. ERC integrado: 0 errores / 0 warnings (H4 humano cerró los 2 menores). Sim reproducida en ngspice-45: exit 0. Veredicto REPORT.md: (a) OK para rutear con AOD4184A, condición: medir ignitor real ≤1.1 A al recibirlo. Gate de la ola 3: VERDE | Merge 9c72979; commits a9de791 (kicad_pro humano) + 2c1a827 |
| 2026-09-01 | **Wave 2 in-flight**: worktree `../dst-ig-wave2-executor-3` creado, executor-3 lanzado por el humano | Plan de integración wave 2 sin cambios: merge `wave2-executor-3` → main al terminar |
| 2026-09-01 | **Auditoría wave 2: APPROVED WITH EXCEPTIONS** (`.workflow/audits/wave2.md`) — números del informe reproducidos por el auditor, ERC integrado 0/0, `.raw` byte-idénticos al re-corrida. Excepciones: (1) `a9de791` tocó `kicad_pro` fuera del map (side-effect GUI del humano, 1 línea, mitigado); (2) ola 1 sin archivo de auditoría formal — gates re-verificados aquí. Regla nueva: cada ola cierra con su audit file | Gate ola 3 VERDE con condición: medir ignitor real ≤1.1 A al recibirlo |
| 2026-09-01 | **Causa raíz de los 2 warnings ERC** (`unconnected_wire_endpoint`): 4 segmentos de cable sobrantes junto a CHRG1 (156.21, 171.45) y STDBY1 (156.21, 184.15) — restos de los labels DIO borrados en wave 1. Fix = tarea H4 (humano, GUI): borrar el wire horizontal desde el pin K (que ya tiene label VBUS encima) + el stub vertical de 2.54mm que cuelga hacia arriba, en cada LED | Los pines de los LEDs ya están conectados (K→VBUS por label, A→R8/R9); el alambrado sobrante sobra. Tras el fix: ERC objetivo 0 errores / 0 warnings |
