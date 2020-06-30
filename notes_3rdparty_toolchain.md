
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
