# Brief: Wave 1 · Humano (GUI de KiCad)

> Este brief lo ejecuta el HUMANO en la GUI de KiCad — no un agente.
> Son ~5 minutos de clics. Los agentes verifican después con kicad-cli.
> Si una instrucción no encaja con lo que ves, PARA y reporta al planner.

## Task

Abrir `hardware/Kicad/ignition-system/ignition-system.kicad_sch` en KiCad y
hacer 3 correcciones para dejar el ERC en 0 errores. NO hagas nada más.

### Fix 1 — CE del TP4056: de "VCC" a "VBUS"

El pin 8 (CE) de `ModuloDeCarga1` (el TP4056) está conectado a un símbolo de
potencia rotulado **"VCC"** que no tiene ninguna fuente (ERC:
`power_pin_not_driven`). El CE es enable activo alto: debe ir al 5V del bus
USB.

**Cómo hacerlo (elegí la opción que te resulte más natural):**
- **Opción A (recomendada):** clic derecho sobre el símbolo de potencia
  "VCC" que cuelga del pin CE → *Properties* → cambia el campo *Value* de
  `VCC` a `VBUS` → OK. (El símbolo de potencia es una etiqueta: renombrar
  el Value re-etiqueta el net. VBUS ya existe y está alimentado por el
  Pico pin 40 y C2.)
- **Opción B:** borra el símbolo VCC y coloca un nuevo símbolo de potencia
  `VBUS` (tecla `P` → busca "VBUS" → colócalo sobre el pin CE).

**Verificación visual:** el net del pin 8 ahora debe decir `VBUS`, y debe
haber al menos otro componente en ese net (el Pico pin 40 y C2).

### Fix 2 — TEMP del TP4056: a GND

El pin 1 (TEMP) de `ModuloDeCarga1` está sin conectar (ERC:
`pin_not_connected` + `pin_not_driven`). En v1 no hay NTC en el BOM, así que
lo llevamos a GND (desactiva el monitoreo de temperatura; la celda carga a
1A fijo — decisión ya tomada en el plan, con `ponytail:` comentario: si
algún día usas LiPo con NTC, añade divisor TEMP en ola 3).

**Cómo hacerlo:** coloca un símbolo de potencia `GND` (tecla `P` → busca
"GND") tocando el extremo del pin 1 de ModuloDeCarga1. Si el pin no termina
en un punto fácil, traza un pequeño wire desde el pin hasta el símbolo GND.

### Fix 3 — Borrar labels DIO1-DIO5

Hay 5 global labels colgando sin conexión (ERC: `label_dangling`). No tienen
destino. Bórralos (clic en cada label → `Supr`):

| Label | Coordenadas (mm) |
|-------|------------------|
| DIO1 | (207.01, 76.20) |
| DIO2 | (207.01, 78.74) |
| DIO3 | (207.01, 81.28) |
| DIO4 | (242.57, 78.74) |
| DIO5 | (242.57, 76.20) |

## Definition of done

- El símbolo de potencia del pin CE (pin 8 del TP4056) dice `VBUS`.
- El pin TEMP (pin 1 del TP4056) tiene un GND tocando su extremo.
- Los 5 labels DIO1-DIO5 ya no existen en la hoja.
- Guardas el esquemático (Ctrl+S) y KiCad no reporta errores al guardar.
- **NO** has tocado nada más (ni el PCB, ni footprints, ni valores, ni el
  DRC del PCB).

## Files you own

- `hardware/Kicad/ignition-system/ignition-system.kicad_sch`
  (lo edita la GUI de KiCad; tú solo guardas).

## Files forbidden

- `hardware/Kicad/ignition-system/ignition-system.kicad_pcb` y `*.kicad_pro`
- `hardware/Kicad/ignition-system/DRC.rpt` y `Local Spice/*`
- `docs/*`, `README.md`, `.gitignore`, `.workflow/*`, `AGENTS.md`

## Read first

- `.workflow/plan.md` → Decision log: las 3 decisiones ya están tomadas
  (CE→VBUS, TEMP→GND, DIO eliminados). No las re-discutas.

## Verify command

NO ejecutes comandos: el executor-1 correrá la verificación headless después
de que tú guardes y commitees. Para tu tranquilidad, si quieres autocomprobar
antes de commitear, corre en una terminal:

```bash
kicad-cli sch erc --output /tmp/opencode/erc-human.rpt \
  hardware/Kicad/ignition-system/ignition-system.kicad_sch
grep -E "Errors [0-9]+" /tmp/opencode/erc-human.rpt   # esperado: Errors 0
```

## Commit

- Conventional commit, una línea, imperativo. Ejemplo:
  `fix: point tp4056 ce to vbus and tie temp to gnd`
  (o `fix: remove dangling dio labels` si haces commits separados — 1 por
  cambio lógico está bien, pero uno solo también vale).
- Commit AND push a tu rama `wave1-human` (o a `main` si el integrador lo
  acordó así). Nunca forces push, nunca toques ramas de otros.

## Report back

- Qué opción usaste en el Fix 1 (A o B) y cualquier cosa rara que vieras.
- Si el ERC no dio 0 tras tus cambios, el texto exacto de los errores que
  queden.
