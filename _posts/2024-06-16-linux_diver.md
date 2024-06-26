---
title: "Linux Develop Document 01:  driver and driver probe"
author: Devin
date: 2024-06-16 09:37:00 +0800
categories: [linux]
tags: [linux driver]
pin: false
math: true
mermaid: true
---
<!--
image:
    path: /_posts/picbed/test.jpg
    lqip: data:image/webp;base64,UklGRpoAAABXRUJQVlA4WAoAAAAQAAAADwAABwAAQUxQSDIAAAARL0AmbZurmr57yyIiqE8oiG0bejIYEQTgqiDA9vqnsUSI6H+oAERp2HZ65qP/VIAWAFZQOCBCAAAA8AEAnQEqEAAIAAVAfCWkAALp8sF8rgRgAP7o9FDvMCkMde9PK7euH5M1m6VWoDXf2FkP3BqV0ZYbO6NA/VFIAAAA
    alt: Responsive rendering of Chirpy theme on multiple devices.
-->

## Linux Kernel Driver && Device Tree Source

### Linux Kernel Driver

A Linux kernel driver is a type of software component that allows the Linux operating system to interact with hardware devices. These drivers are essential for managing the hardware and providing an interface between the hardware and the software applications that use it. Kernel drivers operate in kernel space, which is a privileged mode of the processor that allows direct access to hardware and critical system resources.

#### Key Points:
- **Types of Drivers**: There are various types of drivers including character drivers, smmu drivers, network drivers, and more.
- **Role**: They manage hardware by sending commands to the device, handling interrupts, and transferring data between the hardware and user-space applications.
- **Modules**: Drivers can be built directly into the kernel or as loadable kernel modules, which can be dynamically loaded and unloaded as needed.

### Device Tree

The device tree is a data structure for describing hardware. It is used by the operating system to understand the hardware layout and configuration without hard-coding this information into the kernel. The device tree source (DTS) files are compiled into a binary format (DTB) that the kernel reads during boot time.

#### Key Points:
- **Structure**: It is a tree-like structure with nodes and properties that describe various hardware components and their configurations.
- **Portability**: It enhances the portability of the kernel by separating hardware description from the kernel code.
- **Usage**: Commonly used in embedded systems and ARM-based architectures.

### Relationship Between Kernel Drivers and Device Tree

The relationship between Linux kernel drivers and the device tree is crucial, especially in systems where the hardware configuration can vary significantly.

#### How They Interact:
1. **Initialization**: During the boot process, the kernel reads the device tree blob (DTB) to understand the hardware configuration.
2. **Binding**: The kernel uses information from the device tree to bind drivers to the corresponding hardware devices.
3. **Configuration**: Device-specific configurations, such as memory addresses, interrupts, and GPIO pins, are defined in the device tree and used by the drivers.

### Example

Consider a simple example of an I2C device:

1. **Device Tree Entry**:
    ```plaintext
    i2c@40005400 {
        compatible = "i2c-generic";
        reg = <0x40005400 0x400>;
        status = "okay";

        device@50 {
            compatible = "my-i2c-device";
            reg = <0x50>;
        };
    };
    ```

2. **Kernel Driver**:
    ```c
    static const struct of_device_id my_i2c_device_ids[] = {
        { .compatible = "my-i2c-device" },
        {},
    };
    MODULE_DEVICE_TABLE(of, my_i2c_device_ids);

    static struct i2c_driver my_i2c_driver = {
        .driver = {
            .name = "my_i2c_device",
            .of_match_table = my_i2c_device_ids,
        },
        .probe = my_i2c_probe,
        .remove = my_i2c_remove,
    };

    static int my_i2c_probe(struct i2c_client *client, const struct i2c_device_id *id) {
        // Initialize the device
    }

    static int my_i2c_remove(struct i2c_client *client) {
        // Clean up the device
    }

    module_i2c_driver(my_i2c_driver);
    ```

In this example:
- The device tree specifies an I2C device at address 0x50 on the I2C bus at address 0x40005400.
- The kernel driver defines a compatible string "my-i2c-device" which matches the device tree entry, allowing the kernel to bind the driver to this hardware.

### Conclusion

The Linux kernel driver and the device tree work together to enable the kernel to dynamically understand and interact with hardware. The device tree provides a flexible and portable way to describe hardware, while the kernel drivers utilize this information to manage and operate the hardware efficiently. This separation of concerns simplifies hardware configuration and enhances the portability of the kernel across different hardware platforms.



## Linux Kernel Driver Probe

In the Linux kernel, the probe function is a crucial part of the device driver framework. It is responsible for initializing and configuring a device when it is detected by the kernel. The probe function is called when a matching device is found by the kernel based on the device tree, ACPI, or other hardware enumeration mechanisms. Below is an overview of the probe process and the typical function execution order in a Linux kernel driver.

### Probe Process Overview

1. **Driver Registration**: The driver is registered with the kernel, and it provides a list of devices it supports.
2. **Device Detection**: The kernel detects devices during system initialization or hot-plug events.
3. **Device Matching**: The kernel matches detected devices with registered drivers.
4. **Probe Function Execution**: The probe function of the matching driver is called to initialize and configure the device.

### Function Execution Order

1. **Module Initialization Function**: The driver's module initialization function is called when the driver is loaded. This function typically registers the driver with the kernel using functions like `module_init()`, `platform_driver_register()`, `i2c_add_driver()`, etc.

    ```c
    static int __init my_driver_init(void) {
        return platform_driver_register(&my_platform_driver);
    }
    module_init(my_driver_init);
    ```

2. **Driver Registration Function**: This function registers the driver with the kernel and provides a list of supported devices. The driver structure usually includes pointers to the probe, remove, and other relevant functions.

    ```c
    static struct platform_driver my_platform_driver = {
        .probe = my_probe,
        .remove = my_remove,
        .driver = {
            .name = "my_device",
            .owner = THIS_MODULE,
            .of_match_table = my_of_match,
        },
    };
    ```

3. **Device Detection**: The kernel detects devices either at boot time or when devices are hot-plugged. The device detection mechanism depends on the platform (e.g., device tree, ACPI, PCI, etc.).

4. **Device Matching**: The kernel matches detected devices with registered drivers based on the device ID, compatible string, or other criteria specified in the driver's `of_match_table`, `pci_device_id`, etc.

    ```c
    static const struct of_device_id my_of_match[] = {
        { .compatible = "myvendor,mydevice", },
        {},
    };
    MODULE_DEVICE_TABLE(of, my_of_match);
    ```

5. **Probe Function**: When a match is found, the kernel calls the driver's probe function. The probe function performs device-specific initialization, such as setting up hardware registers, allocating resources, and registering device nodes.

    ```c
    static int my_probe(struct platform_device *pdev) {
        // Initialize the device
        struct resource *res;
        void __iomem *base;

        // Request and map I/O memory
        res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
        if (!res) {
            dev_err(&pdev->dev, "Failed to get I/O memory\n");
            return -ENODEV;
        }

        base = devm_ioremap_resource(&pdev->dev, res);
        if (IS_ERR(base)) {
            dev_err(&pdev->dev, "Failed to map I/O memory\n");
            return PTR_ERR(base);
        }

        // Additional initialization code

        dev_info(&pdev->dev, "Device initialized successfully\n");
        return 0;
    }
    ```

### Summary of the Probe Function Execution Order

1. **Driver module initialization function** (`module_init()`):
   - Registers the driver with the kernel.

2. **Kernel detects devices**:
   - Devices are detected during boot or hot-plug events.

3. **Kernel matches devices with drivers**:
   - Based on device IDs, compatible strings, etc.

4. **Driver's probe function** (`my_probe()`):
   - Initializes and configures the device.

5. **Device ready for use**:
   - The device is now initialized and ready for interaction with the system.

By following these steps, the probe function ensures that devices are properly initialized and ready for use by the rest of the system. The exact implementation details can vary depending on the type of device and the bus it is connected to (e.g., platform devices, PCI, I2C, etc.).

## Linux Kernel Driver Examples

### Built-in Driver && Loadable Modules Driver

In the kernel configuration file (`.config`), a built-in driver might be set as follows:
```plaintext
CONFIG_E2000=y
```

Loadable kernel modules (LKMs) are drivers that can be dynamically loaded and unloaded from the kernel at runtime using commands such as `insmod` and `rmmod`. These modules are separate from the main kernel image. This allows the driver to be loaded later as needed:
```plaintext
CONFIG_E1000=m
```

The module can then be loaded and unloaded using:
```sh
sudo modprobe e1000
sudo rmmod e1000
```

### `module_param` in Linux

In Linux, `module_param` is a macro used for defining parameters that can be passed to a loadable kernel module at the time of loading. These parameters allow for greater flexibility and configurability of the module without the need for recompilation, can be modified via the command line when the module is loaded using `insmod` or through `/sys/module/<module_name>/parameters`. Parameters can be of various data types such as integers, strings, or booleans.

#### Syntax

```c
module_param(name, type, perm);
```

- **name**: The name of the parameter.
- **type**: The data type of the parameter (e.g., `int`, `charp`, `bool`).
- **perm**: The file permissions for the parameter in `/sys/module`.

Here is an example of a simple kernel module that uses `module_param` to accept an integer.

```c
int enable_xxx_interface = 0;
module_param(enable_xxx_interface, int, S_IRUGO);
MODULE_PARM_DESC(enable_xxx_interface, "xxx_interface use 0 (disable), 1 (enable)");
```

```sh
sudo insmod example.ko enable_xxx_interface=1
# or
sudo modprobe example_driver enable_xxx_interface=1
```

### `param` from dts

Here is an example of a variable config param get from device tree source property.

```c
static int drv0_probe(struct platform_device *pdev) {
    int enable_iommu_config = 0;
    struct device_node *node = dev_of_node(&pdev->dev);
    if (!node) {
        return -ENODEV;
    }
    struct device_node *node_iommu = of_parse_phandle(node, "iommus", 0);
    if (node_iommu) {
        const char *status = of_get_property(node_iommu, "status", NULL);
        if (!status || strcmp(status, "okay") == 0) {
            enable_iommu_config = 1;
        }
        of_node_put(node_iommu);
    }

    // here "of_node_put" is coresponding to "of_parse_phandle"
}
```