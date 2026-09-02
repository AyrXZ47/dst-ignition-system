# REPORT — Validación SPICE del disparo del ignitor (Wave 2 · Executor 3)

**Fecha:** 2026-09-01 · **Simulador:** ngspice-45 (`/run/current-system/sw/bin/ngspice`)
**Netlist:** `sim/wave2/ignition-sim.cir` (autocontenido, modelo VDMOS inline)
**Reproducir:** `bash sim/wave2/run.sh` → salidas en `sim/wave2/out/` (log + `.raw` por caso)

## Veredicto: **(a) OK para rutear con el AOD4184A**

El AOD4184A conduce el ignitor con holgura a Vgs≈3.3V en todos los casos
simulados, incluido el peor caso (LiPo descargada 3.3V + ignitor 2Ω):

| Caso | Ignitor | VSYS | Id disparo | Vds | Rds(on) eff. | P MOSFET | Criterio ≥1.5A |
|------|---------|------|-----------|-----|--------------|----------|----------------|
| 1 (nominal) | 1.5Ω | 3.6V | **2.347 A** | 79.5 mV | 33.9 mΩ | 0.19 W | ✓ +0.85A |
| 2a (margen alto) | 2Ω | 3.6V | **1.770 A** | 59.5 mV | 33.6 mΩ | 0.11 W | ✓ +0.27A |
| 2b (margen bajo) | 1Ω | 3.6V | **3.480 A** | 120.2 mV | 34.5 mΩ | 0.42 W | ✓ +1.98A |
| 2c (peor caso) | 2Ω | 3.3V | **1.623 A** | 54.4 mV | 33.5 mΩ | 0.09 W | ✓ +0.12A |

Criterio del brief: corriente ≥ 1 A del ignitor + 0.5 A de margen → **1.5 A**.
El peor caso simulado (2c) da 1.62 A — cumple, pero es la esquina justa; ver
"Condiciones" más abajo.

No hace falta driver de gate ni cambiar de MOSFET: la zona de potencia puede
rutearse tal cual está el esquemático (GPIO15 → R11 220Ω → gate, R7 10k
pull-down, low-side).

## Caso 3 — Barrido DC Id vs Vgs (carga fija 1.5Ω, VSYS 3.6V)

| VGPIO (pre-R11) | Id | Nota |
|------|-----|------|
| 2.6 V | 84 mA | inicio de conducción (Vto=2.61 del modelo) |
| 2.7 V | 350 mA | |
| 2.8 V | 1.02 A | **VGPIO=2.80V ⇔ 1 A** (gate real ≈2.74V) |
| 2.9 V | 2.07 A | |
| 3.0–3.3 V | 2.30–2.35 A | limitado por la carga (no por el FET) |

El divisor R11/R7 (220Ω/10k) solo cuesta 71 mV: el gate reposa a 3.229V con
GPIO a 3.3V. La curva es empinada justo en la zona de trabajo (0.4V de
VGPIO pasan de 84 mA a 2.3 A), lo que hace el diseño tolerante al spread de
Vto **siempre que Vgs final quede claramente por encima del codo** — y queda:
3.23V vs codo ~2.8V.

## Caso 4 — Slew del gate (R11 220Ω + Ciss=1365pF del modelo)

Con un flanco GPIO deliberadamente lento de 1 µs (peor caso realista; el
RP2040 real conmuta en ns):

- **t al 90% de Id: 2.78 µs** desde el inicio del flanco (t90_id=102.78µs,
  pulso en t=100µs).
- t al 90% de Vgs: 3.02 µs. La corriente se adelanta al gate porque cruza el
  codo antes de que el gate termine de subir.
- Corriente estabilizada (±0.1%): ~10 µs. Sin overshoot (Id sube monotónico
  hasta 2.347 A).

Para un ignitor que necesita pulsos de ~ms, el retardo de µs es irrelevante.
R11=220Ω está bien; incluso 1kΩ seguiría siendo sobrado.

## Potencia

- **MOSFET:** peor caso continuo simulado 0.42 W (ignitor 1Ω). En el uso real
  el pulso es de ms → irrelevante para un DPAK (TO-252) incluso sin cobre
  térmico extra. P = Id²·Rds con Rds_eff≈34mΩ a Vgs=3.23V (el "Ron=5.8m" del
  modelo es a Vgs=10V; a 3.3V el modelo da ~34mΩ, coherente con Vto=2.61).
- **Ignitor (referencia):** 8.3 W durante el pulso en el caso nominal — es lo
  que dispara el e-match, no afecta al MOSFET.

## Condiciones y límites del veredicto

1. **El veredicto vale si el ignitor real pide ≤1.1 A.** El peor caso (2c)
   da 1.62 A: si al medir el e-match real su corriente de disparo supera
   ~1.1 A, el margen de 0.5 A ya no se cumple y tocaría pasar a (b) driver
   de gate o (c) MOSFET con Vto<2V. **Acción: medir la resistencia y
   corriente del ignitor real al recibirlo** (es la única variable no
   controlada).
2. **Spread de Vto (estimación analítica, no simulada):** si una unidad real
   tiene Vto=3.0V (peor caso de spread), Rds≈1/(Kp·(Vgs−Vto))≈1/(70·0.23)≈
   62mΩ → Id≈3.6/(1.5+0.062)≈2.30A a 1.5Ω. Sigue sobrado: la carga domina,
   no el FET.
3. Modelo Bordodynov inline verificado en ngspice-45 sin warnings
   (`mfg`, `Ron`, `Qg` se aceptan como parámetros informativos).
   Fuente: `hardware/Kicad/ignition-system/Local Spice/AOD4184A.lib`.

## Quirks de ngspice-45 encontrados (para quien repita esto)

- `meas` **no** acepta vectores de dispositivo tipo `@m1[id]` (devuelve 0 o
  "out of interval"). Usar la corriente de la fuente: `let idd = -i(vsys)`
  (VSYS solo alimenta el ignitor, así que es exactamente Id).
- `wrdata` escribe **pares (x, y) por vector**: con 3 vectores salen 6
  columnas (t, y1, t, y2, t, y3). No confundir la columna y2 con la x.
- `print` con texto literal lanza `PPerror`; usar `echo "..."`.
- Los resultados de `meas` mueren con `destroy all`/`reset`: si un `WHEN`
  necesita un valor medido antes, re-medirlo en el mismo plot (hecho así en
  el caso 4).

## Archivos

- `ignition-sim.cir` — netlist con los 4 casos (2a/2b/2c como caso 2) en un
  solo `.control`, orquestados con `alterparam`+`reset`.
- `run.sh` — corre ngspice en batch, tedea a `out/ngspice.log` y falla si no
  llega al caso 4 (chequeo ejecutable mínimo).
- `out/` — `ngspice.log` + un `.raw` ASCII por caso (case1, case2a/b/c,
  case3, case4).
