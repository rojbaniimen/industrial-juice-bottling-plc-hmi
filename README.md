<div align="center">

# 🏭 Automated Fruit Juice Bottling & Mixing Station — PLC & SCADA/HMI
### *Industrial Sequential Control (GRAFCET / LADDER), Safety Diagnostics & WinCC PROFINET Supervision in Siemens TIA Portal V17*

[![TIA Portal](https://img.shields.io/badge/Siemens-TIA%20Portal%20V17-009999?style=for-the-badge&logo=siemens&logoColor=white)](https://www.siemens.com/)
[![PLC S7-1200](https://img.shields.io/badge/PLC-SIMATIC%20S7--1200-005F87?style=for-the-badge)]()
[![HMI WinCC](https://img.shields.io/badge/HMI-TP700%20Comfort%20(PROFINET)-2E7D32?style=for-the-badge)]()
[![IEC 61131-3](https://img.shields.io/badge/Language-GRAFCET%20%2F%20LADDER-FF6F00?style=for-the-badge)]()

**Authors:** **Imen Rojbani**, **Eya Yousfi**, **Wiem Abidi** & **Youssef Rebah** — *2nd Year Electrical Engineering Students, ENSIT (National Higher Engineering School of Tunis)*  
*Supervisor: Prof. Hela Belkhiria | Academic Year: 2025–2026*

</div>

---

## 🎯 Industrial Process & System Architecture

This project implements a complete industrial automation and supervisory control architecture for a **multi-recipe fruit juice bottling, mixing, labeling, and evacuation line** using **Siemens TIA Portal V17**[cite: 67, 68, 69, 70, 71].

```text
┌─────────────────────────────────────┐         PROFINET (100 Mbps)         ┌─────────────────────────────────────┐
│     SIMATIC HMI TP700 Comfort       │ ◄─────────────────────────────────► │        SIMATIC S7-1200 PLC          │
│         IP: 192.168.0.2             │    HMI_Connection_1 (WinCC Tags)    │          IP: 192.168.0.1            │
│  • Tank Levels & Valve Animations   │                                     │  • 12 LADDER Networks (GRAFCET)     │
│  • Recipe Selection (Apple/Orange)  │                                     │  • TON Timers (30s Dosing/Mixing)   │
│  • Batch Counter & Fault Alarms     │                                     │  • Jam Watchdog (10s) & CTU Counter │
└─────────────────────────────────────┘                                     └──────────────────┬──────────────────┘
                                                                                               │ Field I/O
                                                                                               ▼
                                                                            ┌─────────────────────────────────────┐
                                                                            │      Bottling Line Field Layer      │
                                                                            │  Sensors: dcy, pb, ja, jo, je,      │
                                                                            │           pbe, be                   │
                                                                            │  Actuators: KM1 (Conveyor), KM,     │
                                                                            │             E1 (Apple), E2 (Orange),│
                                                                            │             E3 (Water)              │
                                                                            └─────────────────────────────────────┘


```

## ⚙️ GRAFCET Functional Specification & I/O Mapping

The sequential control logic manages selective ingredient dosing via an **OR-divergence branch** (Apple vs. Orange juice), timed water addition, 30-second mechanical mixing, automated labeling verification, and bottle evacuation[cite: 68, 69, 70]:

| I/O Type | Tag Symbol | Industrial Component | Functional Role in Cycle |
| :--- | :---: | :--- | :--- |
| **Input** | `dcy` | Cycle Start Pushbutton | Initiates automated production cycle (`Step X0 → X1`)[cite: 69, 70] |
| **Input** | `pb` | Bottle Presence Sensor | Detects bottle arrival under filling manifold[cite: 69, 70] |
| **Input** | `ja` / `jo` | Recipe Selector (`Apple` / `Orange`) | Selects OR-branch (`Step X2` vs. `Step X8`)[cite: 69, 70] |
| **Input** | `je` | Water High-Level / Presence Sensor | Confirms water dosing completion (`Step X4`)[cite: 69, 70] |
| **Input** | `pbe` | Label Presence Sensor | Verifies label application (`Step X6`)[cite: 69, 70] |
| **Input** | `be` | Bottle Evacuated Sensor | Confirms exit and resets cycle (`Step X7 → X0`)[cite: 69, 70] |
| **Output** | `KM1` | Conveyor Belt Contactor | Advances bottle (`Steps X1, X6, X7`) with jam interlock[cite: 68, 69, 73] |
| **Output** | `E1` / `E2` | Solenoid Valves (`Apple` / `Orange`) | Selective 30 s juice dosing (`TON` timers)[cite: 68, 69, 70, 72] |
| **Output** | `E3` | Water Solenoid Valve | Controlled water dilution stage (`Step X3`)[cite: 68, 69, 70, 72] |
| **Output** | `KM` | Agitator / Mixer Motor | Homogeneous 30 s mixing phase (`Step X5`)[cite: 68, 69, 70, 72] |

---

## 💻 PLC LADDER Architecture (12 Networks — TIA Portal V17)

The GRAFCET Set/Reset state equations are structured across **12 modular LADDER networks** backed by dedicated Data Blocks (`DB_Grafcet`, `DB_Time`, `DB_Diag`, `DB_Prod`)[cite: 70, 71, 72, 73]:

* **Networks 1 – 3 (Initialization, Conveyor & Mixing Timer):** Manages initial step `X0` retention, conveyor motor `KM1` activation during transport steps, and the `TON` IEC timer (`T#30s`) controlling `Step X5` mixing duration[cite: 71].
* **Networks 4 – 6 (Selective Recipe Dosing & Agitation):** Implements mutual-exclusion interlocking between Apple (`E1`) and Orange (`E2`) valves, water filling (`E3`), and mixer motor (`KM`) actuation[cite: 72].
* **Networks 7 – 9 (Labeling, Evacuation & Emergency Global Reset):** Triggers labeling (`Label_Trigger` on `Step X6`), validates final evacuation (`Step X7`), and provides a `Global_Reset` safety block resetting all active steps (`X0...X8`)[cite: 72].
* **Networks 10 – 12 (Industrial Diagnostics & Batch Production Counter):**
  * **Auto-Ready Indicator (`H_Auto_Ready`):** Visualizes active automatic mode readiness[cite: 73].
  * **Bottle-Jam Watchdog (`T_Fail` — `T#10s`):** Automatically halts conveyor `KM1` and raises `Defaut_Bouteille` if a bottle remains stuck in transit for more than 10 seconds[cite: 73].
  * **Lot Counter (`C_Cycle` — `CTU`):** Tracks completed bottles in `DB_Prod.Cycle_Count` and triggers `H_Batch_Done` upon reaching the 500-bottle batch target[cite: 73].

---

## 🖥️ WinCC HMI Supervision & PROFINET Networking

* **Industrial Network Topology:** Direct **PROFINET** link (`HMI_Connection_1`) between **PLC_1 (`S7-1200` — `192.168.0.1`)** and **HMI_1 (`TP700 Comfort` — `192.168.0.2`)**[cite: 74].
* **Real-Time Synoptic Screen (`Image_5.0`):** Displays live tank levels (`[VAL_LOT_EAU]`, `[VAL_LOT_APU]`, `[VAL_LOT_EAN]`), animated solenoid valves (`E1, E2, E3`), mixer status (`KM`), and conveyor bottle tracking (`[KM1 - LOT BTL Actif]`)[cite: 74].
* **Operator Tag Mapping:** Exposes `HMI_Start`, `HMI_Juice_Type`, `HMI_Mix_Time_SP`, and `HMI_Water_Lot_Size` for live recipe parameterization without modifying PLC code[cite: 74].

---

## 📂 Repository Structure

```text
industrial-juice-bottling-plc-hmi/
├── plc_logic/
│   └── grafcet_equations_scl.st            # Structured GRAFCET Set/Reset & safety equations
├── Rapport-Supervision-Industrielle.pdf    # Complete TIA Portal LADDER & WinCC HMI report
└── README.md
