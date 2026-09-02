# Brief: Wave 3 · Executor 4

> Preparas el PCB para que el humano rutee: corriges board setup, incorporas
> los datos reales del ignitor cuando el humano los mida, y verificas DRC
> hasta 0. El ruteo en sí NO es tuyo: lo hace el humano en la GUI.

## Task

Tres tareas SECUENCIALES (una commit por tarea):

- **T6 (hazla primero, ANTES de que el humano abra KiCad):** en
  `hardware/Kicad/ignition-system/ignition-system.kicad_pro`, cambia la clave
  `"min_through_hole_diameter"` de `"0.3"` a `"0.2"` (bloque
  `design_settings.rules`, ~línea 155). NO toques ninguna otra clave. Luego
  corre DRC y verifica que las 6 violaciones `drill_out_of_range` del TP4056
  desaparecen (el resto de violaciones silk/unconnected siguen, es un board
  sin rutear — normal).
- **T7 (cuando el humano te pase los datos del ignitor):** actualiza
  `docs/design-notes.md` §6 (pendiente "Ignitor/e-match") y §4 (BOM) con los
  números reales: R_min/R_typ/R_max (medidos), R_wire del cableado, y si el
  humano hizo la prueba destructiva, I_fire medido. Haz el chequeo de margen:
  `I_worst = 3.3 / (R_max + R_wire + 0.034)`. Debe ser ≥ 1.1 A (condición de
  `sim/wave2/REPORT.md`). **Si da < 1.1 A: PARA y reporta al planner — no
  decidas tú cambiar MOSFET ni driver.** Si da OK, anota el resultado con la
  fórmula y los números en design-notes.
- **T8 (cuando el humano termine el ruteo):** corre `kicad-cli pcb drc`,
  reporta el resultado al planner. Si hay errores: reporta el .rpt COMPLETO
  (tú no ruteas, no edites el .kicad_pcb). Itera solo cuando el humano diga
  que ya arregló algo.

## Definition of done

- T6: la clave cambiada, DRC sin `drill_out_of_range`, y la verify command pasa.
- T7: design-notes tiene los valores reales y el chequeo de margen con fórmula
  y números; o el bloqueo reportado al planner.
- T8: el DRC final del árbol integrado da 0 errores / 0 unconnected (o el
  reporte de lo que falte, sin editarlo tú).
- La verify command de la tarea activa pasa antes de cada commit.

## Files you own

- `hardware/Kicad/ignition-system/ignition-system.kicad_pro` (SOLO T6, SOLO
  la clave min_through_hole_diameter)
- `docs/design-notes.md` (SOLO §4 BOM y §6 ignitor/estado PCB)

## Files forbidden

- `hardware/Kicad/ignition-system/ignition-system.kicad_sch` (congelado en
  wave 3; si crees que necesita un cambio, reporta al planner)
- `hardware/Kicad/ignition-system/ignition-system.kicad_pcb` (del humano en
  GUI; tú solo lo LEES con kicad-cli)
- `sim/wave2/*`, `.workflow/*`, `README.md`, `src/*`

## Read first

- `.workflow/plan.md` — sección Wave 3 (orden estricto) + decision log.
- `sim/wave2/REPORT.md` — la condición "ignitor ≤ 1.1 A" y el Rds_eff≈34mΩ
  que usa el chequeo de margen.
- `docs/design-notes.md` — §5 estado del PCB (las 6 drill_out_of_range) y
  §6 (pendiente ignitor) — es lo que T6/T7 cierran.
- `.workflow/audits/wave2.md` — excepción 1: si la GUI reordena el
  `.kicad_pro`, eso se commitea como `chore(kicad):` separado.

## Verify command

```bash
# T6 — la corrección de reglas es real:
kicad-cli pcb drc --output /tmp/opencode/drc-t6.rpt \
  hardware/Kicad/ignition-system/ignition-system.kicad_pcb \
  && ! grep -q drill_out_of_range /tmp/opencode/drc-t6.rpt \
  && grep -q '"min_through_hole_diameter": "0.2"' \
     hardware/Kicad/ignition-system/ignition-system.kicad_pro

# T7 — los datos reales y el chequeo están en design-notes:
grep -qiE 'R_max|R_máx|ignitor.*(medid|Ω|ohm)' docs/design-notes.md

# T8 — DRC final limpio:
kicad-cli pcb drc --output /tmp/opencode/drc-final.rpt \
  hardware/Kicad/ignition-system/ignition-system.kicad_pcb \
  && ! grep -qE '\bErrors? [1-9]' /tmp/opencode/drc-final.rpt
```

La ruta del repo tiene ESPACIOS: cita siempre las rutas entre comillas.

## Commit

- MANDATORY: conventional commits, resumen corto, imperativo, una línea.
  Ejemplos: `build: bajar min hole a 0.2mm`, `docs: anotar medidas reales
  del ignitor`. Under ~72 chars. No AI attribution, no trailers.
- One logical change per commit. One commit per task (T6, T7, T8 son commits
  separados).
- Commit ONLY tus archivos.
- BRANCH ISOLATION (mandatory): commit y push SOLO a tu rama de worktree
  `wave3-executor-4` — `git push origin wave3-executor-4` tras cada commit.
  Nunca a `main` ni a otra rama; nunca merge/rebase/fast-forward de ramas
  ajenas.
- No hagas `cd` fuera de tu worktree ni `git checkout|switch|branch|worktree|stash`.

## Report back

- T6: salida del DRC (número de violaciones antes/después).
- T7: los números del ignitor y el resultado del chequeo de margen (o el
  bloqueo si < 1.1A).
- T8: el DRC final con conteo exacto de errores/warnings/unconnected, y el
  listado de violaciones si las hay.
- Cualquier desviación del ownership map: reportada, nunca "arreglada".
