import math
import numpy as np

def forward_subs(L, b):
    y = np.array(b)
    n = b.shape[0]
    for i in range(n):
        for j in range(i):
            y[i] -= L[i, j] * y[j]
        y[i] /= L[i, i]
    return y

def back_subs(U, y):
    x = np.array(y)
    n = y.shape[0]
    for i in range(n - 1, -1, -1):
        for j in range(i + 1, n):
            x[i] -= U[i, j] * x[j]
        x[i] /= U[i, i]
    return x

def cholesky(A):
    L = np.tril(A)
    n = A.shape[0]
    for j in range(n):
        L[j, j] = math.sqrt(L[j, j])
        for i in range(j + 1, n):
            L[i, j] /= L[j, j]
        for k in range(j + 1, n):
            for i in range(k, n):
                L[i, k] -= L[i, j] * L[k, j]
    LT = L.transpose()
    return L, LT

if __name__ == "__main__":
    A = np.array([[4.0, 12.0, -16.0],
                 [12.0, 37.0, -43.0],
                 [-16.0, -43.0, 98.0]])

    b = np.array([-20.0, -43.0, 192.0]) # x = [1.0, 2.0, 3.0]

    L, LT = cholesky(A)
    print(np.matmul(L, LT))
    y = forward_subs(L, b)
    x = back_subs(LT, y)
    print(x)