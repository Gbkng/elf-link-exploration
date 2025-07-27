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

# [build]() the examples

```
gcc foo.c -c -g -Wall -Wextra -O0 -static -o foo.o
gcc main.c -g -Wall -Wextra -O0 -o main
```

# [scan]() symbols

```
nm --demangle --synthetic --line-numbers --with-symbol-versions --no-sort foo.o | 
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



