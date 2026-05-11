<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This project implements an iterative trigonometric computation core based on Taylor series expansion. The design is intended for ASIC implementation using the Tiny Tapeout flow.

The architecture is based on a controller and datapath structure. The controller manages the computation sequence and iteration flow, while the datapath performs the arithmetic operations required for sine and cosine evaluation using fixed-point arithmetic.

The current implementation contains the initial Tiny Tapeout wrapper and verification environment. The computational core will be integrated incrementally.

## How to test

The project can be simulated using the cocotb-based verification environment provided in the `test` directory.
Run the simulation using:

```sh
cd test
make

## External hardware

List external hardware used in your project (e.g. PMOD, LED display, etc), if any

No external hardware is currently required.