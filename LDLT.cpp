#include <iostream>
#include <fstream>
#include <string>
#include <iomanip>
#include "fpm/fixed.hpp"
#include "fpm/ios.hpp"

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

fpm::fixed_16_16** LDLT_fixed (fpm::fixed_16_16 **A, int N) {
    fpm::fixed_16_16 **L = new fpm::fixed_16_16*[N];
    for (int i = 0;i < N;++i) {
        L[i] = new fpm::fixed_16_16[N];
    } 

    for (int i = 0;i < N;++i) {
        for (int j = 0;j < N;++j){
            L[i][j] = (i >= j) ? A[i][j] : fpm::fixed_16_16(0);
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

    int N = 6;
    // int N = 858;
    fstream fin;
    fin.open("./pattern/matrix_6x6_c.dat", ios::in);
    // fin.open("./pattern/matrix_858x858_c.dat", ios::in);
    if (!fin) {
        cerr << "Can't open file!" << endl;
        exit(1);
    }

    float **A_float = new float*[N];
    fpm::fixed_16_16 **A_fixed = new fpm::fixed_16_16*[N];
    // Fix16 **A_fixed = new Fix16*[N];
    for (int i = 0;i < N;++i) {
        A_float[i] = new float[N];
    }
    for (int i = 0;i < N;++i) {
        A_fixed[i] = new fpm::fixed_16_16[N];
    }

    string data;
    int cnt = 0;
    while (getline(fin, data, ',')) {
        A_float[cnt / N][cnt % N] = stof(data);
        A_fixed[cnt / N][cnt % N] = fpm::fixed_16_16(stof(data));
        ++cnt;
    }
    fin.close();

    float** L_float = LDLT_float(A_float, N);
    fpm::fixed_16_16** L_fixed = LDLT_fixed(A_fixed, N);

    for (int i = 0;i < N;++i) {
        for (int j = 0;j < N;++j) {
            cout << setprecision(8) << fixed << L_float[i][j] << " ";
        }
        cout << endl;
    }
    for (int i = 0;i < N;++i) {
        for (int j = 0;j < N;++j) {
            // cout << setprecision(8) << fixed << L_float[i][j] << " ";
            cout << setprecision(8) << fixed << L_fixed[i][j] << " ";
        }
        cout << endl;
    }  
}