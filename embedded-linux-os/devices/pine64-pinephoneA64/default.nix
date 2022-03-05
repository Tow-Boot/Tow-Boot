{ config, lib, pkgs, ... }:

{
  device = {
    name = "pine64/pinephone";
    dtbFiles = [
      "allwinner/sun50i-a64-pinephone-1.0.dtb"
      "allwinner/sun50i-a64-pinephone-1.1.dtb"
      "allwinner/sun50i-a64-pinephone-1.2.dtb"
    ];
  };

  hardware = {
    cpu = "allwinner-a64";
  };

  wip.kernel.package = pkgs.callPackage ./kernel {};
  wip.kernel.defconfig = pkgs.writeText "empty" "";

  boot.cmdline = [
    "console=ttyS0,115200n8"
    "earlycon=uart,mmio32,0x01c28000"
  ];

  wip.kernel = {
    structuredConfig = lib.mkMerge [
      # Slim down config somewhat
      # TODO: move into more general options
      (with lib.kernel; {
        NETFILTER = no;
        BPFILTER = no;
        USB_NET_DRIVERS = no;
        WIRELESS = no;
        WIREGUARD = no;
        BT = no;
        WLAN = no;
        NETDEVICES = no;
        INET = no; # No TCP/IP networking
        ETHTOOL_NETLINK = no;
        SERIO = no;
        LEGACY_PTYS = no;
        EFI = no;
        HW_RANDOM = no;
        HWMON = no;
      })

      (with lib.kernel; {
        SYSVIPC = yes;
        POSIX_MQUEUE = yes;
        NO_HZ = yes;
        HIGH_RES_TIMERS = yes;
        PREEMPT_VOLUNTARY = yes;

        # XXX move into celun as an option for "tiny"
        CC_OPTIMIZE_FOR_SIZE = yes;

        ARCH_SUNXI = yes;
        NR_CPUS = freeform "4";
        COMPAT = yes;

        ARCH_RANDOM = no;
        ARM64_AMU_EXTN = no;
        ARM64_BTI = no;
        ARM64_CNP = no;
        ARM64_E0PD = no;
        ARM64_ERRATUM_1024718 = no;
        ARM64_ERRATUM_1165522 = no;
        ARM64_ERRATUM_1286807 = no;
        ARM64_ERRATUM_1319367 = no;
        ARM64_ERRATUM_1418040 = no;
        ARM64_ERRATUM_1463225 = no;
        ARM64_ERRATUM_1530923 = no;
        ARM64_ERRATUM_1542419 = no;
        ARM64_ERRATUM_832075 = no;
        ARM64_ERRATUM_858921 = no;
        ARM64_HW_AFDBM = no;
        ARM64_PAN = no;
        ARM64_PTR_AUTH = no;
        ARM64_RAS_EXTN = no;
        ARM64_SVE = no;
        ARM64_USE_LSE_ATOMICS = no;
        CAVIUM_ERRATUM_22375 = no;
        CAVIUM_ERRATUM_23154 = no;
        CAVIUM_ERRATUM_27456 = no;
        CAVIUM_ERRATUM_30115 = no;
        CAVIUM_TX2_ERRATUM_219 = no;
        FUJITSU_ERRATUM_010001 = no;
        HISILICON_ERRATUM_161010101 = no;
        HISILICON_ERRATUM_161600802 = no;
        QCOM_FALKOR_ERRATUM_1003 = no;
        QCOM_FALKOR_ERRATUM_1009 = no;
        QCOM_FALKOR_ERRATUM_E1041 = no;
        QCOM_QDF2400_ERRATUM_0065 = no;
        SOCIONEXT_SYNQUACER_PREITS = no;

        ENERGY_MODEL = yes;
        CPU_IDLE = yes;
        CPU_IDLE_GOV_LADDER = yes;
        ARM_CPUIDLE = yes;
        ARM_PSCI_CPUIDLE = yes;

        CPU_FREQ = yes;
        CPU_FREQ_STAT = yes;
        CPU_FREQ_DEFAULT_GOV_POWERSAVE = yes;
        CPU_FREQ_GOV_POWERSAVE = yes;
        CPU_FREQ_GOV_USERSPACE = yes;
        CPU_FREQ_GOV_ONDEMAND = yes;
        CPU_FREQ_GOV_CONSERVATIVE = yes;
        CPU_FREQ_GOV_SCHEDUTIL = yes;
        CPUFREQ_DT = yes;

        JUMP_LABEL = yes;
        STACKPROTECTOR = no;
        GCC_PLUGINS = no;

        CMA = yes;
        CMA_DEBUGFS = yes;

        ZPOOL = yes;
        ZBUD = yes;
        Z3FOLD = yes;
        ZSMALLOC = yes;

        NET = yes;
        PACKET = yes;
        PACKET_DIAG = yes;
        UNIX = yes;
        UNIX_DIAG = yes;

        WIRELESS = no;
        RFKILL = yes;
        RFKILL_GPIO = yes;
        MODEM_POWER = yes;

        ARM_SCPI_PROTOCOL = yes;
        ARM_SMCCC_SOC_ID = no;

        INPUT_MOUSEDEV = yes;
        INPUT_MOUSEDEV_PSAUX = yes;
        INPUT_EVDEV = yes;

        KEYBOARD_GPIO = yes;
        KEYBOARD_GPIO_POLLED = yes;
        KEYBOARD_SUN4I_LRADC = yes;

        INPUT_TOUCHSCREEN = yes;
        TOUCHSCREEN_GOODIX = yes;

        INPUT_MISC = yes;
        INPUT_AXP20X_PEK = yes;

        INPUT_GPIO_VIBRA = yes;

        SERIAL_8250 = yes;
        SERIAL_8250_DEPRECATED_OPTIONS = no;
        SERIAL_8250_CONSOLE = yes;
        SERIAL_8250_NR_UARTS = freeform "8";
        SERIAL_8250_RUNTIME_UARTS = freeform "8";
        SERIAL_8250_DW = yes;
        SERIAL_OF_PLATFORM = yes;
        SERIAL_DEV_BUS = yes;

        I2C_CHARDEV = yes;
        I2C_GPIO = yes;
        I2C_MV64XXX = yes;

        PINCTRL_AXP209 = yes;
        PINCTRL_SINGLE = yes;
        PINCTRL_SUN8I_H3_R = no;
        PINCTRL_SUN50I_H5 = no;
        PINCTRL_SUN50I_H6 = no;
        PINCTRL_SUN50I_H6_R = no;
        PINCTRL_SUN50I_H616 = no;
        PINCTRL_SUN50I_H616_R = no;

        NVMEM_REBOOT_MODE = yes;

        CHARGER_AXP20X = yes;
        BATTERY_AXP20X = yes;
        AXP20X_POWER = yes;

        THERMAL = yes;
        THERMAL_STATISTICS = yes;
        THERMAL_WRITABLE_TRIPS = yes;
        THERMAL_GOV_FAIR_SHARE = yes;
        THERMAL_GOV_BANG_BANG = yes;
        CPU_THERMAL = yes;
        SUN8I_THERMAL = yes;

        WATCHDOG = yes;
        SUNXI_WATCHDOG = yes;

        MFD_SUN4I_GPADC = yes;
        MFD_AXP20X_RSB = yes;
        MFD_SYSCON = yes;

        REGULATOR = yes;
        REGULATOR_FIXED_VOLTAGE = yes;
        REGULATOR_AXP20X = yes;
        REGULATOR_GPIO = yes;

        DRM = yes;
        DRM_LOAD_EDID_FIRMWARE = no;
        DRM_SUN4I = yes;
        DRM_SUN4I_HDMI = no;
        DRM_SUN4I_BACKEND = no;
        DRM_SUN6I_DSI = yes;
        DRM_SUN8I_DW_HDMI = yes; # Needed even if we don't use HDMI
        DRM_SUN8I_MIXER = yes;
        DRM_PANEL_SITRONIX_ST7703 = yes;
        DRM_DW_HDMI_CEC = yes;
        DRM_LIMA = yes;
        FB = yes;
        FB_SIMPLE = yes;
        BACKLIGHT_CLASS_DEVICE = yes;
        BACKLIGHT_PWM = yes;
        FRAMEBUFFER_CONSOLE_ROTATION = yes;

        #LOGO = yes;
        LOGO = no; # XXX

        MMC = yes;
        MMC_SUNXI = yes;

        NEW_LEDS = yes;
        LEDS_CLASS = yes;
        LEDS_GPIO = yes;

        RTC_CLASS = yes;
        RTC_INTF_PROC = no;
        RTC_DRV_SUN6I = yes;

        DMADEVICES = yes;
        DMA_SUN6I = yes;
        DMABUF_HEAPS = yes;
        DMABUF_HEAPS_SYSTEM = yes;
        DMABUF_HEAPS_CMA = yes;

        CLK_SUNXI_PRCM_SUN9I = no;
        SUN50I_H6_CCU = no;
        SUN50I_H616_CCU = no;
        SUN50I_H6_R_CCU = no;
        SUN8I_H3_CCU = no;

        MAILBOX = yes;
        IOMMU_SUPPORT = yes;
        IOMMU_IO_PGTABLE_LPAE = yes;

        DEVFREQ_GOV_PERFORMANCE = yes;
        DEVFREQ_GOV_POWERSAVE = yes;
        DEVFREQ_GOV_USERSPACE = yes;
        DEVFREQ_GOV_PASSIVE = yes;
        ARM_SUN8I_MBUS_DEVFREQ = yes;
        PM_DEVFREQ_EVENT = yes;

        IIO = yes;
        IIO_BUFFER_CB = yes;
        IIO_BUFFER_HW_CONSUMER = yes;
        IIO_SW_DEVICE = yes;
        IIO_SW_TRIGGER = yes;

        AXP20X_ADC = yes;

        INV_MPU6050_I2C = yes;
        STK3310 = yes;
        IIO_ST_MAGN_3AXIS = yes;
        IIO_HRTIMER_TRIGGER = yes;
        IIO_INTERRUPT_TRIGGER = yes;
        IIO_SYSFS_TRIGGER = yes;

        PWM = yes;
        PWM_SUN4I = yes;

        ARM_CCI5xx_PMU = no;
        NVMEM_SUNXI_SID = yes;

        DMA_CMA = yes;
        CMA_SIZE_MBYTES = freeform "64";

        PRINTK_TIME = yes;
        CONSOLE_LOGLEVEL_DEFAULT = freeform "3";

        FRAME_WARN = freeform "1024";

        MAGIC_SYSRQ = yes;

        DEBUG_FS = yes;

        STACKTRACE = yes;
      })


      # Disabling generally unneeded things
      (with lib.kernel; {
        MEDIA_SUBDRV_AUTOSELECT = no;
        NETWORK_FILESYSTEMS = no;
        RAID6_PQ_BENCHMARK = no;
        RUNTIME_TESTING_MENU = no;
        STRICT_DEVMEM = no;
        VHOST_MENU = no;
        VIRTIO_MENU = no;

        HID_A4TECH = no;
        HID_APPLE = no;
        HID_BELKIN = no;
        HID_CHERRY = no;
        HID_CHICONY = no;
        HID_CYPRESS = no;
        HID_EZKEY = no;
        HID_ITE = no;
        HID_KENSINGTON = no;
        HID_LOGITECH = no;
        HID_REDRAGON = no;
        HID_MICROSOFT = no;
        HID_MONTEREY = no;
        INPUT_MOUSE = no;
        KEYBOARD_ATKBD = no;
      })

      (with lib.kernel; {
        EXPERT = no;
        EMBEDDED = no;
      })

      # USB
      (with lib.kernel; {
        USB_HIDDEV = yes;
        USB = yes;
        USB_OTG = yes;
        USB_OTG_FSM = yes;
        USB_MON = yes;
        USB_EHCI_HCD = yes;
        USB_EHCI_HCD_PLATFORM = yes;
        USB_OHCI_HCD = yes;
        USB_OHCI_HCD_PLATFORM = yes;
        USB_ACM = yes;
        USBIP_CORE = yes;
        USBIP_VHCI_HCD = yes;
        USBIP_HOST = yes;
        USB_MUSB_HDRC = yes;
        USB_MUSB_SUNXI = yes;
        MUSB_PIO_ONLY = yes;
        USB_SERIAL = yes;
        USB_SERIAL_SIMPLE = yes;
        USB_SERIAL_CH341 = yes;
        USB_SERIAL_CP210X = yes;
        USB_SERIAL_FTDI_SIO = yes;
        USB_SERIAL_QCAUX = yes;
        USB_SERIAL_QUALCOMM = yes;
        USB_SERIAL_OPTION = yes;
        NOP_USB_XCEIV = yes;

        PHY_SUN4I_USB = yes;

        TYPEC = yes;
        TYPEC_TCPM = yes;
        TYPEC_TCPCI = yes;
        TYPEC_UCSI = yes;
        TYPEC_ANX7688 = yes;
        TYPEC_DP_ALTMODE = yes;
      })
    ];
  };
}
