# 🚀 DST Ignition System

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE-SOFTWARE)
[![Hardware License: CERN-OHL-P-2.0](https://img.shields.io/badge/Hardware-CERN--OHL--P--2.0-blue)](LICENSE-HARDWARE)

A solid-state, remote ignition system designed for experimental rocketry. Built for the Dragons Space Team to safely and reliably ignite rocket motors (like Estes Viking) using electronic matches.

## 🧠 System Architecture
* **Microcontroller:** Raspberry Pi Pico (RP2040)
* **Firmware:** Rust 🦀 with Embassy — **planned, not implemented yet** (see [Hardware status](#-hardware-status))
* **Telemetry & Comms:** LoRa / NRF24L01+ modules
* **Power Switching:** Logic-Level N-Channel MOSFET (AOD4184A)

## 📂 Repository Structure
* `/hardware/`: KiCad project files (Schematics and PCB layouts).
* `/src/`: Rust source code for the RP2040 firmware.
* `/docs/`: Pinout diagrams, component datasheets, and operation manuals.

## 🛠️ Getting Started
### Firmware (Rust)
⚠️ **Not available yet.** The `src/` directory is empty: the Rust/Embassy firmware is planned but has not been written. The steps below are reserved for when it lands:

1. Install Rust and the `thumbv6m-none-eabi` target:
   `rustup target add thumbv6m-none-eabi`
2. Install `elf2uf2-rs` for easy flashing:
   `cargo install elf2uf2-rs --locked`
3. Build and run: `cargo run --release`

### Hardware
Open the project in KiCad 8.x or newer located in the `/hardware/` directory.

## 📋 Hardware status

Schematics and PCB live in `/hardware/Kicad/ignition-system/`. Current status
(wave 1, in progress — see [`docs/design-notes.md`](docs/design-notes.md) for
the full design reference):

* **Schematic:** RP2040 (Pico) + TP4056 Li-ion charger + AOD4184A N-MOSFET ignition switch + 2× LoRa/nRF24 headers + I2C display + status LEDs. Fixes in progress (TP4056 CE→VBUS, TEMP→GND, stray DIO labels).
* **PCB:** placed, **not routed** (0 tracks/vias). DRC: 34 violations (6 drill 0.2mm < 0.3mm min + 28 silkscreen) and 59 unconnected pads — pending wave 3.
* **Firmware:** `src/` is empty; no Rust/Embassy code exists yet.
* **Next:** wave 2 SPICE validation of the MOSFET gate margin (3.3V vs Vto 2.61V). 
