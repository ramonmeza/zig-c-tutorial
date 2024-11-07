#include <stdio.h>
#include "zmath.h"

int main(void) {
    int a = 10;
    int b = 5;
    
    int resultAdd = add(a, b);
    printf("%d + %d = %d\n", a, b, resultAdd);
    
    int resultSub = sub(a, b);
    printf("%d - %d = %d\n", a, b, resultSub);

    return 0;
}
