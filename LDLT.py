import math
import numpy as np

def forward_subs(L, b):
    z = np.array(b)
    n = b.shape[0]
    for i in range(n):
        for j in range(i):
            z[i] -= L[i, j] * z[j]
        z[i] /= L[i, i]
    return z

def back_subs(U, y):
    x = np.array(y)
    n = y.shape[0]
    for i in range(n - 1, -1, -1):
        for j in range(i + 1, n):
            x[i] -= U[i, j] * x[j]
        x[i] /= U[i, i]
    return x

def diag_scale(D, z):
    y = np.divide(z, D)
    return y

# def LDLT(A):
#     D = np.diag(A).copy()
#     L = np.tril(A)
#     n = A.shape[0]

#     for i in range(n):
#         L[i, i] = 1
#     for i in range(n):
#         for j in range(i):
#             for k in range(j):
#                 L[i, j] -= L[i, k] * D[k] * L[j, k]
#             L[i, j] /= D[j]
#             D[i] -= L[i, j] * L[i, j] * D[j]
#     LT = L.transpose()
#     return L, D, LT

def LDLT(A):
    L = np.tril(A)
    n = A.shape[0]

    for i in range(n):
        for j in range(i):
            for k in range(j):
                L[i, j] -= L[i, k] * L[k, k] * L[j, k]
            L[i, j] /= L[j, j]
            L[i, i] -= L[i, j] * L[i, j] * L[j, j]

    D = np.diag(L).copy()
    for i in range(n):
        L[i, i] = 1
    LT = L.transpose()
    return L, D, LT

if __name__ == "__main__":
    # A = np.array([[ 4.0,  12.0, -16.0, -18.0,  -9.0,  -5.0],
    #              [ 12.0,  37.0, -43.0,  43.0,   5.0,  99.0],
    #              [-16.0, -43.0,  98.0,   8.0,   9.0,  77.0],
    #              [-18.0,  43.0,   8.0, 107.0,   8.0,   3.0],
    #              [ -9.0,   5.0,   9.0,   8.0, 223.0,  10.0],
    #              [ -5.0,  99.0,  77.0,   3.0,  10.0, 332.0]])

    # b = np.array([-20.0, -43.0, 192.0,  16.0, 22.0, 44.0])
    # A = np.array([[ 1.0,   1.0,   2.0,   3.0,   4.0,   5.0],
    #              [  1.0,   2.0,   4.0,   3.0,   1.0,   0.0],
    #              [  2.0,   4.0,   1.0,   5.0,   2.0,   1.0],
    #              [  3.0,   3.0,   5.0,   2.0,   2.0,   3.0],
    #              [  4.0,   1.0,   2.0,   2.0,   1.0,   4.0],
    #              [  5.0,   0.0,   1.0,   3.0,   4.0,   3.0]])

    # b = np.array([-20.0, -43.0, 192.0,  16.0, 22.0, 44.0])
    A = np.array([[4.0, 12.0, -16.0],
                 [12.0, 37.0, -43.0],
                 [-16.0, -43.0, 98.0]])

    b = np.array([-20.0, -43.0, 192.0]) # x = [1.0, 2.0, 3.0]

    L, D, LT = LDLT(A)
    print(np.matmul(L, np.matmul(np.diagflat(D), LT)))
    z = forward_subs(L, b)
    y = diag_scale(D, z)
    x = back_subs(LT, y)
    print(x)
    # S = np.array([[ 1.0,   0.0,   0.0,   0.0,   0.0,   0.0],
    #              [  1.0,   1.0,   0.0,   0.0,   0.0,   0.0],
    #              [  2.0,   4.0,   1.0,   0.0,   0.0,   0.0],
    #              [  3.0,   3.0,   5.0,   1.0,   0.0,   0.0],
    #              [  4.0,   1.0,   2.0,   2.0,   1.0,   0.0],
    #              [  5.0,   0.0,   1.0,   3.0,   4.0,   1.0]])
    # D = np.array([1.0, 2.0, 1.0, 1.0, 2.0, 3.0])
    # ST = S.transpose();
    # print(np.matmul(L, np.matmul(np.diagflat(D), LT)))

