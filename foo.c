static const int a[10] = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
static int b[10] = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
static int foo(void) {return 4;}
int bar(void) {return 4;}
static void dumb(void){
  (void)a;
  (void)b;
  (void)foo;
  (void)bar;
  (void)dumb;
}
