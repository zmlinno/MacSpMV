//
//  main.cpp
//  SpMVCPU
//
//  Created by 张木林 on 11/3/24.
//
#import <Foundation/Foundation.h>
#import <iostream>
#import <vector>
#import <fstream>
#import <sstream>
#import <chrono>

// CSR 格式的稀疏矩阵类
class CSRSparseMatrix {
public:
    std::vector<float> values;
    std::vector<int> col_indices;
    std::vector<int> row_ptr;
    int rows;
    int cols;

    // 构造函数，初始化行和列的数量
    CSRSparseMatrix(int rows, int cols) : rows(rows), cols(cols) {
        row_ptr.resize(rows + 1, 0);
    }

    // 添加元素到稀疏矩阵
    void addElement(int row, int col, float value) {
        values.push_back(value);
        col_indices.push_back(col);
        row_ptr[row + 1]++;
    }

    // 最终确定 CSR 的行指针数组
    void finalize() {
        for (int i = 1; i < row_ptr.size(); ++i) {
            row_ptr[i] += row_ptr[i - 1];
        }
    }

    // SpMV 稀疏矩阵-向量乘法
    std::vector<float> multiply(const std::vector<float>& vec) const {
        std::vector<float> result(rows, 0.0f);
        for (int i = 0; i < rows; ++i) {
            float sum = 0.0f;
            for (int j = row_ptr[i]; j < row_ptr[i + 1]; ++j) {
                sum += values[j] * vec[col_indices[j]];
            }
            result[i] = sum;
        }
        return result;
    }
};

// 从 Matrix Market 文件中读取稀疏矩阵
bool readMatrixMarketFile(const std::string& filename, CSRSparseMatrix& csrMatrix) {
    std::ifstream file(filename);
    if (!file.is_open()) {
        std::cerr << "无法打开文件: " << filename << std::endl;
        return false;
    }

    std::string line;
    // 跳过注释行
    while (std::getline(file, line)) {
        if (line[0] != '%') break;
    }

    // 读取矩阵维度和非零元素数
    std::istringstream iss(line);
    int rows, cols, nonZeroCount;
    iss >> rows >> cols >> nonZeroCount;

    // 初始化 CSR 矩阵
    csrMatrix = CSRSparseMatrix(rows, cols);

    // 读取非零元素
    int row, col;
    float value;
    while (file >> row >> col >> value) {
        csrMatrix.addElement(row - 1, col - 1, value); // 转换为 0 基索引
    }

    csrMatrix.finalize();
    return true;
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // 文件路径（请修改为你的文件路径）
//        std::string filePath = "/Users/zhangmulin/Downloads/soc-Pokec/soc-Pokec.mtx";
//        std::string filePath = "/Users/zhangmulin/Downloads/arabic-2005/arabic-2005.mtx";
        std::string filePath = "/Users/zhangmulin/Downloads/webbase-2001/webbase-2001.mtx";

        // 读取稀疏矩阵文件
        CSRSparseMatrix csrMatrix(0, 0);
        if (!readMatrixMarketFile(filePath, csrMatrix)) {
            return -1; // 文件读取失败，退出
        }

        // 创建一个与矩阵维度相匹配的随机向量
        std::vector<float> vec(csrMatrix.cols, 1.0f);

        // 开始计时
        auto start = std::chrono::high_resolution_clock::now();

        // 执行 SpMV 操作
        std::vector<float> result = csrMatrix.multiply(vec);

        // 结束计时
        auto end = std::chrono::high_resolution_clock::now();
        std::chrono::duration<double> elapsed = end - start;

        // 打印运行时间
        std::cout << "SpMV execution time on CPU: " << elapsed.count() << " s" << std::endl;

        // （可选）打印部分结果
        std::cout << "Result (first 10 elements): ";
        for (int i = 0; i < std::min(10, (int)result.size()); ++i) {
            std::cout << result[i] << " ";
        }
        std::cout << std::endl;
    }
    return 0;
}

