static const int a[10] = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
static int b[10] = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
static int foo(void) {return 4;}
int bar(void) {return 4;}

void avoid_unused_warnings(void){
  (void)a;
  (void)b;
  (void)foo;
}
