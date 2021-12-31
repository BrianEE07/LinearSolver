import math

def k2ij (k, n):
    j = int(n - 2 - math.floor(math.sqrt(-8 * k + 4 * n * (n - 1) - 7) / 2.0 - 0.5))
    i = int(k + j + 1 - n * (n - 1) / 2 + (n - j) * ((n - j) - 1) / 2)
    return (i, j)

def ij2k (i, j, n):
    k = int((n * (n - 1) / 2) - (n - j) * ((n - j) - 1) / 2 + i - j - 1)
    return k

if __name__ == "__main__":
    
    n = 96;

    for k in range(int(n * (n - 1) / 2)):
        (i, j) = k2ij(k, n)
        print("k=", k, "(i, j)=", i, j)

    print()

    for j in range(n):
        for i in range(j + 1, n):
            k = ij2k(i, j, n)
            print("(i, j)=", i, j, "k=", k)
