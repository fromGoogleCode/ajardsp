# Introduction #

This page describes how to setup the AjarDSP GCC port. First of all it should be noted that this port, at the time of writing, is very much work in progress and nowhere near complete (and/or even useful).

Assuming some pathnames then the following steps may be taken to build a debuggable compiler.

First apply this patch to add AjarDSP to the configuration scripts.

```
diff --unified -r orig/gcc-4.5.0/config.sub gcc-4.5.0/config.sub
--- orig/gcc-4.5.0/config.sub	2010-03-23 15:26:40.000000000 +0100
+++ gcc-4.5.0/config.sub	2010-07-14 12:03:15.020517581 +0200
@@ -312,7 +312,7 @@
 	c6x)
 		basic_machine=tic6x-unknown
 		;;
-	m6811 | m68hc11 | m6812 | m68hc12 | picochip)
+	m6811 | m68hc11 | m6812 | m68hc12 | picochip | ajardsp)
 		# Motorola 68HC11/12.
 		basic_machine=$basic_machine-unknown
 		os=-none
diff --unified -r orig/gcc-4.5.0/gcc/config.gcc gcc-4.5.0/gcc/config.gcc
--- orig/gcc-4.5.0/gcc/config.gcc	2010-04-07 12:34:00.000000000 +0200
+++ gcc-4.5.0/gcc/config.gcc	2010-07-14 12:03:47.730501702 +0200
@@ -335,6 +335,9 @@
 picochip-*-*)
         cpu_type=picochip
         ;;
+ajardsp-*-*)
+        cpu_type=ajardsp
+        ;;
 powerpc*-*-*)
 	cpu_type=rs6000
 	extra_headers="ppc-asm.h altivec.h spe.h ppu_intrinsics.h paired.h spu2vmx.h vec_types.h si2vmx.h"
@@ -1896,6 +1899,10 @@
 	tm_file="${tm_file} newlib-stdint.h"
 	use_gcc_stdint=wrap
         ;;
+ajardsp-*)
+	tm_file="${tm_file} newlib-stdint.h"
+	use_gcc_stdint=wrap
+        ;;
 # port not yet contributed
 #powerpc-*-openbsd*)
 #	tmake_file="${tmake_file} rs6000/t-fprules rs6000/t-fprules-fpbit "

```

Then follow these steps to configure and build the compiler.

```
$ cd ~/gcc-4.5.0/gcc/config
$ ln -s ~/ajardsp/sw/tools/gcc/config/ajardsp/ ajardsp
$ cd ~/ajardsp-gcc-build
$ ../gcc-4.5.0/configure --target=ajardsp --enable-checking=yes --enable-languages=c
$ make CFLAGS="-O0 -g3" -j32
```

The last step is expected to fail with a message similar to

```
...
checking for ajardsp-gcc... /home/markus/gcc_work/build-ajardsp/./gcc/xgcc -B/home/markus/gcc_work/build-ajardsp/./gcc/ -B/usr/local/ajardsp/bin/ -B/usr/local/ajardsp/lib/ -isystem /usr/local/ajardsp/include -isystem /usr/local/ajardsp/sys-include
checking for suffix of object files... configure: error: in `/home/markus/gcc_work/build-ajardsp/ajardsp/libgcc':
configure: error: cannot compute suffix of object files: cannot compile
See `config.log' for more details.
make[1]: *** [configure-target-libgcc] Error 1
make[1]: Leaving directory `/home/markus/gcc_work/build-ajardsp'
make: *** [all] Error 2
$
```

And as a final step we create a symbolic link for ajardsp-gcc.

```
$ cd ~/ajardsp-gcc-build/gcc
$ ln -s xgcc ajardsp-gcc
```