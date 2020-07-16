0. https://medium.com/@shantanoodesai/run-docker-on-a-raspberry-pi-4-with-yocto-project-551d6b615c0b

1.
git clone -b zeus git://git.yoctoproject.org/meta-raspberrypi
git clone -b zeus git://git.yoctoproject.org/poky.git
git clone -b zeus git://git.openembedded.org/meta-openembedded
cd ..

```
jon@r4 ~/src/jmagnuson/yocto/rpi0/layers $ for dir in *; do (cd $dir; echo "****** $dir ******"; git remote -vv; git status); done
****** meta-openembedded ******
origin  git://git.openembedded.org/meta-openembedded (fetch)
origin  git://git.openembedded.org/meta-openembedded (push)
On branch zeus
Your branch is up to date with 'origin/zeus'.

nothing to commit, working tree clean
****** meta-raspberrypi ******
jmagnuson       git@github.com:jmagnuson/meta-raspberrypi (fetch)
jmagnuson       git@github.com:jmagnuson/meta-raspberrypi (push)
origin  git://git.yoctoproject.org/meta-raspberrypi (fetch)
origin  git://git.yoctoproject.org/meta-raspberrypi (push)
On branch zeus-nuke-wireless-regdb
nothing to commit, working tree clean
****** meta-virtualization ******
origin  git://git.yoctoproject.org/meta-virtualization (fetch)
origin  git://git.yoctoproject.org/meta-virtualization (push)
On branch zeus
Your branch is up to date with 'origin/zeus'.

nothing to commit, working tree clean
****** poky ******
origin  git://git.yoctoproject.org/poky.git (fetch)
origin  git://git.yoctoproject.org/poky.git (push)
On branch zeus
Your branch is up to date with 'origin/zeus'.

nothing to commit, working tree clean
```

source layers/poky/oe-init-build-env build

`add_layers.sh` failed with:

```
ERROR: Unable to start bitbake server (None)
ERROR: Server log for this session (/home/jon/src/jmagnuson/yocto/rpi0/build/bitbake-cookerdaemon.log):
--- Starting bitbake server pid 14196 at 2020-06-10 14:01:10.584848 ---
ERROR: The following required tools (as specified by HOSTTOOLS) appear to be unavailable in PATH, please install them in order to proceed:
  chrpath diffstat rpcgen
ERROR: The following required tools (as specified by HOSTTOOLS) appear to be unavailable in PATH, please install them in order to proceed:
  chrpath diffstat rpcgen
ERROR: The following required tools (as specified by HOSTTOOLS) appear to be unavailable in PATH, please install them in order to proceed:
  chrpath diffstat rpcgen
```


emerge --ask chrpath diffstat

emerge -av net-libs/rpcsvc-proto
https://archives.gentoo.org/gentoo-user/message/6d2b0b774716866468746dc06554043a
(glibc no longer has rpc use flag)


bitbake-layers add-layer ../layers/meta-openembedded/meta-networking
bitbake-layers add-layer ../layers/meta-openembedded/meta-python
bitbake-layers add-layer ../layers/meta-raspberrypi

all throw:

```
NOTE: Starting bitbake server...
Traceback (most recent call last):
  File "/home/jon/src/jmagnuson/yocto/rpi0/layers/poky/bitbake/bin/bitbake-layers", line 93, in <module>
    ret = main()
  File "/home/jon/src/jmagnuson/yocto/rpi0/layers/poky/bitbake/bin/bitbake-layers", line 61, in main
    tinfoil.prepare(True)
  File "/home/jon/src/jmagnuson/yocto/rpi0/layers/poky/bitbake/lib/bb/tinfoil.py", line 408, in prepare
    self.run_command('parseConfiguration')
  File "/home/jon/src/jmagnuson/yocto/rpi0/layers/poky/bitbake/lib/bb/tinfoil.py", line 466, in run_command
    raise TinfoilCommandFailed(result[1])
bb.tinfoil.TinfoilCommandFailed: Traceback (most recent call last):
  File "/home/jon/src/jmagnuson/yocto/rpi0/layers/poky/bitbake/lib/bb/command.py", line 74, in runCommand
    result = command_method(self, commandline)
  File "/home/jon/src/jmagnuson/yocto/rpi0/layers/poky/bitbake/lib/bb/command.py", line 275, in parseConfiguration
    command.cooker.parseConfiguration()
  File "/home/jon/src/jmagnuson/yocto/rpi0/layers/poky/bitbake/lib/bb/cooker.py", line 437, in parseConfiguration
    self.handleCollections(self.data.getVar("BBFILE_COLLECTIONS"))
  File "/home/jon/src/jmagnuson/yocto/rpi0/layers/poky/bitbake/lib/bb/cooker.py", line 1229, in handleCollections
    raise CollectionError("Errors during parsing layer configuration")
bb.cooker.CollectionError: Errors during parsing layer configuration
```


also `bitbake-layers show-layers`


sigh...
https://stackoverflow.com/questions/59127987/bitbake-layers-add-layer-meta-python-meta-raspberrypi-failed


SOLVED by reordering.. meta-networking and meta-multimedia come last for what ever reason



bitbake-layers add-layer ../layers/meta-virtualization

then

bitbake-layers add-layer ../layers/meta-openembedded/meta-filesystems


but FAILED again

reordered and they added fine

```
dd if=tmp/deploy/images/raspberrypi0-wifi/rpi-basic-image-raspberrypi0-wifi.rpi-sdimg of=/dev/sdg bs=4M

dd: failed to open '/dev/sdg': Read-only file system
```

SOLVED by unplugging and replugging (maybe mounting beforehand locked it into RO)

base worked, but has no wireless. uart works, but docker doesn't because no actual network iface

added
```
dtoverlay=dwc2,dr_mode=peripheral
```
to try to get OTG network iface, but no luck (needs more than that?)

instead tried
```
bitbake -k rpi-test-image
```
but

```
Error:
 Problem: package packagegroup-base-wifi-1.0-r83.raspberrypi0_wifi requires wireless-regdb-static, but none of the providers can be installed
  - package wireless-regdb-2020.04.29-r0.noarch conflicts with wireless-regdb-static provided by wireless-regdb-static-2020.04.29-r0.noarch
  - package packagegroup-base-1.0-r83.raspberrypi0_wifi requires packagegroup-base-wifi, but none of the providers can be installed
  - package packagegroup-rpi-test-1.0-r0.noarch requires wireless-regdb, but none of the providers can be installed
  - package packagegroup-base-extended-1.0-r83.raspberrypi0_wifi requires packagegroup-base, but none of the providers can be installed
  - conflicting requests
```

more layers??

no,
https://github.com/agherzan/meta-raspberrypi/issues/456#issuecomment-516575318
recipes-core/packagegroups/packagegroup-rpi-test.bb

calls out `wireless-regdb`, try replacing with `wireless-regdb-static`.

WORKS

now docker run hello-world doesn't seem to output what i would expect. try running ubuntu container?

/etc/init.d/docker.init is scuffed, so replace with line:
```
"$unshare" -m -- $exec $other_args >>$logfile 2>&1 &
```

arm32v5/hello-world worked (rpi0w is v6, but not available)

also, what i may end up targetting:
```
docker run -it arm32v6/alpine sh
```

Picking back up on docker stuff...
trying out layer `meta-gnss-sdr` since it has an example docker image type.

required layers/submodules:
```
[submodule "layers/meta-gnss-sdr"]
        path = layers/meta-gnss-sdr
        url = https://github.com/carlesfernandez/meta-gnss-sdr
        branch = zeus
[submodule "layers/meta-docker"]
        path = layers/meta-docker
        url = https://github.com/L4B-Software/meta-docker
[submodule "layers/meta-sdr"]
        path = layers/meta-sdr
        url = git://github.com/balister/meta-sdr.git
        branch = zeus
[submodule "layers/meta-qt5"]
        path = layers/meta-qt5
        url = git://github.com/meta-qt5/meta-qt5.git
        branch = zeus
```

`meta-sdr` said to use `meta-qt4` in the upstream yocto git, but I think that's
just out of date.

still complaining about missing libgfortran though:
```
ERROR: Nothing RPROVIDES 'libgfortran' (but /home/jon/src/jmagnuson/yocto/rpi0/layers/meta-gnss-sdr/recipes-images/packagegroups/packagegroup-gnss-sdr.bb RDEPENDS on or otherwise requires it)
libgfortran was skipped: libgfortran needs fortran support to be enabled in the compiler
NOTE: Runtime target 'libgfortran' is unbuildable, removing...
Missing or unbuildable dependency chain was: ['libgfortran']
NOTE: Runtime target 'packagegroup-gnss-sdr-buildessential' is unbuildable, removing...
Missing or unbuildable dependency chain was: ['packagegroup-gnss-sdr-buildessential', 'libgfortran']
ERROR: Required build target 'gnss-sdr-dev-docker' has no buildable providers.
Missing or unbuildable dependency chain was: ['gnss-sdr-dev-docker', 'packagegroup-gnss-sdr-buildessential', 'libgfortran']
```
hmm, should be provided by `poky/meta`..

in `meta-gnss-sdr/conf/conf.local`:
```
FORTRAN_forcevariable = ",fortran"
```
now it's building.

ugh, QA bullshit
```
ERROR: gnss-sdr-monitor-1.0.git-r0 do_package: QA Issue: gnss-sdr-monitor: Files/directories were installed but not shipped in any package:
  /usr/bin/.debug
    /usr/bin/.debug/gnss-sdr-monitor
    Please set FILES such that these items are packaged. Alternatively if they are unneeded, avoid installing them or delete them within do_install.
    gnss-sdr-monitor: 2 installed and not shipped files. [installed-vs-shipped]
    ERROR: gnss-sdr-monitor-1.0.git-r0 do_package: Fatal QA errors found, failing task.
    ERROR: Logfile of failure stored in: /home/jon/src/jmagnuson/yocto/rpi0/build/tmp/work/arm1176jzfshf-vfp-poky-linux-gnueabi/gnss-sdr-monitor/1.0.git-r0/temp/log.do_package.8403
    ERROR: Task (/home/jon/src/jmagnuson/yocto/rpi0/layers/meta-gnss-sdr/recipes-core/gnss-sdr-monitor/gnss-sdr-monitor_git.bb:do_package) failed with exit code '1'
    NOTE: Tasks Summary: Attempted 6706 tasks of which 1414 didn't need to be rerun and 1 failed.
```

tried:
```
FILES_${PN}-dbg += "\
  ${exec_prefix}/src/debug/* \
"
```

but I think something is missing from that approach, can't remember.
```
INHIBIT_PACKAGE_DEBUG_SPLIT = "1"
```
works though.

needs python package..
```
| -- Python checking for six - python 2 and 3 compatibility library - not found
| -- python-six not found. See https://pythonhosted.org/six/
| --  You can try to install it by typing:
| --  sudo apt-get install python-six
| CMake Error at CMakeLists.txt:924 (message):
|   six - python 2 and 3 compatibility library required to build VOLK_GNSSSDR
```

```
jon@r4 ~/src/jmagnuson/yocto/rpi0/build/tmp/work $ pip install --user six
Requirement already satisfied: six in /home/jon/.local/lib/python3.7/site-packages (1.14.0)
jon@r4 ~/src/jmagnuson/yocto/rpi0/build/tmp/work $ pip2 install --user six
DEPRECATION: Python 2.7 reached the end of its life on January 1st, 2020. Please upgrade your Python as Python 2.7 is no longer maintained. A future version of pip will drop support for Python 2.7. More details about Python 2 support in pip, can be found at https://pip.pypa.io/en/latest/development/release-process/#python-2-support
Collecting six
  Downloading six-1.15.0-py2.py3-none-any.whl (10 kB)
Installing collected packages: six
Successfully installed six-1.15.0
```
works now.

more QA nonsense
```
ERROR: gnss-sdr-0.0.12.git-r0 do_package: QA Issue: File '/usr/bin/volk_gnsssdr-config-info' from gnss-sdr was already stripped, this will prevent future debugging! [already-stripped]
ERROR: gnss-sdr-0.0.12.git-r0 do_package: QA Issue: File '/usr/bin/volk_gnsssdr_profile' from gnss-sdr was already stripped, this will prevent future debugging! [already-stripped]
ERROR: gnss-sdr-0.0.12.git-r0 do_package: Fatal QA errors found, failing task.
ERROR: Logfile of failure stored in: /home/jon/src/jmagnuson/yocto/rpi0/build/tmp/work/arm1176jzfshf-vfp-poky-linux-gnueabi/gnss-sdr/0.0.12.git-r0/temp/log.do_package.2625
ERROR: Task (/home/jon/src/jmagnuson/yocto/rpi0/layers/meta-gnss-sdr/recipes-core/gnss-sdr/gnss-sdr_git.bb:do_package) failed with exit code '1'
```

parse error:
```
ERROR: ParseError at /home/jon/src/jmagnuson/yocto/rpi0/build/conf/local.conf:284: unparsed line: 'INSANE_SKIP_gnss-sdr_append = “already-stripped”
```

just add:
```
INSANE_SKIP_${PN}_append = "already-stripped"
```
to the recipe directly

works, but now--
```
NOTE: Running intercept scripts:
NOTE: > Executing update_pixbuf_cache intercept ...
NOTE: + '[' True = False -a qemuwrapper-cross '!=' nativesdk-qemuwrapper-cross ']'
+ qemu-arm -r 3.2.0 -E LD_LIBRARY_PATH=/home/jon/src/jmagnuson/yocto/rpi0/build/tmp/work/raspberrypi0_wifi-poky-linux-gnueabi/gnss-sdr-demo-docker/1.0-r0/rootfs/usr/lib:/home/jon/src/jmagnuson/yocto/rpi0/build/tmp/work/raspberrypi0_wifi-poky-linux-gnueabi/gnss-sdr-demo-docker/1.0-r0/rootfs/lib -L /home/jon/src/jmagnuson/yocto/rpi0/build/tmp/work/raspberrypi0_wifi-poky-linux-gnueabi/gnss-sdr-demo-docker/1.0-r0/rootfs /home/jon/src/jmagnuson/yocto/rpi0/build/tmp/work/raspberrypi0_wifi-poky-linux-gnueabi/gnss-sdr-demo-docker/1.0-r0/rootfs/usr/lib/gdk-pixbuf-2.0/gdk-pixbuf-query-loaders

NOTE: > Executing update_gio_module_cache intercept ...
NOTE: Exit code 1. Output:
+ '[' True = False -a qemuwrapper-cross '!=' nativesdk-qemuwrapper-cross ']'
+ qemu-arm -r 3.2.0 -E LD_LIBRARY_PATH=/home/jon/src/jmagnuson/yocto/rpi0/build/tmp/work/raspberrypi0_wifi-poky-linux-gnueabi/gnss-sdr-demo-docker/1.0-r0/rootfs/usr/lib:/home/jon/src/jmagnuson/yocto/rpi0/build/tmp/work/raspberrypi0_wifi-poky-linux-gnueabi/gnss-sdr-demo-docker/1.0-r0/rootfs/lib -L /home/jon/src/jmagnuson/yocto/rpi0/build/tmp/work/raspberrypi0_wifi-poky-linux-gnueabi/gnss-sdr-demo-docker/1.0-r0/rootfs /home/jon/src/jmagnuson/yocto/rpi0/build/tmp/work/raspberrypi0_wifi-poky-linux-gnueabi/gnss-sdr-demo-docker/1.0-r0/rootfs/usr/libexec/gio-querymodules /home/jon/src/jmagnuson/yocto/rpi0/build/tmp/work/raspberrypi0_wifi-poky-linux-gnueabi/gnss-sdr-demo-docker/1.0-r0/rootfs/usr/lib/gio/modules/

ERROR: The postinstall intercept hook 'update_gio_module_cache' failed, details in /home/jon/src/jmagnuson/yocto/rpi0/build/tmp/work/raspberrypi0_wifi-poky-linux-gnueabi/gnss-sdr-demo-docker/1.0-r0/temp/log.do_rootfs
DEBUG: Python function do_rootfs finished
```

hello...
```
jon@r4 ~/src/jmagnuson/yocto/rpi0/build/tmp/work/raspberrypi0_wifi-poky-linux-gnueabi/gnss-sdr-demo-docker/1.0-r0 $ ./recipe-sysroot-native/usr/bin/qemu-arm -r 3.2.0 -E LD_LIBRARY_PATH=/home/jon/src/jmagnuson/yocto/rpi0/build/tmp/work/raspberrypi0_wifi-poky-linux-gnueab
i/gnss-sdr-demo-docker/1.0-r0/rootfs/usr/lib:/home/jon/src/jmagnuson/yocto/rpi0/build/tmp/work/raspberrypi0_wifi-poky-linux-gnueabi/gnss-sdr-demo-docker/1.0-r0/rootfs/lib -L /home/jon/src/jmagnuson/yocto/rpi0/build/tmp/work/raspberrypi0_wifi-poky-linux-gnueabi/gnss-sdr-
demo-docker/1.0-r0/rootfs /home/jon/src/jmagnuson/yocto/rpi0/build/tmp/work/raspberrypi0_wifi-poky-linux-gnueabi/gnss-sdr-demo-docker/1.0-r0/rootfs/usr/libexec/gio-querymodules /home/jon/src/jmagnuson/yocto/rpi0/build/tmp/work/raspberrypi0_wifi-poky-linux-gnueabi/gnss-s
dr-demo-docker/1.0-r0/rootfs/usr/lib/gio/modules/poky-linux-gnueabi/gnss-sdr-demo-docker/1.0-r0/rootfs/usr/lib/gio/modules/
Error while loading /home/jon/src/jmagnuson/yocto/rpi0/build/tmp/work/raspberrypi0_wifi-poky-linux-gnueabi/gnss-sdr-demo-docker/1.0-r0/rootfs/usr/libexec/gio-querymodules: Permission denied
```

```
$ ls -l
...
-rwxr-xr-x 1 jon jon  30208 Jul 15 18:58 frcode
drwxr-xr-x 3 jon jon   4096 Jul 15 19:22 gcc
-rw-r--r-- 1 jon jon  33676 Jul 15 18:19 gio-querymodules
drwxr-xr-x 3 jon jon   4096 Jul 15 22:05 gnuplot
-rwxr-xr-x 1 jon jon  87712 Jul 15 19:05 gpg-check-pattern
...
```

thinking gio-querymodules needs user exec or something
```
chmod +x /home/jon/src/jmagnuson/yocto/rpi0/build/tmp/work/raspberrypi0_wifi-poky-linux-gnueabi/gnss-sdr-demo-docker/1.0-r0/rootfs/usr/libexec/gio-querymodules
```

well, running the above worked on its own, now try bitbake...

nope, got replaced and failed again. patch script directly:
```
diff --git a/scripts/postinst-intercepts/update_gio_module_cache b/scripts/postinst-intercepts/update_gio_module_cache
index c87fa85db9..a6610c19b8 100644
--- a/scripts/postinst-intercepts/update_gio_module_cache
+++ b/scripts/postinst-intercepts/update_gio_module_cache
@@ -5,6 +5,9 @@

 set -e

+# Fix permission-denied
+chmod +x $D${libexecdir}/${binprefix}gio-querymodules
+
 PSEUDO_UNLOAD=1 ${binprefix}qemuwrapper -L $D $D${libexecdir}/${binprefix}gio-querymodules $D${libdir}/gio/modules/

 [ ! -e $D${libdir}/gio/modules/giomodule.cache ] ||
```

```
$ bitbake gnss-sdr-demo-docker
```
WORKS!
