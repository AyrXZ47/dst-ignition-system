# Design Notes — DST Ignition System

> Referencia de diseño del sistema de ignición remota para cohetería
> experimental (Dragons Space Team).
> Fuentes: netlist exportado de `hardware/Kicad/ignition-system/ignition-system.kicad_sch`
> (2026-08-14, `kicad-cli sch export netlist`), `DRC.rpt`, y decision log en
> `.workflow/plan.md`. Estado: **wave 1 en curso** (fixes del esquemático en
> manos del humano, ver §3).

## 1. Topología

Sistema de ignición por MOSFET de lado bajo, alimentado por LiPo 1S y con
enlace de radio LoRa/nRF24:

```
                ┌────────────────────────────────────────────────┐
 USB ◄────────► │ Raspberry Pi Pico (RP2040)                     │
                │                                                │
                │  GPIO13  BTN_FIRE  ← SW1 (botón)               │
                │  GPIO15  IGNITION_GATE → R11 220Ω → G AOD4184A1│
                │  GPIO10/11/12 LEDs LINK / MODO / ARMADO        │
                │  GPIO26  ADC_Bateria ← divisor R5/R6 (10k/10k) │
                │  GPIO4/5 I2C (SDA/SCL) → Display1              │
                 │ GPIO16-19 SPI + GPIO20/21 → socket RA-02       │
                └───────┬─────────────────────────────────┬──────┘
                        │ VSYS (batería)                  │ 3V3
                ┌───────▼────────┐               ┌────────▼─────────┐
                │ TP4056 (carga) │               │ Display1 (I2C)   │
                │ CE → VBUS      │               │ 1x04, 2.54mm     │
                 │ TEMP → TH1 NTC │               └──────────────────┘
                 └───────┬────────┘
                         │ BATP (celda + BAT del TP4056)
                 ┌───────▼────────┐               ┌──────────────────┐
                 │ InBatt1 (JST)  │               │ AOD4184A1        │
                 │ LiPo 1S(PCM)   │               │ D ◄─ IGNITOR1.2  │
                 └───┬────────────┘               │ G ◄─ R11 ← GPIO15│
                     │ SW3 (SPDT)                 │ S → GND (low-side│
                     └─► VSYS ──► SW2.1/2.2 ──► IGNITOR1.1 (e-match)
                                       IGNITOR1 = terminal 5.0mm (1x02)
```

Flujo de disparo: `BTN_FIRE` (SW1) → GPIO13; firmware activa `IGNITION_GATE`
(GPIO15) → R11 220Ω → gate del AOD4184A1 → conduce → cierra el circuito del
ignitor (IGNITOR1) contra GND. El flujo de potencia de la placa: celda
(InBatt1) → nodo BATP (compartido con el pin BAT del TP4056) → SW3 → VSYS.
SW3 es el switch maestro de la placa: abierto = Pico/LEDS/divisor/ignitor
sin tensión (consumo ~0), cerrado = normal; la carga funciona con la placa
apagada (VBUS del pin 40 del Pico → TP4056 → BATP → celda, sin pasar por SW3).
SW2 (SPDT) conecta la línea del ignitor a VSYS (ON) o la ata a GND (seguro/descarga, línea sin fuente detrás).

## 2. Mapa de pines RP2040 (Raspberry Pi Pico)

Fuente: netlist exportado del esquemático (pad → net). Los GPIO se numeran
según el pinout estándar del Pico.

| Pad Pico | GPIO | Net | Función |
|----------|------|-----|---------|
| 6 | GPIO4 | SDA | Display I2C |
| 7 | GPIO5 | SCL | Display I2C |
| 14 | GPIO10 | LED_LINK | LED azul de enlace (R1 330Ω) |
| 15 | GPIO11 | LED_MODO | LED amarillo de modo (R2 330Ω) |
| 16 | GPIO12 | LED_ARMADO | LED rojo de armado (R3 330Ω) |
| 17 | GPIO13 | BTN_FIRE | Botón de disparo (SW1) |
| 20 | GPIO15 | IGNITION_GATE | Gate del MOSFET vía R11 220Ω |
| 21 | GPIO16 | MISO | SPI socket LORA RA-02 (fila LORA-Sx1278(B)) |
| 22 | GPIO17 | NSS | SPI CS (LORA-Sx1278(B)) |
| 24 | GPIO18 | SCK | SPI (LORA-Sx1278(B)) |
| 25 | GPIO19 | MOSI | SPI (LORA-Sx1278(B)) |
| 26 | GPIO20 | RST | Reset (LORA-Sx1278(A), fila de control) |
| 27 | GPIO21 | DIO0 | IRQ (LORA-Sx1278(A)) |
| 31 | GPIO26/ADC0 | ADC_Bateria | Medición de batería (divisor R5/R6) |
| 3, 8, 13, 18, 23, 28, 38 | — | GND | Tierra |
| 36 | — | 3V3 | Alimentación 3.3V |
| 39 | — | VSYS | Alimentación del Pico (batería) |
| 40 | — | VBUS | USB; alimenta el CE del TP4056 |

Sin conectar (disponibles para ola 2/3): GPIO0-3, GPIO6-9, GPIO14, GPIO22,
GPIO27/ADC1, GPIO28/ADC2, AGND, ADC_VREF, RUN, 3V3_EN.

Nota radio: LORA-Sx1278(A) y LORA-Sx1278(B) son una ÚNICA radio — el SOCKET
físico del módulo SX1278 RA-02 (2 filas de 8 agujeros, un borde por cara del
módulo de 17×16 mm). Fila A = control (GND, GND, 3V3, RST, DIO0); fila B =
SPI (NSS, MOSI, MISO, SCK); DIO1–DIO5 quedan sueltos sin conectar. El rol
TX/RX es puro firmware: transceptor half-duplex, un módulo por placa.

## 3. Decisiones de diseño

Del decision log de `.workflow/plan.md` (wave 1):

- **CE del TP4056 → VBUS (pin 8), no al net "VCC".** El net VCC no tiene
  fuente (ERC `power_pin_not_driven`). El pin 8 queda alimentado por VBUS, que
  viene del USB del Pico. *Estado: fix del humano en curso (GUI).*
- **TEMP del TP4056 (pin 1) va a GND a través de TH1** (NTC 10k B3950, header
  1x02; el NTC se pega a la celda, V lo confirma para 2026-09-15b). Revoca la
  nota wave 1 de "TEMP→GND": TEMP recupera su función térmica (ventana
  ≈ 0–45 °C); la protección eléctrica de la celda vive en el PCM integrado.
- **Labels DIO1-DIO5 eliminados.** Colgaban sin destino en el esquemático; si
  se necesitan en ola 2/3, se re-añaden con propósito concreto.
- **Human-in-the-loop como modelo de trabajo** (adaptación de AGENTS.md a
  hardware): el humano edita KiCad en GUI; los agentes planifican, verifican
  con `kicad-cli`, documentan y simulan. Los fixes de wave 1 los aplica el
  humano (~5 min de clics).
- **SW3 = switch maestro en serie entre BATP y VSYS** (nodo BATP: InBatt1.1 +
  pin BAT del TP4056). La carga funciona con la placa apagada (VBUS del pin 40
  del Pico → TP4056 → BATP → celda, aguas arriba del switch); con SW3 abierto
  el consumo es ~0. El pin suelto del SPDT queda sin conectar (nunca a GND:
  un interruptor de potencia a tierra cortocircuita el pack al accionarlo).
  Hay un PWR_FLAG en VSYS (anotación KiCad para satisfacer el ERC del switch
  de potencia, sin efecto eléctrico).
- **Disparo low-side**: el ignitor (J1) va entre la alimentación conmutada por
  SW2 y el drenador del MOSFET; fuente a GND. Pull-down R7 10k en el gate.
- **Divisor de batería**: VSYS → R5 10k → ADC_Bateria → R6 10k → GND.

## 4. BOM preliminar

Extraído del netlist exportado (29 referencias, 2026-09-16). Pendiente de confirmar
valores de display/módulos con el humano.

| Ref | Valor | Footprint | Función |
|-----|-------|-----------|---------|
| RaspberryPi_Pico1 | Raspberry Pi Pico (RP2040) | Module: Pico común | MCU |
| ModuloDeCarga1 | TP4056-42-ESOP8 | SOIC-8-1EP 3.9x4.9mm | Cargador Li-ion 1S |
| AOD4184A1 | NMOS (Vto≈2.61V, Ron≈5.8mΩ) | TO-252-2 | Interruptor de ignición |
| C1, C2 | 10µF | 0805 | Desacople |
| R1, R2, R3 | 330Ω | 0805 | LEDs LINK/MODO/ARMADO |
| R4 | 2.2kΩ | 0805 | PROG del TP4056 |
| R5, R6 | 10kΩ | 0805 | Divisor ADC_Bateria |
| R7 | 10kΩ | 0805 | Pull-down del gate |
| R8, R9 | 1kΩ | 0805 | LEDs STDBY/CHRG del cargador |
| R11 | 220Ω | 0805 | Serie al gate |
| BLED1, YLED1, RLED1 | LED | 0805 | Estado: enlace/modo/armado |
| CHRG1, STDBY1 | LED | 0805 | Estado de carga |
| Display1-SSD1306 | SSD1306 (conector 1x04) | PinHeader 2.54mm | Display I2C |
| InBatt1 | Conector 1x02 | JST PH 2.0mm | Batería LiPo 1S (≥500mAh: pulso de ignición ~2.7A) |
| IGNITOR1 | Terminal 1x02 | Screw_Terminal_01x02 5.0mm | Ignitor/e-match |
| LORA-Sx1278(A), (B) | Conector 1x08 | PinHeader 2.54mm | SOCKET del módulo SX1278 RA-02: fila control (A) + fila SPI (B) — 1 radio por placa |
| TH1 | NTC 10k B3950 | PinHeader 1x02 | Sonda térmica del TEMP del TP4056 (pegada a la celda) |
| SW1 | Pulsador | PinHeader 1x02 | BTN_FIRE |
| SW2 | SPDT | PinHeader 1x03 | Selector de ignitor: VSYS / GND |
| SW3 | SPDT | PinHeader 1x03 | Switch maestro de la placa (BATP ↔ VSYS) |

## 5. Estado del PCB

`hardware/Kicad/ignition-system/ignition-system.kicad_pcb` (KiCad 10.0):

- **Colocación en progreso** (humano, GUI, 2026-09-16): footprints colocados
  en tablero; sin conectar.
- **Ruteo: pendiente** (lo hace el humano en la GUI; los agentes solo
  verifican con `kicad-cli pcb drc`).
- **DRC 2026-09-16: 98 hallazgos** = 32 violaciones + 66 pads sin conectar
  (consecuente con un board sin rutear). Desglose de violaciones:
  `drill_out_of_range` ×6, `hole_clearance` ×8, `hole_to_hole` ×3,
  `copper_edge_clearance` ×2, `shorting_items` ×6, `items_not_allowed` ×2,
  `silk_over_copper` ×31, `silk_overlap` ×15, `silk_edge_clearance` ×10,
  `solder_mask_bridge` ×6, `lib_footprint_mismatch` ×9.
  ⚠️ Las 6 `drill_out_of_range` del TP4056 REGRESARON: el árbol integrado
  tiene `"min_through_hole_diameter": 0.3` (línea 161 del .kicad_pro) —
  el fix de T6 (0.2) se revirtió en la integración/fusión del .kicad_pro.
  Reportado a V; corregir con el humano en GUI antes de seguir el ruteo.
- ERC: **0 errores / 0 warnings** (2026-09-16, tras H7b/H8/H9 del humano).

## 6. Pendientes y riesgos

- **Margen de gate del AOD4184A1**: Vto≈2.61V contra 3.3V lógicos → Vgs−Vto
  ≈ 0.7V. Validar por SPICE en ola 2 (modelo en `hardware/Kicad/ignition-system/Local Spice/AOD4184A.lib`);
  si no conduce suficiente, driver de gate o MOSFET con Vto menor. También:
  slew rate con R11=220Ω y picos en el pull-down R7.
- **Switch maestro SW3 + carga**: BATP (celda + pin BAT del TP4056) → SW3 →
  VSYS; la carga funciona con la placa apagada (VBUS pin 40 → TP4056 → BATP,
  sin pasar por SW3); con SW3 abierto el consumo del sistema es ~0 (reemplaza
  al viejo "BAT+ (VSYS)" directo). Colocar cerca del borde, aparte del
  conector InBatt, con huella accesible de mano enguantada.
- **NTC TH1**: pegar físicamente la sonda B3950 a la celda (cinta Kapton) y
  ruta corta InBatt→TH1 en el ruteo; ventana térmica ≈ 0–45 °C.
- **Firmware**: `src/` está vacío; el Rust/Embassy prometido en el README aún
  no existe (ver README, §Estado del hardware).
- **Ignitor/e-match — RESUELTO 2026-09-02 (medido, lote n=10)**: R_min/R_typ/
  R_max = **0.8 / 0.93 / 1.1 Ω** (2 multímetros, spread ≤0.3Ω, lote
  consistente). R_wire del cableado no medido: estimado **0.2Ω** conservador.
  Fase B destructiva: 4/4 ignitores disparados con pila 3V vía amperímetro;
  rango 200mA en OVERLOAD → I_fire > 200mA real (la lectura "0.01A" del rango
  10A se descarta como artefacto de display: el burst dura ms, el DMM muestrea
  ~3/s; a 10mA con 0.93Ω habría solo 0.1mW — físicamente imposible).
  **Chequeo de margen**: `I_worst = 3.3 / (R_max + R_wire + 0.034)` =
  3.3 / (1.1 + 0.2 + 0.034) ≈ **2.47A ≥ 1.1A** (margen 2.25×). Nominal
  3.6V → 2.70A. P ignitor ≈ 6.7W por pulso; P MOSFET ≈ 0.21W por pulso
  (trivial para DPAK). **Cierra la condición del REPORT.md de wave 2:
  veredicto (a) CONFIRMADO con datos reales** — AOD4184A se queda, sin driver
  ni cambio de MOSFET. Fuente: decision log de `.workflow/plan.md`
  (entrada 2026-09-02).
- **Radio — RESUELTO 2026-09-15**: es LoRa SX1278 RA-02. No hay dos radios:
  LORA-Sx1278(A)/(B) son el socket físico del módulo (2 filas de 8); el rol
  TX/RX es puro firmware (transceptor half-duplex, un módulo por placa).
  DIO1–DIO5 del módulo quedan sueltos (sin conectar en el socket).
- **Display — modelo confirmado (2026-09-01)**: SSD1306 I2C sobre conector
  1x04; queda solo confirmar si el conector 1x04 basta (el 5º pin del
  SSD1306-A es VCC extra, opcional).
