#include <iostream>
#include <fstream>
#include <string>
#include <iomanip>
#include <bitset>
#include "fpm/fixed.hpp"
#include "fpm/ios.hpp"

using namespace std;

/* LDLT.cpp
   Specify First
   -> matrix size : N (NxN)
   -> input floating point matrix file path : in_path
   -> output binary fixed point matrix file path : out_mat_path
   -> output binary fixed point golden file path : out_gold_path
   Binary Data Format
   -> 32bits signed fixed point Q15.16, low triangle, column-wise
   Features
   -> dump verilog binary testbench patterns
   -> calculate error between floating point & fixed point (TODO)
*/

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
    float mac = 0;
    // LDLT
    // for (int i = 0;i < N;++i) {
    //     for (int j = 0;j < i;++j) {
    //         for (int k = 0;k < j;++k) {
    //             L[i][j] -= L[i][k] * L[k][k] * L[j][k];
    //         }
    //         L[i][j] /= L[j][j];
    //         L[i][i] -= L[i][j] * L[i][j] * L[j][j];
    //     }
    // }
    // for (int j = 0;j < N;++j) {
    //     for (int i = j;i < N;++i) {
    //         for (int k = 0;k <= j;++k) {
    //             if (k == j) {
    //                 mac = 0;
    //                 if (i != j) {
    //                     L[i][j] /= L[j][j];
    //                 }
    //             }
    //             else if (k < j) {
    //                 mac += float(L[i][k]) * float(L[k][k]) * float(L[j][k]);
    //             }
    //             if (k == j - 1) {
    //                 fpm::fixed_16_16 mac_fpm {mac};
    //                 L[i][j] -= mac_fpm;
    //             }
    //         }
    //     }
    // }
    for (int j = 0;j < N;++j) {
        for (int i = j;i < N;++i) {
            for (int k = 0;k <= j;++k) {
                if (k == j && i != j) {
                    L[i][j] /= L[j][j];
                }
                else if (k < j) {
                    L[i][j] -= L[i][k] * L[k][k] * L[j][k];
                }
            }
        }
    }

    return L;
}

void dumpFixed2Bin(string path, fpm::fixed_16_16 **M, int N) {
    fstream fout;
    fout.open(path, ios::out);

    // dump binary vertically to file
    for (int j = 0;j < N;++j) {
        for (int i = j;i < N;++i) {
            int l_int = int(float(M[i][j]) * 65536);
            string l_str = bitset<32>(l_int).to_string();
            fout << l_str.substr(0, 16) << '_' << l_str.substr(16) << '\n';
        }
    }

    // dump comments to file
    fout << '\n';
    for (int i = 0;i < N;++i) {
        fout << "//";
        for (int j = 0;j <= i;++j) {
            fout << setw(12) << right << setprecision(5) << fixed << M[i][j];

        }
        fout << '\n';
    } 
    fout << '\n';
    fout << "// dump file: " << path << '\n';
    fout << "// data num: " << N * (N + 1) / 2 << '\n';
    fout << "// 32bits signed fixed point Q15.16" << '\n';
    fout << "// column-wise" << '\n';
    fout.close();
}

int main () {

    const int N = 96;
    // const int N = 6;
    // const int N = 858;
    string in_path = "./pattern/matrix_96x96_float.dat";
    // string in_path = "./pattern/matrix_6x6_float.dat";
    // string in_path = "./pattern/matrix_858x858_float.dat";
    string out_mat_path = "./pattern/matrix_96x96.dat";
    // string out_mat_path = "./pattern/matrix_6x6.dat";
    string out_gold_path = "./pattern/golden_96x96.dat";
    // string out_gold_path = "./pattern/golden_6x6.dat";

    fstream fin;
    fin.open(in_path, ios::in);
    if (!fin) {
        cerr << "Can't open file!" << endl;
        exit(1);
    }

    float **A_float = new float*[N];
    fpm::fixed_16_16 **A_fixed = new fpm::fixed_16_16*[N];

    for (int i = 0;i < N;++i) {
        A_float[i] = new float[N];
    }
    for (int i = 0;i < N;++i) {
        A_fixed[i] = new fpm::fixed_16_16[N];
    }

    // readfile
    string data;
    int cnt = 0;
    while (getline(fin, data, ',')) {
        A_float[cnt / N][cnt % N] = stof(data);
        A_fixed[cnt / N][cnt % N] = fpm::fixed_16_16(stof(data));
        ++cnt;
    }
    fin.close();

    // LDLT
    float** L_float = LDLT_float(A_float, N);
    fpm::fixed_16_16** L_fixed = LDLT_fixed(A_fixed, N);

    // dumpfile
    dumpFixed2Bin(out_mat_path, A_fixed, N);
    dumpFixed2Bin(out_gold_path, L_fixed, N);

    // print if needed
    cout << "FLOAT LDLT" << endl;
    for (int i = 0;i < N;++i) {
        for (int j = 0;j < N;++j) {
            cout << setprecision(8) << fixed << L_float[i][j] << " ";
        }
        cout << endl;
    }
    cout << "FIXED LDLT" << endl;
    for (int i = 0;i < N;++i) {
        for (int j = 0;j < N;++j) {
            cout << setprecision(8) << fixed << L_fixed[i][j] << " ";
        }
        cout << endl;
    }
}