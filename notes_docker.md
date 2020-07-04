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

