# 🚀 DST Ignition System

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE-SOFTWARE)
[![Hardware License: CERN-OHL-P-2.0](https://img.shields.io/badge/Hardware-CERN--OHL--P--2.0-blue)](LICENSE-HARDWARE)

A solid-state, remote ignition system designed for experimental rocketry. Built for the Dragons Space Team to safely and reliably ignite rocket motors (like Estes Viking) using electronic matches.

## 🧠 System Architecture
* **Microcontroller:** Raspberry Pi Pico (RP2040)
* **Firmware:** Written in Rust 🦀 (Async with Embassy framework)
* **Telemetry & Comms:** NRF24L01+ modules
* **Power Switching:** Logic-Level N-Channel MOSFETs

## 📂 Repository Structure
* `/hardware/`: KiCad project files (Schematics and PCB layouts).
* `/src/`: Rust source code for the RP2040 firmware.
* `/docs/`: Pinout diagrams, component datasheets, and operation manuals.

## 🛠️ Getting Started
### Firmware (Rust)
1. Install Rust and the `thumbv6m-none-eabi` target:
   `rustup target add thumbv6m-none-eabi`
2. Install `elf2uf2-rs` for easy flashing:
   `cargo install elf2uf2-rs --locked`
3. Build and run: `cargo run --release`

### Hardware
Open the project in KiCad 8.x or newer located in the `/hardware/` directory. 
