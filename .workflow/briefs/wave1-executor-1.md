# Brief: Wave 1 · Executor 1

> Copy this template per executor. The planner fills every section. The
> executor never touches a file it doesn't own, even "obviously". Deviations
> go back to the planner via the decision log in `.workflow/plan.md`.

## Task

Corregir el esquemático `hardware/Kicad/ignition-system/ignition-system.kicad_sch`
(archivo texto S-expression, NO binario — edítalo con las herramientas de
edición de texto normales, igual que cualquier otro archivo). Objetivo: ERC
con 0 errores. Tres fixes concretos:

1. **CE del TP4056 (pin 8 de `ModuloDeCarga1`) → net VBUS.** Hoy cuelga del
   símbolo `#PWR07` con valor "VCC", un net sin ninguna fuente
   (ERC `power_pin_not_driven`). El CE es enable activo alto: debe ir al 5V
   del bus USB. Solución mínima: renombrar el símbolo de potencia `#PWR07`
   de "VCC" a "VBUS" (el net VBUS ya existe y está alimentado por
   `RaspberryPi_Pico1` pin 40 y `C2`). No muevas wires ni símbolos; solo
   cambia el nombre del net de ese símbolo.
2. **TEMP del TP4056 (pin 1 de `ModuloDeCarga1`) → GND.** Hoy sin conectar
   (ERC `pin_not_connected` + `pin_not_driven`). Solución mínima: conectar
   ese pin al net GND (añade un símbolo de potencia GND, o renombra/une la
   conexión al GND existente más cercano en el esquemático). Comenta la
   decisión con `ponytail:` — sin NTC en el BOM, TEMP a GND desactiva el
   monitoreo de temperatura; la celda se carga a 1A fijo. Techo conocido:
   una LiPo sin protección y con NTC requeriría divisor TEMP en ola 3.
3. **Eliminar los 5 global labels colgantes `DIO1`, `DIO2`, `DIO3`, `DIO4`,
   `DIO5`** (ERC `label_dangling`). No tienen destino; borra los símbolos
   de label. Si vieras que alguno SÍ debería conectar (p.ej. al conector
   LORA), páralo y repórtalo al planner en vez de decidir tú.

NO corrijas nada más. Si encuentras otro error, repórtalo en "Report back"
sin tocarlo. La regla ponytail: el diff más pequeño que hace pasar el ERC.

## Definition of done

- ERC con 0 errores (warnings pueden quedar, documentados).
- El netlist exportado muestra `ModuloDeCarga1.8` en el net `VBUS` y
  `ModuloDeCarga1.1` en el net `GND`; no existe el net "VCC" huérfano.
- Los labels DIO1-DIO5 ya no existen en el archivo.
- El resto del esquemático quedó intacto (mismo número de componentes,
  mismo netlist salvo los 3 cambios).
- La verify command de abajo pasa.

## Files you own

- `hardware/Kicad/ignition-system/ignition-system.kicad_sch`

## Files forbidden

- `hardware/Kicad/ignition-system/ignition-system.kicad_pcb`
- `hardware/Kicad/ignition-system/ignition-system.kicad_pro`
- `hardware/Kicad/ignition-system/DRC.rpt`
- `hardware/Kicad/ignition-system/Local Spice/*`
- `hardware/Kicad/ignition-system/.history/`
- `hardware/Kicad/ignition-system/*.lck`
- `docs/*`, `README.md`, `.gitignore`, `AGENTS.md`, `.workflow/*`

## Read first

- `hardware/Kicad/ignition-system/ignition-system.kicad_sch` — la sección
  `(symbol (lib_id "power:VCC")` del `#PWR07` (≈línea 6300) y el bloque de
  `ModuloDeCarga1` (≈línea 9480). Las conexiones se hacen por UUID de pin,
  no por wires con nombre.
- `.workflow/plan.md` — decision log: CE→VBUS y TEMP→GND ya están decididos.
- DRC/ERC actuales: `hardware/Kicad/ignition-system/DRC.rpt` (del PCB, no lo
  toques, solo contexto).

## Verify command

```bash
# 1. ERC debe reportar 0 errores:
kicad-cli sch erc --output /tmp/opencode/erc-e1.rpt \
  hardware/Kicad/ignition-system/ignition-system.kicad_sch
grep -E "Errors [0-9]+" /tmp/opencode/erc-e1.rpt    # esperado: Errors 0

# 2. Netlist: VBUS lleva ModuloDeCarga1.8, GND lleva ModuloDeCarga1.1,
#    y no existe net VCC:
kicad-cli sch export netlist --format kicadsexpr --output /tmp/opencode/net-e1.net \
  hardware/Kicad/ignition-system/ignition-system.kicad_sch
grep -c 'VCC' /tmp/opencode/net-e1.net               # esperado: 0
grep -A6 'name "VBUS"' /tmp/opencode/net-e1.net      # debe incluir ModuloDeCarga1 pin 8
```

Ejecuta ambas antes de commitear. Si el ERC no da 0, sigue corrigiendo SOLO
los 3 puntos del task hasta que pase.

## Commit

- MANDATORY: conventional commits, short summary, imperative, one line
  (`fix:`). Ejemplo: `fix: point tp4056 ce to vbus and tie temp to gnd`.
  Bajo ~72 chars. Sin atribución IA, sin trailers.
- Un solo commit para la tarea (los 3 fixes van juntos: mismo archivo).
- Commit ONLY your owned files.
- BRANCH ISOLATION (mandatory): commit AND push ONLY to `wave1-executor-1` —
  `git push origin wave1-executor-1`. Never push to `main` or another
  branch; never merge, rebase, or fast-forward anyone else's branch.
- Nunca salgas de tu worktree (`cd`) ni ejecutes `git checkout`, `git
  switch`, `git branch`, `git worktree`, `git stash`.

## Report back

- Archivos cambiados y diff resumido.
- Salida de la verify command (ERC 0 + evidencia de VBUS/GND + sin VCC).
- Cualquier hallazgo extra del esquemático (sin tocarlo) y preguntas
  abiertas.
