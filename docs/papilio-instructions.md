# Loading a Circuit on the Papilio

This section describes how to a program a Papilio's FPGA with a synthesized design (`.bit` file).

## Prerequisites

* A Papilio Pro development board and USB cable (other Papilio boards ought to work, too).

* A Xilinx programming file (`.bit`), either generated using [these instructions](synthesis-instructions.md), or a pre-built one from the example projects.

* A working copy of the `papilio-prog` tool, including the FTDI USB device drivers ([installation instructions here](install-instructions.md)).

## Steps

#### 1. Connect the Papilio via USB

If you're running Linux in virtualization, you may need to add a USB port to your virtual machine. You will then likely need to grant the virtualized environment access to the device.

You may wish to grep dmesg to verify the connection:

```
root@ubuntu-vm-i386:# dmesg | grep FTDI
[ 9715.868915] usb 2-1: Manufacturer: FTDI
[ 9715.920856] usbserial: USB Serial support registered for FTDI USB Serial Device
[ 9715.920886] ftdi_sio 2-1:1.0: FTDI USB Serial Device converter detected
[ 9715.923563] usb 2-1: FTDI USB Serial Device converter now attached to ttyUSB0
[ 9715.923599] ftdi_sio 2-1:1.1: FTDI USB Serial Device converter detected
[ 9715.927584] usb 2-1: FTDI USB Serial Device converter now attached to ttyUSB1
[ 9738.389022] ftdi_sio ttyUSB0: FTDI USB Serial Device converter now disconnected from ttyUSB0
[10364.012161] ftdi_sio ttyUSB1: FTDI USB Serial Device converter now disconnected from ttyUSB1
```

#### 2. Verify the connection

**You will need to run these commands as superuser.** Use `sudo su` to create a root-privileged prompt, or preface commands with `sudo`.

Use the `papilio-prog -j` command to verify that the programmer can "talk" to the FPGA:

```
root@ubuntu-vm-i386:# papilio-prog -j
Using built-in device list
JTAG chainpos: 0 Device IDCODE = 0x24001093	Desc: XC6SLX9
```

An error like `Could not access USB device 0403:6010. If this is linux then use sudo.` indicates there is something wrong with your USB connection or hardware. Verify that your machine sees the USB device and that you're running `papilio-prog` as superuser.

#### 3. Locate the programming file

`cd` into the directory containing your programming file (`.bit`).

These can be found in the `/papilio` directory of the sample projects, or in the ISE project directory, if you used ISE to generate your own file.

#### 4. Program the device

Program the device using the `papilio-prog -f <bitfile>` command:

```
root@ubuntu-vm-i386:# papilio-prog -f loopback.bit
Using built-in device list
JTAG chainpos: 0 Device IDCODE = 0x24001093	Desc: XC6SLX9
Created from NCD file: loopback.ncd;UserID=0xFFFFFFFF
Target device: 6slx9tqg144
Created: 2017/03/25 13:31:51
Bitstream length: 2724832 bits

Uploading "loopback.bit". DNA is 0xf9f5ea92a61eb9ff
```

Upon completion, your hardware is ready to go! Do not power-cycle the device after programming it as the FPGA design configuration will be lost when the device is powered off.

To persist the design, the Papilio Pro contains a small flash memory that can be used to store your design and automatically load it on power-up. Use the `-s a` flag to erase, verify and program this flash:

```
root@ubuntu-vm-i386:# papilio-prog -s a -f loopback.bit
```