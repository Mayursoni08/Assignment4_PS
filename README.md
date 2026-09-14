# Ferranti Effect Simulation — EE 315 Assignment 4

Simulation and mitigation of the Ferranti effect on a 220 kV, 50 Hz, 200 km
transmission line, built in MATLAB/Simulink (Simscape Electrical).

**Project page:** https://Mayursoni08.github.io/Assignment4_PS/

## Group

| Member | Roll Number | Name |
|---|---|---|
| Member 1 | 240002007 | Akarsh J |
| Member 2 | 240002073 | Sreehari |
| Member 3 | 240002043 | Naman V Shetty |
| Member 4 | 240002037 | **Mayur Soni** (Project Lead) |
| Member 5 | 240002017 | Bhasuru Nikhil |
| Member 6 | 240002069 | Ridhi Shakkar |

## Problem

Model a 220 kV, 50 Hz, 200 km transmission line and demonstrate the
Ferranti effect (receiving-end voltage rise) under no-load/light-load
conditions, then suggest and demonstrate a mitigation.

**Line parameters:**
- Series resistance: 0.05 Ω/km/phase
- Series inductance: 1 mH/km/phase
- Shunt capacitance: 0.01 µF/km/phase

## Files

| File | Description |
|---|---|
| `assignment4.m` | MATLAB script that programmatically builds and wires `model.slx` using Simscape Electrical Foundation Library blocks |
| `model.slx` | The resulting Simulink model |
| `report.tex` / `report.pdf` | Full write-up: theory, ABCD-parameter derivation, model construction, and results |
| `index.html` | Static demo page summarizing the project and results |

## How to rebuild the model

```
1. Open MATLAB (Online or desktop) with Simulink + Simscape Electrical.
2. Run: assignment4
3. This creates and saves model.slx in the current folder.
4. Open the model, press Run, then double-click Scope_Vs_Vr.
```

The model is built entirely from a script rather than saved as a
hand-drawn binary, so it is reproducible and diffable in Git.

## Results

| Condition | V_S (kV, LL) | V_R (kV, LL) | Change |
|---|---|---|---|
| Theoretical (no load, ABCD) | 220.0 | 224.4 | +2.01% |
| Simulated (light load, reactor OFF) | 220.0 | 224.75 | +2.16% |
| Simulated (light load, reactor ON) | 220.0 | 216.76 | −1.46% |

A ~30.4 MVAr shunt reactor was switched in at the receiving end at
t = 0.1 s during the simulation, bringing the receiving-end voltage
from above the sending-end value down to slightly below it —
confirming shunt reactor compensation as an effective mitigation for
the Ferranti effect.

## Reference

EE 315 Power Systems, Module Lecture Material, Department of
Electrical Engineering.
