# Samsung Galaxy Tab S7 (SM-T870) Snapdragon 865+ Adreno 650 GPU Overclock Kernel

This repository contains the ultimate custom kernel modification for the Samsung Galaxy Tab S7 (Snapdragon 865+ "Kona" SoC) that successfully overclocks the Adreno 650 GPU from its factory thermal-locked state of 587 MHz / 670 MHz up to a blazing **940.8 MHz**.

## The Challenge: Samsung's Secure Bootloader & GMU Firmware
Overclocking the GPU on modern Samsung devices is not as simple as editing the Device Tree Blob (DTB). We encountered two major roadblocks during our development:

1. **Samsung ABL (Application Bootloader) DTBO Enforcement:** Samsung's bootloader enforces Android Verified Boot (AVB) and ignores any custom DTB injected via `boot.img`. It forces the kernel to load the hardware's locked `dtbo` partition. Attempting to flash a modified `dtbo.img` directly trips SECURE CHECK FAIL and causes a bootloop.
2. **GMU (Graphics Management Unit) 7-Level Firmware Constraint:** The Adreno 650 GMU ROM strictly requires the GPU frequency table to have exactly 7 levels, sorted in strictly decreasing order. Any attempt to blindly append an 8th level or spoof levels incorrectly results in `probe of 3d00000.qcom,kgsl-3d0 failed with error -22` and a completely dead GPU.

## The Solution: "The Holy Grail" C-Code RAM Override & Spoofing
Instead of fighting the bootloader by flashing device tree files, we allow the kernel to read the locked, original Samsung DTBO. However, the moment it finishes parsing it into RAM, we intercept the data using a custom C-code injection within `adreno.c` and `kgsl_hfi.c`.

### Key Modifications:
- **`drivers/gpu/msm/adreno.c`:**
  - Added 940.8 MHz dynamically to the Linux Operating Performance Point (OPP) table for the `RPMH_REGULATOR_LEVEL_TURBO_L1` voltage level.
  - Injected an override immediately after DTB parsing to replace the top array element (`pwrlevels[0].gpu_freq`) with 940.8 MHz.

- **`drivers/gpu/msm/kgsl_hfi.c` (The Spoof):**
  - When the DCVS table is sent via the HFI protocol to the GMU, we intercept the frequencies.
  - To prevent the GMU firmware from panicking at high frequencies, we cap the reported frequency to 587 MHz in the HFI payload, while the actual Linux Clock Control driver (`kgsl_pwrctrl_clk_set_rate`) directly forces the PLL hardware clock to 940.8 MHz.
  - This perfectly maintains the 7-level structural requirement of the GMU ROM while spoofing the safety checks.

- **`arch/arm64/boot/dts/vendor/qcom/kona-v2-gpu.dtsi`:**
  - Standardized the `qcom,gpu-freq` array levels to perfectly align with our 940.8 MHz target.
  - Cleared `qcom,throttle-pwrlevel` to `0` to permanently remove thermal throttling bottlenecks.

## Result
A flawlessly booting, stable kernel with no bootloader conflicts and no GMU crashes.

```bash
> cat /sys/class/kgsl/kgsl-3d0/max_gpuclk
940800000

> cat /sys/class/kgsl/kgsl-3d0/devfreq/available_frequencies
940800000 587000000 525000000 490000000 441600000 400000000 305000000
```

## Compilation
Use the provided `build.sh` script to compile the kernel. It automatically merges the required configs (including audio fidelity and BBR TCP congestion optimizations) and outputs the `Image` file ready to be packed into AnyKernel3.

---
*Developed with pure engineering tenacity and reverse-engineering logic. Enjoy the extreme performance!*
