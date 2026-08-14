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
- Simulación: ngspice (a instalar en ola 2) o simulador de KiCad GUI.
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
| 1 | Esquemático limpio: ERC 0, fixes TP4056 (CE→VBUS, TEMP), labels DIO, artefactos docs | [x] in-flight (humano autorizado 2026-08-14) |
| 2 | Validación de potencia por SPICE (gate 3.3V vs Vto 2.61V, disparo del ignitor) | [ ] planned |
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

## Wave 2 (future — not detailed yet)

Validar el disparo: modelo SPICE AOD4184A + ignitor (~1-2Ω) en ngspice.
El agente prepara el netlist SPICE (kicad-cli export spice) y los casos de
test; el humano corre ngspice o el simulador de KiCad GUI. Entregable:
decisión documentada — ¿gate a 3.3V basta (Vgs-Vto=0.7V) o hace falta
driver/MOSFET con Vto menor? También: slew rate con R11=220Ω, picos en el
pull-down R7.

## Wave 3 (future — not detailed yet)

PCB — **HUMANO en GUI** (ruteo no es automatizable de forma fiable). El
agente prepara: ajuste de min hole del board setup (0.3→0.2mm o cambio de
footprint del TP4056 — se puede editar en `*.kicad_pro`, texto JSON),
planos GND/VBUS sugeridos, y verifica con `kicad-cli pcb drc` hasta 0.
Ruteo: el humano con router interactivo (o freerouting, bajo supervisión).

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
| 2026-08-14 | `*.kicad_pro` prohibido en wave 1 | Los fixes de board setup (min hole) son de ola 3; mantener ola 1 mínima |
