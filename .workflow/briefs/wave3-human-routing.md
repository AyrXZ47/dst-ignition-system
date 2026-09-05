# Brief manual (HUMANO): Wave 3 · H6 — Placement y ruteo en GUI

> Tu tarea en la GUI de KiCad. El executor-4 ya corrigió el board setup
> (min hole 0.2mm). Esta guía va por bloques, en orden. En cada hito puedes
> parar y pedirme verificación con kicad-cli. Regla general: **el cobre de
> abajo (B.Cu) es TODO GND** — ese es tu "GND común" físico: todos los
> retornos vuelven por el plano, sin que tengas que rutear ni un cable de
> tierra.

## Hito 0 — Board setup (10 min)

**Archivo → Configuración de placa → Clases de red (Net Classes):**
1. Añade una clase **`Power`**: `track_width = 1.0 mm`, `clearance = 0.25`,
   `via 0.8/0.4`. Justificación: el lazo del ignitor conmuta ~2.7A de pulso
   (1mm en 1oz ≈ subida de 20°C continuo; el pulso dura ms — sobrado).
2. Asigna a `Power` los nets: **VSYS** y **VBUS**. Todo lo demás se queda en
   Default (0.2mm — suficiente para señales, I2C, SPI y LEDs).
3. Resto de reglas: Default clearance 0.2 ya está bien para JLCPCB
   (mín. fab: pista/gap 0.127, agujero 0.2, borde 0.3).

**Contorno (Edge.Cuts):** el actual (173×110mm) sale del tier caro de la
fab. Redibújalo a **~50×70mm** (rectángulo). Quédate bajo 100×100mm para el
precio mínimo de JLCPCB. La placa cabe: el Pico es 51×17.8mm.

**Agujeros de montaje (decisión mía recomendada: SÍ):** añade 4 footprints
`MountingHole:MountingHole_3.2mm_M3` en las esquinas (3.5mm del borde). Es
una placa de cohete: hay que poder atornillarla al bay de aviónica.

## Hito 1 — Placement por bloques lógicos (30-45 min)

Activa rejilla 0.5mm (abajo a la derecha). Teclas: **M** mover, **R** rotar,
**E** editar. El flujo de señal manda: batería → carga → Pico → radio, y el
lazo de ignición lo más corto posible.

```
┌────────────────────────────────────────────┐
│ SW2      AOD4184A   R7   R11               │   ← bloque IGNICIÓN (lazo corto)
│ [InBatt JST]  [J1 terminal 5mm]            │      J1 en el borde, claro
├────────────────────────────────────────────┤
│ [TP4056] C1  R4  C2   [PICO — centro,      │   ← bloque CARGA a la izq.
│  CHRG STDBY LEDs]      horizontal]         │
├────────────────────────────────────────────┤
│ Display1        LORA1 ────────── LORA2     │   ← radio a la derecha,
│ SW1 botón  LEDs estado (borde inferior)    │      antenas hacia fuera
└────────────────────────────────────────────┘
```

Reglas de placement que NO se negocian:
1. **Lazo de ignición compacto:** InBatt/SW2 → J1 → MOSFET drain, en ese
   orden, pegados. Cuanto más corto ese lazo, mejor.
2. **TP4056 pegado a InBatt**, con C1/C2 a <2mm de sus pines (desacoplo).
3. **Desacoplo junto al Pico:** C2 (VBUS) cerca del pin 40 del Pico.
4. **Antenas de LORA1/LORA2 hacia el borde derecho**, y NO pongas cobre ni
   pistas bajo el último tercio de cada módulo (zona de antena).
5. LEDs de estado y SW1 (botón FIRE) en el borde que será accesible.
6. Deja 3mm+ entre cualquier cobre y el Edge.Cuts (regla de fab).

## Hito 2 — Plano GND (10 min)

1. Capa **B.Cu** → Añadir zona rellena (Add Filled Zone) → net **GND** →
   dibuja un rectángulo que cubra TODO el contorno.
2. Añadir zona en **F.Cu** igual (net GND) — la rellenaremos al final, el
   router la respeta igual.
3. **Vías GND**: por cada pad GND de cada chip (Pico ×7, TP4056, MOSFET
   source, C1, C2, LEDs), pon una vía pegada al pad (durante el ruteo: tecla
   **V**; o Place → Via sobre una pista GND). Apunta a ~30-50 vías en total
   al final; al principio basta 1 por pad GND.
4. Después de rutar: Editar → Rellenar todas las zonas.

## Hito 3 — Ruteo en este orden (60-90 min)

Rutea con el router interactivo (**D** sobre un pad; **V** inserta vía;
**Espacio** cambia de capa). Orden estricto:

1. **Lazo de ignición (Power, 1mm):** InBatt+ → (SW2 común/throw) → J1 pin1;
   J1 pin2 → drain del AOD4184A; source → GND con 2 vías al plano. El gate
   (R11→gate, R7→GND) va en 0.2mm — por ahí solo hay µA.
2. **Carga (Power, 1mm):** VBUS del Pico (pin 40) → TP4056 VBUS y CE; BAT+
   del TP4056 → net VSYS (InBatt + Pico pin 39). BAT- y GND: al plano con
   vías.
3. **3V3 y señales (Default, 0.2mm):** I2C al display, SPI a LORA1/2, LEDs,
   botón. Cortas y directas, evitando la zona de antena. A 10MHz no hace
   falta emparejar longitudes — el plano GND debajo hace el trabajo.
4. Si una pista de señal tiene que cruzar otra, usa una vía a B.Cu y otra de
   vuelta — pero B.Cu es del plano GND: los saltos en B.Cu son cortos (2-3
   vías máx por salto) para no cortar el plano.
5. F.Cu GND zone: dibújala al final cubriendo lo que quede libre → rellena
   todas las zonas.

## Hito 4 — Silk y limpieza (15 min)

1. Inspección → DRC: te saldrán warnings de silk (`silk_overlap`,
   `silk_over_copper`). Se arreglan moviendo los textos de referencia fuera
   de los pads (M sobre el texto; E para tamaño/giro). Los que no puedas,
   déjalos: son warnings, no errores — pero reduce los que puedas.
2. Verifica visualmente: contorno cerrado, ningún cobre a <0.3mm del borde,
   antenas libres de cobre.

## Hito 5 — Entrega a verificación

Cuando digas "ruteado": yo lanzo la T8 del executor-4 (DRC headless hasta 0
errores / 0 unconnected) y cerramos la wave 3. Comitea tú el `.kicad_pcb`
en main:

```bash
cd "/home/yovick/repos/Workspace dst-ignition-system/dst-ignition-system"
git add hardware/Kicad/ignition-system/ignition-system.kicad_pcb
git commit -m "feat: ruteo pcb de ignition-system"
git push origin main
```

(Si la GUI toca el `.kicad_pro` al guardar, `chore(kicad):` separado —
práctica ya establecida.)
