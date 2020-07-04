
~/src/oss/meta-linaro/meta-linaro-toolchain/conf/distro/include/tcmode-external-linaro.inc


https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18842224/Getting+started+with+Yocto+Xilinx+layer
https://github.com/Xilinx/meta-linaro/tree/rel-v2020.1

https://www.yoctoproject.org/pipermail/yocto/2013-June/014599.html

https://github.com/MentorEmbedded/meta-external-toolchain
https://github.com/MentorEmbedded/meta-sourcery (newer I think)

ugh..

```diff
diff --git a/meta-linaro-toolchain/conf/distro/include/external-linaro-toolchain-versions.inc b/meta-linaro-toolchain/conf/distro/include/external-linaro-toolchain-versions.inc
index 2a99209..bdec4f2 100644
--- a/meta-linaro-toolchain/conf/distro/include/external-linaro-toolchain-versions.inc
+++ b/meta-linaro-toolchain/conf/distro/include/external-linaro-toolchain-versions.inc
@@ -28,6 +28,9 @@ def elt_get_main_version(d):
        version = elt_get_version(d)
        bb.debug(2, 'Trying for parse version info from: %s' % version)
        if version != 'UNKNOWN':
+               if version.split()[3] == '(Linaro':
+                       # gcc version 5.1.1 20150608 (Linaro GCC 5.1-2015.08)
+                       return version.split()[5].split('-')[1].split(')')[0]
                if version.split()[4] == '(Linaro':
                        # gcc version 5.1.1 20150608 (Linaro GCC 5.1-2015.08)
                        return version.split()[6].split('-')[1].split(')')[0]
```

now..

```
bitbake -c populate_sdk rpi-test-image
```

(iirc it fails even without `populate_sdk`)

```
ERROR: external-linaro-toolchain-2019.12-r0 do_install: oe_multilib_header: Unable to find header bits/floatn.h.
```

https://www.yoctoproject.org/pipermail/yocto/2019-January/043747.html
https://www.openembedded.org/pipermail/openembedded-core/2018-April/268495.html
https://www.openembedded.org/pipermail/openembedded-core/2018-April/268496.html
https://lists.linaro.org/pipermail/openembedded/2017-June/000092.html

tl;dr likely an issue of glibc mismatches.

also..

```
bitbake external-linaro-toolchain
```

```
ERROR: external-linaro-toolchain-2017.11-r0 do_populate_lic: QA Issue: external-linaro-toolchain: The LIC_FILES_CHKSUM does not match for file:///home/jon/src/jmagnuson/yocto/rpi0/layers/poky/LICENSE;md5=4d92cd373abda3937c2bc47fbc49d690
external-linaro-toolchain: The new md5 checksum is b97a012949927931feb7793eee5ed924
external-linaro-toolchain: Here is the selected license text:
vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
Different components of OpenEmbedded are under different licenses (a mix
of MIT and GPLv2). See LICENSE.GPL-2.0-only and LICENSE.MIT for further
details of the individual licenses.
```

now set up with meta-arm-toolchain, but..

```
Exception: FileExistsError: [Errno 17] File exists: '/home/jon/src/jmagnuson/yocto/rpi0/build/tmp/sysroots-components/arm1176jzfshf-vfp/external-arm-toolchain/sysroot-providers/linux-libc-headers' -> '/home/jon/src/jmagnuson/yocto/rpi0/build/tmp/work/arm1176jzfshf-vfp-poky-linux-gnueabi/opkg-utils/0.4.2-r0/recipe-sysroot/sysroot-providers/linux-libc-headers'

ERROR: Logfile of failure stored in: /home/jon/src/jmagnuson/yocto/rpi0/build/tmp/work/arm1176jzfshf-vfp-poky-linux-gnueabi/opkg-utils/0.4.2-r0/temp/log.do_prepare_recipe_sysroot.29597
ERROR: Task (/home/jon/src/jmagnuson/yocto/rpi0/layers/poky/meta/recipes-devtools/opkg-utils/opkg-utils_0.4.2.bb:do_prepare_recipe_sysroot) failed with exit code '1'
ERROR: Task (/home/jon/src/jmagnuson/yocto/rpi0/layers/poky/meta/recipes-core/zlib/zlib_1.2.11.bb:do_prepare_recipe_sysroot) failed with exit code '1'
```

tried doing populate_sdk, cleanall, then populate_sdk again...

```
ERROR: external-arm-toolchain-2019.12-r0 do_packagedata_setscene: The recipe external-arm-toolchain is trying to install files into a shared area when those files already exist. Those files and their manifest location are:
  /home/jon/src/jmagnuson/yocto/rpi0/build/tmp/pkgdata/raspberrypi0-wifi/runtime/linux-libc-headers
    (matched in manifest-raspberrypi0_wifi-linux-libc-headers.packagedata)
  /home/jon/src/jmagnuson/yocto/rpi0/build/tmp/pkgdata/raspberrypi0-wifi/runtime/linux-libc-headers-dev.packaged
    (matched in manifest-raspberrypi0_wifi-linux-libc-headers.packagedata)
  /home/jon/src/jmagnuson/yocto/rpi0/build/tmp/pkgdata/raspberrypi0-wifi/runtime/linux-libc-headers-dev
    (matched in manifest-raspberrypi0_wifi-linux-libc-headers.packagedata)
Please verify which recipe should provide the above files.
```

i'm thinking maybe it's just because I have artifacts from non-external toolchain build? maybe wipe out build?

why is everything the worst...

```
ERROR: zlib-1.2.11-r0 do_configure: Execution of '/home/jon/src/jmagnuson/yocto/rpi0/build/tmp/work/arm1176jzfshf-vfp-poky-linux-gnueabi/zlib/1.2.11-r0/temp/run.do_configure.15425' failed with exit code 1:
Compiler error reporting is too harsh for ./configure (perhaps remove -Werror).
** ./configure aborting.
WARNING: /home/jon/src/jmagnuson/yocto/rpi0/build/tmp/work/arm1176jzfshf-vfp-poky-linux-gnueabi/zlib/1.2.11-r0/temp/run.do_configure.15425:1 exit 1 from 'LDCONFIG=true ./configure --prefix=/usr --shared --libdir=/usr/lib --uname=GNU'
```

https://stackoverflow.com/a/28002818

oh shit, probably not in `PATH`.

```
jon@r4 ~/src/jmagnuson/yocto/rpi0/build $ echo $PATH
/home/jon/toolchains/gcc-arm-9.2-2019.12-x86_64-arm-none-linux-gnueabihf/bin:/home/jon/src/jmagnuson/yocto/rpi0/layers/poky/scripts:/home/jon/src/jmagnuson/yocto/rpi0/layers/poky/bitbake/bin:/home/jon/.cargo/bin:/home/jon/.local/bin:/home/jon/bin:/home/jon/bin/FlameGraph:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/bin:/usr/lib/llvm/9/bin
```

still no worky

trying to set `TCLIBC = "external-arm-toolchain"`:
```
ERROR: ParseError at /home/jon/src/jmagnuson/yocto/rpi0/layers/poky/meta/conf/distro/defaultsetup.conf:10: Could not include required file conf/distro/include/tclibc-external-arm-toolchain.inc
```

back to "error reporting is too harsh"--

https://github.com/maxdev1/ghost/issues/9#issuecomment-306334125

I think I saw this before and forgot/ignored it. this is probably the problem. where is `CC`?

I think this helped things (although is it even documented?):

in `conf/local.conf`:
```
# arm's target
EAT_TARGET_SYS = "arm-none-linux-gnueabihf"
EAT_TARGET_SYS_arm = "arm-none-linux-gnueabihf"
```

a little deeper, in
` ~/src/jmagnuson/yocto/rpi0/build/tmp/work/arm1176jzfshf-vfp-poky-linux-gnueabi/zlib/1.2.11-r0/zlib-1.2.11`:
```
--------------------
./configure --prefix=/usr --shared --libdir=/usr/lib --uname=GNU
Thu 02 Jul 2020 05:40:00 PM UTC
=== ztest17157.c ===
extern int getchar();
int hello() {return getchar();}
===
arm-none-linux-gnueabihf-gcc -march=armv6 -mfpu=vfp -mfloat-abi=hard -mtune=arm1176jzf-s -mfpu=vfp -fstack-protector-strong -D_FORTIFY_SOURCE=2 -Wformat -Wformat-security -Werror=format-security --sysroot=/home/jon/src/jmagnuson/yocto/rpi0/build/tmp/work/arm1176jzfshf-vfp-poky-linux-gnueabi/zlib/1.2.11-r0/recipe-sysroot -c ztest17157.c
ztest17157.c: In function ‘hello’:
ztest17157.c:2:1: sorry, unimplemented: Thumb-1 hard-float VFP ABI
    2 | int hello() {return getchar();}
      | ^~~
... using arm-none-linux-gnueabihf-gcc -march=armv6 -mfpu=vfp -mfloat-abi=hard -mtune=arm1176jzf-s -mfpu=vfp -fstack-protector-strong -D_FORTIFY_SOURCE=2 -Wformat -Wformat-security -Werror=format-security --sysroot=/home/jon/src/jmagnuson/yocto/rpi0/build/tmp/work/arm1176jzfshf-vfp-poky-linux-gnueabi/zlib/1.2.11-r0/recipe-sysroot

Checking for obsessive-compulsive compiler options...
=== ztest17157.c ===
int foo() { return 0; }
===
arm-none-linux-gnueabihf-gcc -march=armv6 -mfpu=vfp -mfloat-abi=hard -mtune=arm1176jzf-s -mfpu=vfp -fstack-protector-strong -D_FORTIFY_SOURCE=2 -Wformat -Wformat-security -Werror=format-security --sysroot=/home/jon/src/jmagnuson/yocto/rpi0/build/tmp/work/arm1176jzfshf-vfp-poky-linux-gnueabi/zlib/1.2.11-r0/recipe-sysroot -c -O2 -pipe -g -feliminate-unused-debug-types -fmacro-prefix-map=/home/jon/src/jmagnuson/yocto/rpi0/build/tmp/work/arm1176jzfshf-vfp-poky-linux-gnueabi/zlib/1.2.11-r0=/usr/src/debug/zlib/1.2.11-r0 -fdebug-prefix-map=/home/jon/src/jmagnuson/yocto/rpi0/build/tmp/work/arm1176jzfshf-vfp-poky-linux-gnueabi/zlib/1.2.11-r0=/usr/src/debug/zlib/1.2.11-r0 -fdebug-prefix-map=/home/jon/src/jmagnuson/yocto/rpi0/build/tmp/work/arm1176jzfshf-vfp-poky-linux-gnueabi/zlib/1.2.11-r0/recipe-sysroot= -fdebug-prefix-map=/home/jon/src/jmagnuson/yocto/rpi0/build/tmp/work/arm1176jzfshf-vfp-poky-linux-gnueabi/zlib/1.2.11-r0/recipe-sysroot-native= ztest17157.c
ztest17157.c: In function ‘foo’:
ztest17157.c:1:1: sorry, unimplemented: Thumb-1 hard-float VFP ABI
    1 | int foo() { return 0; }
      | ^~~
(exit code 1)
Compiler error reporting is too harsh for ./configure (perhaps remove -Werror).
** ./configure aborting.
--------------------
```

https://github.com/frida/frida/issues/311#issuecomment-320143326
>problem solved by replace "-march=armv6" to "-marm" in releng/setup-env.sh

https://stackoverflow.com/a/51201725
>The problem is that the maintainers of the Linaro toolchain specify ARMv7A as the minimum supported architecture. It makes cross-compiling for Raspberry Pi using the Debian cross-compiler packages rather hopeless, since various builtins will fail if you correctly configure your build for BCM2835 with -march=armv6z -mtune=arm1176jzf-s -mfpu=vfp -mfloat-abi=hard
>...
>and note that the former has --with-arch=armv6 --with-fpu=vfp --with-float=hard whereas the latter has --with-arch=armv7-a --with-fpu=vfpv3-d16 --with-float=hard This blog post provides one solution (basically using Clang and self-building the binutils):

```
jon@r4 ~/toolchains/gcc-arm-9.2-2019.12-x86_64-arm-none-linux-gnueabihf/bin $ ./arm-none-linux-gnueabihf-gcc -v
Using built-in specs.
COLLECT_GCC=./arm-none-linux-gnueabihf-gcc
COLLECT_LTO_WRAPPER=/home/jon/toolchains/gcc-arm-9.2-2019.12-x86_64-arm-none-linux-gnueabihf/bin/../libexec/gcc/arm-none-linux-gnueabihf/9.2.1/lto-wrapper
Target: arm-none-linux-gnueabihf
Configured with: /tmp/dgboter/bbs/rhev-vm7--rhe6x86_64/buildbot/rhe6x86_64--arm-none-linux-gnueabihf/build/src/gcc/configure --target=arm-none-linux-gnueabihf --prefix= --with-sysroot=/arm-none-linux-gnueabihf/libc --with-build-sysroot=/tmp/dgboter/bbs/rhev-vm7--rhe6x86_64/buildbot/rhe6x86_64--arm-none-linux-gnueabihf/build/build-arm-none-linux-gnueabihf/install//arm-none-linux-gnueabihf/libc --with-bugurl=https://bugs.linaro.org/ --enable-gnu-indirect-function --enable-shared --disable-libssp --disable-libmudflap --enable-checking=release --enable-languages=c,c++,fortran --with-gmp=/tmp/dgboter/bbs/rhev-vm7--rhe6x86_64/buildbot/rhe6x86_64--arm-none-linux-gnueabihf/build/build-arm-none-linux-gnueabihf/host-tools --with-mpfr=/tmp/dgboter/bbs/rhev-vm7--rhe6x86_64/buildbot/rhe6x86_64--arm-none-linux-gnueabihf/build/build-arm-none-linux-gnueabihf/host-tools --with-mpc=/tmp/dgboter/bbs/rhev-vm7--rhe6x86_64/buildbot/rhe6x86_64--arm-none-linux-gnueabihf/build/build-arm-none-linux-gnueabihf/host-tools --with-isl=/tmp/dgboter/bbs/rhev-vm7--rhe6x86_64/buildbot/rhe6x86_64--arm-none-linux-gnueabihf/build/build-arm-none-linux-gnueabihf/host-tools --with-arch=armv7-a --with-fpu=neon --with-float=hard --with-mode=thumb --with-arch=armv7-a --with-pkgversion='GNU Toolchain for the A-profile Architecture 9.2-2019.12 (arm-9.10)'
Thread model: posix
gcc version 9.2.1 20191025 (GNU Toolchain for the A-profile Architecture 9.2-2019.12 (arm-9.10))
```

tried setting `DEFAULTTUNE = "arm"` in local.conf but that didn't work.

BUT

setting the rpi0's tuning recipe to armv7 appears to have worked:
```diff
diff --git a/conf/machine/include/tune-arm1176jzf-s.inc b/conf/machine/include/tune-arm1176jzf-s.inc
index b6fcc59..3866a98 100644
--- a/conf/machine/include/tune-arm1176jzf-s.inc
+++ b/conf/machine/include/tune-arm1176jzf-s.inc
@@ -1,6 +1,6 @@
-DEFAULTTUNE ?= "armv6"
+DEFAULTTUNE ?= "armv7a"

-require conf/machine/include/arm/arch-armv6.inc
+require conf/machine/include/arm/arch-armv7a.inc

 TUNEVALID[arm1176jzfs] = "Enable arm1176jzfs specific processor optimizations"
 TUNE_CCARGS += "${@bb.utils.contains("TUNE_FEATURES", "arm1176jzfs", "-mtune=arm1176jzf-s", "", d)}"
@@ -9,7 +9,7 @@ TUNE_CCARGS += "${@bb.utils.contains("TUNE_FEATURES", "vfp", "-mfpu=vfp", "", d)
 AVAILTUNES += "arm1176jzfs arm1176jzfshf"
 ARMPKGARCH_tune-arm1176jzfs = "arm1176jzfs"
 ARMPKGARCH_tune-arm1176jzfshf = "arm1176jzfs"
-TUNE_FEATURES_tune-arm1176jzfs = "${TUNE_FEATURES_tune-armv6} arm1176jzfs"
+TUNE_FEATURES_tune-arm1176jzfs = "${TUNE_FEATURES_tune-armv7a} arm1176jzfs"
 TUNE_FEATURES_tune-arm1176jzfshf = "${TUNE_FEATURES_tune-arm1176jzfs} callconvention-hard"
-PACKAGE_EXTRA_ARCHS_tune-arm1176jzfs = "${PACKAGE_EXTRA_ARCHS_tune-armv6}"
-PACKAGE_EXTRA_ARCHS_tune-arm1176jzfshf = "${PACKAGE_EXTRA_ARCHS_tune-armv6hf} arm1176jzfshf-vfp"
+PACKAGE_EXTRA_ARCHS_tune-arm1176jzfs = "${PACKAGE_EXTRA_ARCHS_tune-armv7a}"
+PACKAGE_EXTRA_ARCHS_tune-arm1176jzfshf = "${PACKAGE_EXTRA_ARCHS_tune-armv7ahf} arm1176jzfshf-vfp"
```

