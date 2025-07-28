# About

An exploration of the possibilities to link ELF format in various ways.
Notably, explore following possibilities :

- How to embed a static library in a dynamic library ?
- Is it possible to create a static library from a dynamic library ?
- How to compile an executable with both static and dynamic libraries ?
- What is the impact of various linkers ?

# Ref

- [1] https://www.lurklurk.org/linkers/linkers.html
  An excellent introduction to link procedures and conventions
- [2] https://gavinhoward.com/2021/10/static-linking-considered-harmful-considered-harmful/
  A deep dive into implication of static and dynamic linking. The article
  notably points out that dynamic linking is not always the answer (which seems
  to be often ignore in the Linux ecosystem)
- [3] https://stackoverflow.com/questions/65575673/is-it-possible-to-compile-a-c-program-with-both-static-and-dynamic-libraries
  On the `gcc` command to link against both static and dynamic libraries


# [build-1]()

Dependency graph and goals

```
cat <<EOF
main
|
|- libstatic-2.a
|
|- libdynamic.so
   |
   |-libstatic.a
EOF
```

- The first goal is to have `libstatic.a` statically linked against
  `libdynamic.so` so that `libdynamic.so` is a static shared library.
- The second goal is to have `main` which is both linked statically against
  `libstatic-2.a` and dynamically linked against `libdynamic.so`, to demonstrate
  that it is possible to combine static and dynamic linkage modes. It is also
  important to show that `libstatic.a` is not needed to link `main` against
  `libdynamic.so`, as `libdynamic.so` has been statically linked against
  `libstatic.a`

Build static archives (ie. static libraries)

```
gcc src/static.c -c -g -Wall -Wextra -O0 -static -o static.o
ar r libstatic.a static.o 2>/dev/null
```

```
gcc src/static-2.c -c -g -Wall -Wextra -O0 -static -o static-2.o
ar r libstatic-2.a static-2.o 2>/dev/null
```

`libstatic.a` is required by the dynamic library `libdynamic.so`, while the
second `libstatic-2.a` is required by `main`.

Build dynamic lib depending on the static archive

```
gcc \
    src/dynamic.c \
    -shared \
    -static-libgcc \
    -g \
    -fPIC \
    -Wall \
    -Wextra \
    -O0 \
    -o libdynamic.so \
    -L. \
    -Wl,-Bstatic \
    -lstatic \
    -Wl,-Bdynamic
```

Note the use of `-Wl,-Bstatic` to impose search of static libraries only.
`-Wl,-Bdynamic` falls back to the "dynamic, else static (if dynamic not found)". If `-Wl,-Bstatic`
is used, it is **mandatory that the last `-Wl,-B<some>` be `-Wl,-Bdynamic`.
Otherwise, linkage with `libc` fails.

Build main

```
gcc -g -Wall -Wextra -O0 \
    -o main \
    src/main.c \
    -L ./ \
    -Wl,-Bdynamic -ldynamic \
    -Wl,-Bstatic -lstatic-2 \
    -Wl,-Bdynamic
```

# [build-2]()

Dependency graph and goals

```
cat <<EOF
main
|
|- libstatic-2.a
|
|- libdynamic.so
   |
   |-libstatic.so <- obtained from 'libstatic.a'
EOF
```

This is the same as `build-1`, but it demonstrates that it is possible and easy
to build a shared library from a static library.

Here, dynamic library `libstatic.so` is built from static library
`libstatic.a`.

This section contains less explanation that `build-1`, as most of the
commands the same. Explanations mainly emphasize differences compared to
`build-1`.

Build static archives (ie. static libraries)

```
gcc src/static.c -c -g -Wall -Wextra -O0 -static -o static.o
gcc src/static-2.c -c -g -Wall -Wextra -O0 -static -o static-2.o

ar r libstatic.a static.o 2>/dev/null
ar r libstatic-2.a static-2.o 2>/dev/null
```

Transform static library into dynamic library:

The `-Wl,--whole-archive` option allows to create the dynamic library
directly from the static archive, **without any need for an intermediate binding
file**.

```
gcc -shared -fPIC -o libstatic.so -Wl,--whole-archive libstatic.a -Wl,--no-whole-archive
```

Build dynamic lib depending on the dynamic version of the initial static library

```
gcc \
    src/dynamic.c \
    -shared \
    -static-libgcc \
    -g \
    -fPIC \
    -Wall \
    -Wextra \
    -O0 \
    -o libdynamic.so \
    -L. \
    -Wl,-Bdynamic \
    -lstatic \
    -Wl,-Bdynamic
```

Build main

```
gcc -g -Wall -Wextra -O0 \
    -o main \
    src/main.c \
    -L ./ \
    -Wl,-Bdynamic -ldynamic -lstatic \
    -Wl,-Bstatic -lstatic-2 \
    -Wl,-Bdynamic
```

# [build-failure]()

Extract symbols from a `.so` library:

```
objcopy --extract-symbol libdynamic.so libdynamic-symbols.o
```

Build a static library from the extracted symbols:

```
ar r libdynamic.a libdynamic-symbols.o
```

Note that those commands are here as a curiosity. It does not work in practice
due to missing linkage information in `libdynamic-symbols.o`, preventing from
linking against the latter.

Link with object file of extracted symbols of dynamic library, which **does not
work** (probably because of missing linker directive inside object files):

```
gcc src/main.c -c -g -Wall -Wextra -O0 -o main.o
gcc -o main main.o static.o libdynamic-symbols.o
```

# [clean]() remove build artifacts

```
rm -f *.o *.so *.a main
```

# [scan]() symbols

```
nm --demangle --synthetic --line-numbers --with-symbol-versions --no-sort libdynamic.so |
    sed -E \
        -e "s/^[a-z0-9]+ //" \
        -e "s/^ +//" \
        -e "s/^R/R  global read-only...>/" \
        -e "s/^r/r  local  read-only...>/" \
        -e "s/^B/B  global .bss........>/" \
        -e "s/^b/b  local  .bss........>/" \
        -e "s/^D/D  global .data.......>/" \
        -e "s/^d/d  local  .data.......>/" \
        -e "s/^I/I  indirect ref.......>/" \
        -e "s/^S/S  global small uninit>/" \
        -e "s/^s/s  local  small uninit>/" \
        -e "s/^T/T  global .text.......>/" \
        -e "s/^t/t  local  .text.......>/" \
        -e "s/^V/V  global weak........>/" \
        -e "s/^v/v  local  weak........>/" \
        -e "s/^W/W  global weak unspec.>/" \
        -e "s/^w/w  local  weak unspec.>/" \
        -e "s/^U/U  undefined..........>/" \
        -e "s/^u/u  uniq global sym....>/" \
        -e "s/^A/A  absolute sym.......>/" \
        -e "s/^N/N  debug sym..........>/" \
        -e "s/^n/n  misc read-only.....>/" \
        -e "s/^p/p  stack unwind.......>/" \
| sort
```
