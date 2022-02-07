{ config, lib, ... }:

# TODO: implement this entirely as environment overrides.
# It is a planned feature, instead of patching the environment in C,
# the default environment will be manipulated through the modules system.

let
  inherit (lib)
    escapeShellArg
    mkIf
    mkMerge
    mkOption
    types
  ;
  cfg = config.Tow-Boot.phone-ux;

  inherit (cfg.wip)
    led_R
    led_G
    led_B
    mmcSD
    mmcEMMC
  ;

  setup_leds = lib.concatStringsSep " ; " [
    # Defaults to yellow~ish
    "led ${led_R} on"
    "led ${led_G} on"
    "led ${led_B} off"
  ];

  # Flashes the red LED a given number of time.
  # Leaves the LED on at the last flash.
  failure = times: lib.concatStringsSep " ; " [
    "led ${led_R} off"
    "led ${led_G} off"
    "led ${led_B} off"
    "for i in ${lib.concatStringsSep " " (lib.genList (x: toString x) times)}; do"
    "  vibrator vibrator timed 250"
    "  led ${led_R} off"
    "  sleep 0.25"
    "  led ${led_R} on"
    "done"
  ];

  nokb_form_factor_bootcmd = lib.concatStringsSep " ; " [
    # Ensure red LED at start of bootcmd...
    # It may happen that some platforms are harder than necessary to setup initially.
    "led ${led_R} on"
    "led ${led_G} off"
    "led ${led_B} off"

    # Vibrate a bit
    "vibrator vibrator timed 200"
    "sleep 0.1"
    "vibrator vibrator timed 200"

    "if button 'Volume Up'; then"
    #  blue -> TDM
    "  led ${led_R} off"
    "  led ${led_G} off"
    "  led ${led_B} on"
    "  ums 0 mmc ${mmcEMMC}" # for now export the eMMC using `ums`
    #  Keep default LED state on a bit longer...
    "  sleep 1"
    #  If boot failed failed
    (failure 4)
    "fi"
    "if button 'Volume Down'; then"
    #  aqua -> sd card
    "  led ${led_R} off"
    "  led ${led_G} on"
    "  led ${led_B} on"
    "  run bootcmd_mmc${mmcSD}"
    #  Keep default LED state on a bit longer...
    "  sleep 1"
    (failure 4)
    "fi"

    # Setup yellow~ish LED, as usual
    "run setup_leds"

    # Normal boot flow follows...
    "run distro_bootcmd"

    "echo"
    "echo ERROR: Could not boot anything from distro_bootcmd."
    "echo"

    # Keep default "working" LED state on a bit longer...
    "sleep 1"
    # Announce failure
    (failure 10)
    "sleep 0.25"

    # Power off device. No sense in staying on.
    # Users with UART can ^C at this point if needed.
    "poweroff"
    # (This is subject to change once display is used by Tow-Boot)
  ];
in
{
  options = {
    Tow-Boot = {
      phone-ux = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Whether to enable the user experience built for
            keyboard-less devices.

            Generally tablets or phones, with a limited set
            of inputs (Volume up/Volume down/Power).
          '';
        };
        blind = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Whether to build "Phone UX" for devices where the
            display is not supported.
          '';
        };
        # This is temporary, until I think about better semantics.
        # We cannot assume RGB LEDs, and can't assume mmc+SD
        # **Anyway** this sort of hardware description is required for better
        # semantics for `setup_leds` and such in the customized boot flow.
        wip = {
          led_R = mkOption {
            type = types.str;
            internal = true;
          };
          led_G = mkOption {
            type = types.str;
            internal = true;
          };
          led_B = mkOption {
            type = types.str;
            internal = true;
          };
          mmcEMMC = mkOption {
            type = types.str;
            internal = true;
          };
          mmcSD = mkOption {
            type = types.str;
            internal = true;
          };
        };
      };
    };
  };

  config = mkMerge [
    (mkIf (cfg.enable) {
      Tow-Boot = {
        inherit setup_leds;
        builder.postPatch = ''
          substituteInPlace include/tow-boot_env.h \
            --replace \
              'bootcmd=run setup_leds; run distro_bootcmd\0' \
              'bootcmd='${escapeShellArg nokb_form_factor_bootcmd}'\0'

          substituteInPlace drivers/usb/gadget/g_dnl.c \
            --replace "USB download gadget" "${config.device.name}"
        '';
        config = [
          (helpers: with helpers; {
            BUTTON = yes;
            CMD_BUTTON = yes;
          })
          (helpers: with helpers; {
            LED = yes;
            CMD_LED = yes;
          })
          (helpers: with helpers; {
            VIBRATOR = yes;
            CMD_VIBRATOR = yes;
          })
          (helpers: with helpers; {
            USB_GADGET = yes;
            USB_GADGET_DOWNLOAD = yes;
            CMD_USB_MASS_STORAGE = yes;
          })
        ];
        patches = [
          # Vibrator support
          ./phone-ux/0001-add-vibrator-and-gpio-vibrator.patch
        ];
      };
    })
    (mkIf (cfg.enable && cfg.blind) {
      Tow-Boot = {
        config = [
          (helpers: with helpers; {
            # Remove the useless delay from boot.
            # With blind UX, the user will already be holding
            # the buttons to trigger an action.
            BOOTDELAY = lib.mkForce (freeform "0");
          })
        ];
      };
    })
  ];
}
