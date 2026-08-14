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
  sch export pdf, pcb drc).
- Modelo SPICE local: `hardware/Kicad/ignition-system/Local Spice/AOD4184A.lib`
  (VDMOS, Vto=2.61V, Ron=5.8mΩ).
- Simulación: ngspice (a instalar en ola 2) o simulador de KiCad GUI.
- Ignitor/e-match estándar (~1-2Ω, ~1A) — pendiente confirmar con el humano.
- Licencias: hardware CERN-OHL-P-2.0, software Apache-2.0.
- Regla ponytail: mínimo cambio que funciona; no añadir drivers/partes hasta
  que la simulación demuestre que hacen falta.

## Waves

| Wave | Focus | Status |
|------|-------|--------|
| 1 | Esquemático limpio: ERC 0, fixes TP4056 (CE→VBUS, TEMP), labels DIO, artefactos docs | [x] planned |
| 2 | Validación de potencia por SPICE (gate 3.3V vs Vto 2.61V, disparo del ignitor) | [ ] planned |
| 3 | PCB: reglas, planos de cobre, ruteo, DRC 0 | [ ] planned |
| 4 | Release: Gerbers, BOM, PDF final, security-audit | [ ] planned |

> Status legend: planned → in-flight → integrated → audited → done.
> Update after each step, by whoever ran the step.

---

## Wave 1 (current)

### File ownership map

| File/glob | Owner |
|-----------|-------|
| `hardware/Kicad/ignition-system/ignition-system.kicad_sch` | executor-1 |
| `docs/design-notes.md` (nuevo), `README.md`, `.gitignore` | executor-2 |
| `hardware/Kicad/ignition-system/ignition-system.kicad_pcb` | prohibido (ola 3) |
| `hardware/Kicad/ignition-system/Local Spice/*`, `.history/`, `DRC.rpt`, `*.lck` | prohibido |

El PDF `docs/ignition-system.pdf` lo regenera el INTEGRADOR (no un executor)
después del merge, porque depende del `.kicad_sch` ya corregido.

### Tasks

- [ ] T1: Corregir el esquemático: CE del TP4056 a VBUS (el net "VCC" no tiene
      fuente), TEMP a GND (v1 sin NTC, nota `ponytail:`), eliminar labels
      DIO1-DIO5 colgantes → brief: `.workflow/briefs/wave1-executor-1.md`
- [ ] T2: Documentar el diseño (topología, mapa de pines RP2040, decisiones,
      BOM preliminar), ignorar `*.lck`, actualizar README →
      brief: `.workflow/briefs/wave1-executor-2.md`

### Integration plan

Orden: **executor-2 primero** (docs, sin dependencias del sch), **executor-1
después** (único que toca el sch). Luego el integrador regenera artefactos:

```bash
# 1. merge wave1-executor-2 -> main
# 2. merge wave1-executor-1 -> main
# 3. regenerar PDF del esquemático corregido (sustituye al desactualizado):
kicad-cli sch export pdf --output docs/ignition-system.pdf \
  hardware/Kicad/ignition-system/ignition-system.kicad_sch
# 4. verificación final en el árbol integrado:
kicad-cli sch erc --output /tmp/opencode/erc-final.rpt \
  hardware/Kicad/ignition-system/ignition-system.kicad_sch   # debe decir "Errors 0"
```

En conflicto (improbable: territorios disjuntos): STOP y reportar.

### Audit gate

Correr `.workflow/audit-checklist.md` en el árbol integrado. Específico:

- Solo se modificaron archivos del ownership map (ver `git log --stat` por rama).
- ERC en el árbol integrado: 0 errores (evidencia: `/tmp/opencode/erc-final.rpt`).
- Netlist integrado: net `VBUS` incluye `ModuloDeCarga1.8`; el net `VCC` huérfano
  ya no existe.
- `docs/design-notes.md` existe y cubre: topología, mapa de pines, decisiones.
- El PDF regenerado es más reciente que el commit `0df3d5b` que lo creó.

---

## Wave 2 (future — not detailed yet)

Validar el disparo: modelo SPICE AOD4184A + ignitor (~1-2Ω) en ngspice.
Entregable: decisión documentada — ¿gate a 3.3V basta (Vgs-Vto=0.7V) o hace
falta driver/MOSFET con Vto menor? También: slew rate con R11=220Ω, picos en
el pull-down R7.

## Wave 3 (future — not detailed yet)

PCB: ajustar min hole del board setup (0.3→0.2mm o cambiar footprint del
TP4056), planos GND/VBUS, ruteo (freerouting o humano en GUI), DRC 0.

## Wave 4 (future — not detailed yet)

Gerbers + BOM + PDF final + `skills/security-audit` (release gate, es
distribuible) + docs de operación (armado, carga, ignición).

---

## Decision log

| Date | Decision | Why |
|------|----------|-----|
| 2026-08-14 | CE del TP4056 irá a VBUS, no al net "VCC" | ERC: `power_pin_not_driven`; el símbolo VCC no tiene fuente en el esquemático |
| 2026-08-14 | TEMP del TP4056 a GND en v1 | Sin NTC en el BOM; `ponytail:` — si se usa LiPo con NTC, añadir divisor en ola 3 |
| 2026-08-14 | Labels DIO1-DIO5 se eliminan | Cuelgan sin destino; si se necesitan en ola 2/3, se re-añaden con propósito |
| 2026-08-14 | `*.lck` a .gitignore | Archivos lock de KiCad abierto, ruido en git status |
| 2026-08-14 | Drill 0.2mm del TP4056 se corrige en ola 3 | Es problema del footprint/board setup, no del esquemático |
