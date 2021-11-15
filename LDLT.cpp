#include <iostream>
#include <fstream>
#include <string>
#include <iomanip>
#include "libfixmath/fixmath.h"

using namespace std;

float** LDLT_float (float **A, int N) {
    float **L = new float*[N];
    for (int i = 0;i < N;++i) {
        L[i] = new float[N];
    } 

    for (int i = 0;i < N;++i) {
        for (int j = 0;j < N;++j){
            L[i][j] = (i >= j) ? A[i][j] : 0;
        }
    }

    // LDLT
    for (int i = 0;i < N;++i) {
        for (int j = 0;j < i;++j) {
            for (int k = 0;k < j;++k) {
                L[i][j] -= L[i][k] * L[k][k] * L[j][k];
            }
            L[i][j] /= L[j][j];
            L[i][i] -= L[i][j] * L[i][j] * L[j][j];
        }
    }

    return L;
}

Fix16** LDLT_fixed (Fix16 **A, int N) {
    Fix16 **L = new Fix16*[N];
    for (int i = 0;i < N;++i) {
        L[i] = new Fix16[N];
    } 

    for (int i = 0;i < N;++i) {
        for (int j = 0;j < N;++j){
            L[i][j] = (i >= j) ? A[i][j] : Fix16(0);
        }
    }

    // LDLT
    for (int i = 0;i < N;++i) {
        for (int j = 0;j < i;++j) {
            for (int k = 0;k < j;++k) {
                L[i][j] -= L[i][k] * L[k][k] * L[j][k];
            }
            L[i][j] /= L[j][j];
            L[i][i] -= L[i][j] * L[i][j] * L[j][j];
        }
    }

    return L;
}

int main () {
    // Fix16 f(100.0);
    // Fix16 f2(300.54321);
    // Fix16 f3 = f / f2;
    // cout << fix16_t(f3) << endl;
    // cout << float(f3) << endl;
    // cout << 100 / 300.54321 << endl;

    int N = 858;
    fstream fin;
    fin.open("./pattern/matrix_858*858.dat", ios::in);
    if (!fin) {
        cerr << "Can't open file!" << endl;
        exit(1);
    }

    float **A_float = new float*[N];
    Fix16 **A_fixed = new Fix16*[N];
    for (int i = 0;i < N;++i) {
        A_float[i] = new float[N];
    }
    for (int i = 0;i < N;++i) {
        A_fixed[i] = new Fix16[N];
    }

    string data;
    int cnt = 0;
    while (getline(fin, data, ',')) {
        A_float[cnt / N][cnt % N] = stof(data);
        A_fixed[cnt / N][cnt % N] = Fix16(stof(data));
        ++cnt;
    }
    fin.close();

    // for (int i = 0;i < N;++i) {
    //     for (int j = 0;j < N;++j) {
    //         cout << setprecision(5) << fixed << A_float[i][j] << " ";
    //     }
    //     cout << endl;
    // }
    // for (int i = 0;i < N;++i) {
    //     for (int j = 0;j < N;++j) {
    //         cout << setprecision(5) << fixed << float(A_fixed[i][j]) << " ";
    //     }
    //     cout << endl;
    // }

    float** L_float = LDLT_float(A_float, N);
    Fix16** L_fixed = LDLT_fixed(A_fixed, N);

    for (int i = 0;i < N;++i) {
        for (int j = 0;j < N;++j) {
            cout << setprecision(5) << fixed << L_float[i][j] << " ";
            cout << setprecision(5) << fixed << float(L_fixed[i][j]) << " ";
        }
        cout << endl;
    }

    // for (int i = 0;i < N;++i) {
    //     for (int j = 0;j < N;++j) {
    //         cout << setprecision(5) << fixed << float(L_fixed[i][j]) << " ";
    //     }
    //     cout << endl;
    // }
}