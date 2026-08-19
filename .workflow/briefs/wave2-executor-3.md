# Brief: Wave 2 · Executor 3

> Valida por SPICE si el AOD4184A conduce el ignitor con gate a 3.3V — ANTES
> de que el humano rutee. Tú no tocas archivos KiCad: creas un subcircuito de
> simulación aparte.

## Task

Simular el circuito de ignición con ngspice y entregar un informe con
veredicto. NO se simula la placa completa ni el RP2040: un GPIO digital es
una fuente pulsada 0→3.3V.

**Subcircuito a simular** (spoilers del esquemático):

```
V1 (fuente pulsada 0→3.3V, simula el GPIO15/IGNITION_GATE)
 ├─ R11 220Ω
 │    └─ nodo GATE ── R7 10kΩ ── GND
 │                   │
 │            AOD4184A (modelo: Local Spice/AOD4184A.lib)
 │             G=GATE  D=J1.2  S=GND
 │                            │
 VSYS (fuente DC 3.6V, LiPo nominal) ── J1 (ignitor, R=1.5Ω) ── D
```

**Casos de test** (todos con `.tran` y/o `.dc`):
1. Vgs=3.3V, ignitor 1.5Ω, VSYS=3.6V → ¿corriente de disparo? ¿Vds?
2. Vgs=3.3V, ignitor 2Ω y 1Ω (márgenes) → rango de corriente.
3. Barrido `.dc v1 0 3.3 0.1` → curva Id vs Vgs con carga fija.
4. Slew rate del gate con R11=220Ω + Cgs del modelo → tiempo hasta que la
   corriente alcanza el 90%.

**Entregables** (todos nuevos, en `sim/wave2/`):
- `ignition-sim.cir` — netlist ngspice completo con los 4 casos comentados.
- `run.sh` — corre ngspice y guarda salidas en `sim/wave2/out/`.
- `REPORT.md` — veredicto: ¿el AOD4184A conduce ≥ criterio (≥0.5A de margen
  sobre lo que pida el ignitor real)? Tabla con resultados por caso,
  potencia disipada en el MOSFET (P = Id²·Rds), y recomendación:
  (a) OK para rutear con este MOSFET; (b) añadir driver de gate;
  (c) cambiar a MOSFET con Vto<2V.

Si `kicad-cli sch export netlist --format spice` genera el netlist del
subcircuito completo, puedes usarlo como base, pero el .cir entregado debe
ser autocontenido y correr solo (no depende de abrir KiCad).

## Definition of done

- `sim/wave2/ignition-sim.cir`, `run.sh` y `REPORT.md` existen.
- `run.sh` corre `ngspice` sin errores y produce salidas en `sim/wave2/out/`.
- `REPORT.md` tiene veredicto CON números (Id, Vds, potencia) y uno de los 3
  veredictos (a/b/c) razonados.
- La verify command pasa.

## Files you own

- `sim/wave2/` (todo lo que crees ahí)

## Files forbidden

- `hardware/Kicad/ignition-system/*` (todo — salvo LEER
  `Local Spice/AOD4184A.lib` y el `.kicad_sch` para sacar valores)
- `docs/*`, `README.md`, `.gitignore`, `.workflow/*`, `.history/`
- `src/*`

## Read first

- `hardware/Kicad/ignition-system/Local Spice/AOD4184A.lib` — el modelo
  VDMOS (Kp, Vto=2.61, Rd, Rg, Cgs=1365p, tt=42n).
- `hardware/Kicad/ignition-system/ignition-system.kicad_sch` — valores de
  R7/R11 y la topología del disparo (≈líneas 8876-8940 para AOD4184A1,
  8307-8380 para R11, 9674-9750 para R7).
- `.workflow/plan.md` — Wave 2 y decision log.

## Verify command

```bash
# 1. El netlist corre en ngspice:
bash sim/wave2/run.sh && ls sim/wave2/out/ | grep -q '\.raw\|\.log' 
# 2. El informe tiene veredicto y números:
grep -qiE 'veredicto|recomendaci|conduce|0\.[0-9]+ ?A' sim/wave2/REPORT.md
```

Instala ngspice si falta: `nix profile install nixpkgs#ngspice` (o el
equivalente en tu distro). Si no hay forma de instalarlo, reporta el bloqueo
en vez de inventarte resultados.

## Commit

- Conventional commits, una línea, imperativo. Ejemplos:
  `feat: add spice ignition simulation`,
  `docs: add spice verification report`.
- BRANCH ISOLATION: commit AND push ONLY a `wave2-executor-3`.
- Nunca `cd` fuera de tu worktree ni `git checkout|switch|branch|worktree|stash`.

## Report back

- Veredicto (a/b/c) y los números clave.
- Dificultades con el modelo AOD4184A (VDMOS de Bordodynov) o con ngspice.
- Recomendación concreta para el humano (qué cambiaría si el veredicto no es OK).