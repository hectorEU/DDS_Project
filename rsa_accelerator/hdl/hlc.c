#include <stdio.h>
#include <math.h>

int montgomery(int a, int b, int modulus, int k)
{
    int r = 0;
    for(int i=0; i<k; i++)
    {
        r = r + ((a >> i) & 1) * b;
        if((r & 1) == 0)
        {
            r = r >> 1;
        }
        else
        {
            r = (r + modulus) >> 1;
        }
            
    }
    return r;
}

int mod_mult(int a, int b, int modulus, int c, int k)
{
    int r = 0;
    r = montgomery(a, b, modulus, k);
    return montgomery(r, c, modulus, k);
}

int gen_r2(int k, int n)
{
    int result = 2;
    while(k>1)
    {
        result *= 2;
        result %= n;
        k--;
    }
    return result;
}

void mod_mult_test()
{
    int k = sizeof(int)*8; // k bits of operands
    int n = 101;
    int ab = 0;
    int ans = 0;
    int c = gen_r2(2*k, n);
    char pass = 1;
    for(int a = 0; a < 50; a++)
    {
       for(int b = 50; b < 100; b++)
       {
           if(a >= n || b >= n)
           {
               printf("mod_mult() FAIL\n");
               printf("%d and %d must be < %d\n", a, b, n);
               pass = 0;
           }
            ab = mod_mult(a, b, n, c, k); // C=2**(2*32bits) mod n
            ans = (a*b)%n;
            if(ab!=ans)
            {
                printf("mod_mult() FAIL\n");
                printf("%d x %d = %d vs %d\n", a, b, ab, ans);
                pass = 0;
            }
       }
    }
    if(pass) printf("mod_mult() PASS\n");
}

int RL_binary_method(int m, int e, int modulus, int r2, int k)
{
    int c = 1;
    int p = m;
    int i;
    for(i=0; i<k; i++)
    {
        if(e & (1<<i)) c=mod_mult(c, p, modulus, r2, k);
        p=mod_mult(p, p, modulus, r2, k);
    }
    return c;
}


int main()
{
    mod_mult_test();
    int modulus = 13;
    int k = sizeof(int)*8;
    int r2 = gen_r2(2*k, modulus);
    int m = 7;
    int e = 10;
    int ans = RL_binary_method(7, 10, modulus, r2, k);
	printf("\n%d", k);
    int ans2= (7*7*7*7*7*7*7*7*7*7)%modulus;
    printf("\n%d", ans2);
    printf("\n%d", ans);
}
