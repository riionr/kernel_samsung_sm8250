# AospKSU

# Introduction
- This repository is always compliant with the latest vanadium-oss samsung sm8250 kernel changes.

## Warning
- Credit me if you use this source for any of your projects.
- Please use it with caution.

## Warranty
- None, none at all. I am handing you a **sharp knife**, it is not on me if you stab yourself with it.

## Notes
- The kernel source code is stable.
- It supports AOSP/LineageOS based roms ranging from Android 13 upto Android 17 QPR2.
- No OneUI support is provided.

## Telegram
- [t.me/not_kernel](https://t.me/not_kernel) // Dummy chat
- [t.me/AospKSU](https://t.me/AospKSU) // Channel - same as github releases provided in this repo

## KernelSU Manager
- [doubledashdot/sKernelSU](https://github.com/doubledashdot/sKernelSU) // Manager releases
- [t.me/sKernelSU](https://t.me/sKernelSU) // Channel - same as github releases provided in the repo above


---

# DroidSpaces Integration

This fork extends AospKSU with DroidSpaces support
for the Samsung Galaxy S20 FE.

## Target Device

| Property | Value |
| --- | --- |
| Device | Samsung Galaxy S20 FE 4G |
| Model | SM-G780G |
| Codename | r8q |
| SoC | Qualcomm Snapdragon 865 |
| Tested ROM | LineageOS 23.2 |
| Android | 16 |
| Kernel | Linux 4.19.325 |
| Architecture | ARM64 |

## Features

- AospKSU kernel base.
- Integrated sKernelSU.
- DroidSpaces kernel configuration.
- Cgroup compatibility patch.
- Linux namespace support.
- OverlayFS support.
- Seccomp support.
- Container networking and NAT support.
- Docker-related kernel configuration.
- Pinned build dependencies.
- Automated AnyKernel3 packaging.
- Toolchain integrity verification.

## Build Requirements

Recommended build environment:

- Ubuntu 24.04 LTS (x86_64).
- 12 GB RAM.
- 8 GB swap.
- 50 GB of available disk space.

Install the required packages:

```sh
sudo apt update
sudo apt install -y build-essential bc bison flex \
  git curl jq zip unzip zstd libssl-dev libelf-dev \
  gcc-aarch64-linux-gnu gcc-arm-linux-gnueabi
```

## Building

Clone this repository:

```sh
git clone -b droidspaces-integration \
  https://github.com/riionr/kernel_samsung_sm8250.git

cd kernel_samsung_sm8250
```

Provide the validated Neutron Clang archive:

```sh
export TOOLCHAIN_PATH=/path/to/neutron-clang-24-f42c87ba.tar.zst
```

Start the build:

```sh
bash build.sh
```

The resulting AnyKernel3 ZIP will be generated
in the repository root.

## Dependency Management

All validated dependency revisions and toolchain
checksums are recorded in dependencies.lock.

The tools/setup-dependencies.sh script prepares
and verifies the required dependencies.

The validated toolchain archive is not yet
publicly distributed by this fork.

## Validation Status

- Original custom kernel: boot tested on SM-G780G.
- sKernelSU: operational.
- DroidSpaces: container startup verified.
- Clean independent build: successful.
- Kernel configuration: identical to original build.
- DTB and DTBO: matching SHA-256 checksums.
- AnyKernel3 ZIP integrity: verified.
- Bit-for-bit kernel reproducibility: not established.
- Latest rebuilt ZIP: device testing pending.
- Full Docker compatibility: additional testing required.

Other device variants have not been validated
by this fork.

## Installation Warning

Back up your boot and dtbo partitions before flashing.

This fork is intended for compatible AOSP-based ROMs.
OneUI is not supported.

Use at your own risk.

## Credits

- doubledashdot / not_kernel - AospKSU and sKernelSU.
- Vanadium OSS - upstream kernel development.
- ravindu644 - DroidSpaces.
- LineageOS contributors.
- Neutron Toolchains contributors.
- AnyKernel3 contributors.
- riionr - DroidSpaces integration and build automation.

All original licensing and copyright notices are retained.
