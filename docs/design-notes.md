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
                │  GPIO16-19 SPI + GPIO20/21 → LORA1 / LORA2     │
                └───────┬─────────────────────────────────┬──────┘
                        │ VSYS (batería)                  │ 3V3
                ┌───────▼────────┐               ┌────────▼─────────┐
                │ TP4056 (carga) │               │ Display1 (I2C)   │
                │ CE → VBUS      │               │ 1x04, 2.54mm     │
                │ TEMP → GND     │               └──────────────────┘
                └───────┬────────┘
                        │ BAT+ (VSYS)
                ┌───────▼────────┐   ┌──────────────────────────────┐
                │ InBatt1 (JST)  │   │ AOD4184A1 (NMOS TO-252-2)    │
                │ LiPo 1S        │   │ D ◄─ J1 pin2 (ignitor)       │
                └────────────────┘   │ G ◄─ R11 (220Ω) ← GPIO15     │
                        ┌───────────►│ S → GND (low-side)           │
                        │ SW2 (SPDT) └──────────────────────────────┘
                VSYS ────┘
                        └───────────► J1 pin1 (ignitor/e-match)
                                     J1 = terminal 5.0mm (1x02)
```

Flujo de disparo: `BTN_FIRE` (SW1) → GPIO13; firmware activa `IGNITION_GATE`
(GPIO15) → R11 220Ω → gate del AOD4184A1 → conduce → cierra el circuito del
ignitor (J1) contra GND. SW2 (SPDT) corta/alimenta VSYS hacia el ignitor como
interruptor de seguridad en serie.

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
| 21 | GPIO16 | MISO | SPI LORA1 |
| 22 | GPIO17 | NSS | SPI CS LORA1 |
| 24 | GPIO18 | SCK | SPI LORA1 |
| 25 | GPIO19 | MOSI | SPI LORA1 |
| 26 | GPIO20 | RST | Reset LORA2 |
| 27 | GPIO21 | DIO0 | IRQ LORA2 |
| 31 | GPIO26/ADC0 | ADC_Bateria | Medición de batería (divisor R5/R6) |
| 3, 8, 13, 18, 23, 28, 38 | — | GND | Tierra |
| 36 | — | 3V3 | Alimentación 3.3V |
| 39 | — | VSYS | Alimentación del Pico (batería) |
| 40 | — | VBUS | USB; alimenta el CE del TP4056 |

Sin conectar (disponibles para ola 2/3): GPIO0-3, GPIO6-9, GPIO14, GPIO22,
GPIO27/ADC1, GPIO28/ADC2, AGND, ADC_VREF, RUN, 3V3_EN.

Nota LORA2: solo RST y DIO0 están cableados; el SPI lo comparte conceptualmente
con LORA1 pero queda pendiente decidir el módulo definitivo (ola 2/3).

## 3. Decisiones de diseño

Del decision log de `.workflow/plan.md` (wave 1):

- **CE del TP4056 → VBUS (pin 8), no al net "VCC".** El net VCC no tiene
  fuente (ERC `power_pin_not_driven`). El pin 8 queda alimentado por VBUS, que
  viene del USB del Pico. *Estado: fix del humano en curso (GUI).*
- **TEMP del TP4056 → GND (pin 1).** No hay NTC en el BOM.
  `ponytail:` — techo: el cargador no tendrá protección térmica de batería;
  upgrade path: si se usa una LiPo con terminal NTC, añadir divisor de NTC en
  ola 3 y conectar TEMP a su punto medio.
- **Labels DIO1-DIO5 eliminados.** Colgaban sin destino en el esquemático; si
  se necesitan en ola 2/3, se re-añaden con propósito concreto.
- **Human-in-the-loop como modelo de trabajo** (adaptación de AGENTS.md a
  hardware): el humano edita KiCad en GUI; los agentes planifican, verifican
  con `kicad-cli`, documentan y simulan. Los fixes de wave 1 los aplica el
  humano (~5 min de clics).
- **Disparo low-side**: el ignitor (J1) va entre la alimentación conmutada por
  SW2 y el drenador del MOSFET; fuente a GND. Pull-down R7 10k en el gate.
- **Divisor de batería**: VSYS → R5 10k → ADC_Bateria → R6 10k → GND.

## 4. BOM preliminar

Extraído del netlist exportado (28 referencias). Pendiente de confirmar
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
| Display1 | Conector 1x04 | PinHeader 2.54mm | Display I2C |
| InBatt1 | Conector 1x02 | JST PH 2.0mm | Batería LiPo 1S (≥500mAh: pulso de ignición ~2.7A) |
| J1 | Terminal 1x02 | MX126-5.0-02P 5.0mm | Ignitor/e-match |
| LORA1, LORA2 | Conector 1x08 | PinHeader 2.54mm | Módulos LoRa/nRF24 |
| SW1 | Pulsador | PinHeader 1x02 | BTN_FIRE |
| SW2 | SPDT | PinHeader 1x03 | Interruptor de alimentación |

## 5. Estado del PCB

`hardware/Kicad/ignition-system/ignition-system.kicad_pcb` (KiCad 10.0):

- **No ruteado**: 0 pistas, 0 vias, 0 zonas de cobre.
- **DRC: 34 violaciones** (`DRC.rpt`, 2026-08-13):
  - 6 × `drill_out_of_range`: pads PTH del TP4056 con agujero 0.2mm < mínimo
    del board setup (0.3mm) → se corrige en ola 3 (ajuste de regla o
    footprint).
  - 28 × silk (`silk_overlap` y `silk_over_copper`, warnings) → se corrigen
    en ola 3.
- **59 pads sin conectar** (`unconnected_items`): consecuente con un PCB sin
  rutear; se resuelven en ola 3.
- ERC: pendiente de los fixes del esquemático (§3); objetivo 0 errores.

## 6. Pendientes y riesgos

- **Margen de gate del AOD4184A1**: Vto≈2.61V contra 3.3V lógicos → Vgs−Vto
  ≈ 0.7V. Validar por SPICE en ola 2 (modelo en `hardware/Kicad/ignition-system/Local Spice/AOD4184A.lib`);
  si no conduce suficiente, driver de gate o MOSFET con Vto menor. También:
  slew rate con R11=220Ω y picos en el pull-down R7.
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
- **Módulos de radio**: confirmar LoRa vs nRF24 definitivo; LORA2 solo tiene
  RST/DIO0 cableados.
- **Display**: confirmar modelo I2C (SSD1306) y si el conector 1x04 basta.
