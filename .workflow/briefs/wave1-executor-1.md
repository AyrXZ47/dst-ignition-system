# Brief: Wave 1 · Executor 1

> El humano hace los fixes del esquemático en GUI (`wave1-human-schematic.md`).
> TÚ no editas KiCad: verificas el resultado con kicad-cli y regeneras el PDF.

## Task

1. **Verificar el esquemático tras el fix del humano** (headless, sin abrir
   GUI): el ERC debe reportar 0 errores y el netlist debe reflejar los 3
   cambios acordados.
2. **Regenerar `docs/ignition-system.pdf`** — el PDF actual data del commit
   `0df3d5b` (2026-08-08) y está desactualizado respecto al esquemático
   corregido. Usa `kicad-cli sch export pdf`.

Si la verificación falla: NO arregles el `.kicad_sch` por texto tú mismo
(territorio del humano en GUI). Reporta el fallo con la salida exacta del
ERC y para.

## Definition of done

- ERC: 0 errores (warnings documentados si quedan).
- Netlist: `ModuloDeCarga1.8` (CE) está en el net `VBUS`; `ModuloDeCarga1.1`
  (TEMP) está en el net `GND`; no existe net "VCC" huérfano.
- `docs/ignition-system.pdf` regenerado y más nuevo que el commit `0df3d5b`.
- La verify command pasa.

## Files you own

- `docs/ignition-system.pdf` (regenerado)

## Files forbidden

- `hardware/Kicad/ignition-system/ignition-system.kicad_sch` (si lo editas,
  corres el riesgo de pisar al humano; si el ERC falla, reporta, no arregles)
- `hardware/Kicad/ignition-system/ignition-system.kicad_pcb`
- `hardware/Kicad/ignition-system/ignition-system.kicad_pro`
- `hardware/Kicad/ignition-system/DRC.rpt`, `Local Spice/*`, `.history/`, `*.lck`
- `docs/design-notes.md`, `README.md`, `.gitignore`, `.workflow/*` (salvo leer)

## Read first

- `.workflow/plan.md` → Decision log y plan de integración.
- `.workflow/briefs/wave1-human-schematic.md` → qué se supone que cambió.

## Verify command

```bash
# 1. ERC 0 errores:
kicad-cli sch erc --output /tmp/opencode/erc-e1.rpt \
  hardware/Kicad/ignition-system/ignition-system.kicad_sch
grep -E "Errors [0-9]+" /tmp/opencode/erc-e1.rpt       # esperado: Errors 0

# 2. Netlist: VBUS incluye ModuloDeCarga1.8, GND incluye ModuloDeCarga1.1,
#    y el net VCC huérfano no existe:
kicad-cli sch export netlist --format kicadsexpr --output /tmp/opencode/net-e1.net \
  hardware/Kicad/ignition-system/ignition-system.kicad_sch
node -e '
const fs=require("fs");const t=fs.readFileSync("/tmp/opencode/net-e1.net","utf8");
const b=t.split("\t(nets\n")[1].split("\n\t)\n)")[0];
for(const bl of b.split("\t\t(net\n")){
  const n=bl.match(/\(name "([^"]*)"\)/);if(!n)continue;
  const c=[...bl.matchAll(/\(ref "([^"]+)"\)\n\t\t\t\t\(pin "(\d+)"\)/g)];
  console.log(n[1].padEnd(30), c.map(x=>x[1]+"."+x[2]).join(","));
}'
# Esperado: VBUS incluye ModuloDeCarga1.8; GND incluye ModuloDeCarga1.1;
#           sin línea "VCC".

# 3. PDF regenerado (más nuevo que el del 8-ago):
kicad-cli sch export pdf --output docs/ignition-system.pdf \
  hardware/Kicad/ignition-system/ignition-system.kicad_sch
ls -la docs/ignition-system.pdf
```

Ejecuta 1 y 2 ANTES de tocar nada. Si pasan, ejecuta 3 y commitea el PDF.
Si fallan, reporta sin commitear nada.

## Commit

- Conventional commit: `docs: regenerate schematic pdf after erc fixes`
  (una línea, imperativo, <72 chars). Commit ONLY tu archivo.
- BRANCH ISOLATION: commit AND push ONLY a `wave1-executor-1`.
- Nunca `cd` fuera de tu worktree ni `git checkout|switch|branch|worktree|stash`.

## Report back

- Salida de los 3 checks (o el fallo exacto).
- Warnings del ERC que quedaron (si alguno).
