Serial console
==============

> **NOTE**: This document is a stub.

All platforms use the 115200 baud rate. Even platforms which generally default
to another serial baud rate have been configured for homogeneity.

The author personally uses `picocom` to access the serial console.

```shell-session
 $ picocom -b 115200
```
