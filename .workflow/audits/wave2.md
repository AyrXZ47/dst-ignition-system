# Audit — Wave 2 (Validación SPICE del disparo)

**Fecha:** 2026-09-01 · **Auditor:** sesión fresca, árbol integrado en `main` @ `46f3a95`
**Alcance:** ola 2 (`wave2-executor-3` + fix humano H4) según `.workflow/plan.md`

## Veredicto: APPROVED WITH EXCEPTIONS

La ola cumple su gate: el informe SPICE existe, corre en ngspice-45 y es
reproducible; el veredicto (a) "OK para rutear con AOD4184A" está soportado
por números que reproduje yo mismo. Dos excepciones menores listadas abajo,
ambas de bajo riesgo y ya mitigadas. La ola 3 (ruteo) puede arrancar, con la
condición del informe: **medir el ignitor real al recibirlo (≤1.1 A)**.

## 1. Integridad de integración

- [x] Worktrees fusionados: `wave2-executor-3` (tip `2c1a827`) fusionada en
      `main` vía `9c72979`. `git log --graph` lo confirma; `git branch -a`
      no muestra ramas sin fusionar.
- [x] `git status` limpio; `git stash list` vacío.
- [x] Diff vs plan (ownership map):
  - `2c1a827` (executor-3): solo `sim/wave2/*` (9 archivos, +8180) ✓
  - `d453565` (H4 humano): solo `ignition-system.kicad_sch` ✓
  - `a9de791` (humano): `ignition-system.kicad_pro` — **EXCEPCIÓN 1** (ver abajo)
  - `46f3a95`, `f86ebb4`, `ce80c91`: solo `.workflow/plan.md` ✓

## 2. Build & tests (evidencia)

- [x] **ERC en árbol integrado** (H4 + renombres de designators verificados):
  ```
  kicad-cli sch erc --output /tmp/opencode/erc-wave2-audit.rpt hardware/Kicad/ignition-system/ignition-system.kicad_sch
  → exit 0 · **ERC messages: 0  Errors 0  Warnings 0**
  ```
- [x] **Verify #1 del brief:** `bash sim/wave2/run.sh` → exit 0, `CASE4`
  alcanzado, salidas regeneradas en `sim/wave2/out/`. Re-corrida deja
  `git status` limpio: los `.raw` comprometidos **reproducen byte-idéntico**.
- [x] **Verify #2 del brief:** `grep -qiE 'veredicto|recomendaci|conduce|0\.[0-9]+ ?A' REPORT.md` → PASS.
- [x] **Cross-check auditor vs REPORT.md** (re-simulé yo mismo, ngspice-45):

  | Caso | REPORT | Medido por auditor |
  |------|--------|--------------------|
  | 1 (1.5Ω/3.6V) | 2.347 A · Vds 79.5 mV | `id_final=2.346969`, `vds_final=7.9547e-2` ✓ |
  | 2a (2Ω/3.6V) | 1.770 A · 59.5 mV | `1.770268` · `5.9464e-2` ✓ |
  | 2b (1Ω/3.6V) | 3.480 A · 120.2 mV | `3.479834` · `1.2017e-1` ✓ |
  | 2c (2Ω/3.3V peor) | 1.623 A · 54.4 mV | `1.622806` · `5.4389e-2` ✓ |
  | 3 (Id=1A) | VGPIO≈2.80V, gate≈2.74V | `vgs_at_1a=2.7975` → gate 2.737 ✓ |
  | 4 (slew) | t90=2.78 µs | `t90_id=102.7792µs` − 100µs = 2.78µs ✓ |

- [x] Aritmética del informe verificada: Rds_eff = 79.5mV/2.347A = 33.9 mΩ ✓;
      P = Id²·Rds = 0.187 W (informe: 0.19 W) ✓.
- [x] Modelo inline en `ignition-sim.cir` **idéntico** a
      `Local Spice/AOD4184A.lib` (diff de parámetros: ninguno).
- [x] Topología simulada = esquemático real: netlist de KiCad confirma
      `R11 IGNITION_GATE <gate> 220`, `R7 <gate> GND 10k`, AOD4184A1 presente,
      `.include` apunta al `.lib` local.

## 3. Disciplina ponytail

- [x] Sin dependencias nuevas: ngspice ya instalado (gate de la ola), bash.
- [x] `run.sh` = 18 líneas; `.cir` autocontenido (modelo inline, no includes
      externos); 4 casos con `alterparam`+`reset`, sin duplicar netlists.
- [x] `run.sh` deja un check ejecutable mínimo (`grep -q CASE4`) — cumple la
      regla de "un check que falla si la lógica se rompe".
- [ ] OBSERVACIÓN: los `.raw` de `out/` (~8k líneas) son artefactos
      regenerables comprometidos en git. Defendible como evidencia adjunta
      del audit gate ("salida transitoria/dc adjunta"), pero si vuelve a
      doler en diffs, `sim/wave2/out/` a `.gitignore` y el gate se demuestra
      con un run. No bloquea.
- Trivial: typo "tedea" en REPORT.md:99 (por "tee-a"). No bloquea.

## 4. Seguridad

- [x] Scan de secretos (`git grep -iE '(api[_-]?key|secret|token|password|...)'`):
      solo matches en docs de `skills/` y `.gitignore` — **sin secretos reales**.
- [x] `.gitignore` cubre `*.log`, `*.secret`, `secrets/`, `.history/`.
- [x] `run.sh` sin `eval`, sin entradas de confianza; no hay trust boundaries
      nuevas en esta ola.
- N/A Release gate `skills/security-audit`: corresponde a la ola 4 (plan),
  no a esta ola.

## 5. Excepciones

1. **`a9de791` toca `ignition-system.kicad_pro` fuera del ownership map de la
   ola 2** (el mapa solo concedía el `.kicad_sch` para H4; el `.kicad_pro` es
   material de la ola 3). Riesgo ~cero: 1 línea mecánica (`used_designators`
   reordenado, side-effect de guardar la GUI de KiCad), commit del humano.
   Owner: humano. Mitigado: el cambio no afecta diseño ni DRC futuro. Regla
   para ola 3: si la GUI reordena el `.kicad_pro` al guardar, commitearlo
   como `chore(kicad):` separado y documentarlo — ya es la práctica observada.
2. **La ola 1 nunca tuvo archivo de auditoría** en `.workflow/audits/` (la
   carpeta no existía; quedó "integrated" sin registro formal). Mitigado en
   esta auditoría re-verification: ERC 0/0 hoy, sin net huérfano `VCC`
   (`grep -i vcc` en netlist → sin matches), PDF regenerado existe
   (`0b2d5ee`), `docs/design-notes.md` presente. Owner: planner — para la
   ola 3+, cerrar cada ola con su archivo de auditoría.

## Conclusión y ruta a la ola 3

El gate de la ola 2 queda **VERDE con la condición ya documentada en el
informe**: al recibir el ignitor/e-match real, medir su corriente; si >1.1 A,
escalar a (b) driver de gate o (c) MOSFET con Vto<2V antes de rutear la zona
de potencia. La ola 3 (ruteo en GUI + `kicad-cli pcb drc`) puede planificarse.
