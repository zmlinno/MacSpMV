//
//  NSObject+SpMVCsr.m
//  SpMVTest
//
//  Created by 张木林 on 9/20/24.
//


//#import <Foundation/Foundation.h>
//#import <Metal/Metal.h>
//#import <vector>
//#include<fstream>
//#include<sstream>
//#include<iostream>
//#include<algorithm>
//using namespace std;
//
//
//
//
//
//
//class CSRSparseMatrix {
//public:
//    vector<float> values;
//    vector<int> col_indices;
//    vector<int> row_ptr;
//    int rows;
//    int cols;
//
//    CSRSparseMatrix(int rows, int cols) : rows(rows), cols(cols) {
//        row_ptr.resize(rows + 1, 0);  // row_ptr 的大小为 rows + 1
//    }
//
//    void addElement(int row, int col, float value) {
//        values.push_back(value);
//        col_indices.push_back(col);
//        row_ptr[row + 1]++;  // 仅延后更新行指针的计数
//    }
//
//    void finalize() {
//        for (int i = 1; i < row_ptr.size(); ++i) {
//            row_ptr[i] += row_ptr[i - 1];  // 构建行指针的累加
//        }
//    }
//    
//    enum MatrixType{GRAPH,SPMV,UNKNOWN};
//
//    //根据矩阵的特征判断它的类型
//    MatrixType identifyMatrixType(const CSRSparseMatrix& matrix)
//    {
//        if(matrix.rows == matrix.cols)
//        {
//            //判断是否是圆数据集(例如对称矩阵)
//            return GRAPH;
//        }
//        else
//        {
//            //如果行列不对称，可能是普通的SpMV数据集
//            return SPMV;
//        }
//    }
//};
//
//
//
//void readMatrixMarketFile(const std::string& fileName, CSRSparseMatrix& csrMatrix) {
//    std::ifstream file(fileName);
//    std::string line;
//    
//    // 跳过注释和头信息
//    while (std::getline(file, line)) {
//        if (line[0] != '%') {
//            break;
//        }
//    }
//    
//    std::istringstream header(line);
//    int rows, cols, nonZeroCount;
//    header >> rows >> cols >> nonZeroCount;
//
//    csrMatrix = CSRSparseMatrix(rows, cols);
//    
//    int row, col;
//    float value;
//    while (file >> row >> col >> value) {
//        csrMatrix.addElement(row - 1, col - 1, value);  // MTX格式的索引从1开始，C++从0开始
//    }
//    
//    csrMatrix.finalize();
//}
//
//
//int main() {
//    @autoreleasepool {
//        // 读取稀疏矩阵文件
//        CSRSparseMatrix csrMatrix(0, 0);
//        //readMatrixMarketFile("/Users/zhangmulin/Downloads/soc-Pokec/soc-Pokec.mtx", csrMatrix );
//        readMatrixMarketFile("/Users/zhangmulin/Downloads/mawi_201512020030/mawi_201512020030.mtx", csrMatrix);
//
//        // 创建一个与矩阵维度相匹配的向量
//        vector<float> vec(csrMatrix.cols, 1.0f);
//        vector<float> resultArray(csrMatrix.rows, 0.0f);
//
//        // Metal 初始化
//        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
//        id<MTLCommandQueue> commandQueue = [device newCommandQueue];
//        
//        // 声明 Metal 缓冲区
////         id<MTLBuffer> valuesBuffer = nil;
////         id<MTLBuffer> colIndicesBuffer = nil;
////         id<MTLBuffer> rowPtrBuffer = nil;
//        
//
//
//        // 创建 Metal 缓冲区
//        id<MTLBuffer> valuesBuffer = [device newBufferWithBytes:csrMatrix.values.data()
//                                                         length:csrMatrix.values.size() * sizeof(float)
//                                                        options:MTLResourceStorageModeShared];
//        id<MTLBuffer> colIndicesBuffer = [device newBufferWithBytes:csrMatrix.col_indices.data()
//                                                             length:csrMatrix.col_indices.size() * sizeof(int)
//                                                            options:MTLResourceStorageModeShared];
//        id<MTLBuffer> rowPtrBuffer = [device newBufferWithBytes:csrMatrix.row_ptr.data()
//                                                         length:csrMatrix.row_ptr.size() * sizeof(int)
//                                                        options:MTLResourceStorageModeShared];
//        id<MTLBuffer> vecBuffer = [device newBufferWithBytes:vec.data()
//                                                      length:vec.size() * sizeof(float)
//                                                     options:MTLResourceStorageModeShared];
//        id<MTLBuffer> resultBuffer = [device newBufferWithLength:resultArray.size() * sizeof(float)
//                                                         options:MTLResourceStorageModeShared];
//
//        // 原子任务索引
//        int initial_task_index = 0;
//        id<MTLBuffer> taskIndexBuffer = [device newBufferWithBytes:&initial_task_index
//                                                            length:sizeof(int)
//                                                           options:MTLResourceStorageModeShared];
//
//        // 加载 Metal 着色器
//        NSError *error = nil;
//        id<MTLLibrary> library = [device newDefaultLibrary];
//        id<MTLFunction> function = [library newFunctionWithName:@"csr_matrix_vector_mul"];
//        if (!function) {
//            NSLog(@"无法找到指定的函数");
//            return 0;
//        }
//        id<MTLComputePipelineState> computePipelineState = [device newComputePipelineStateWithFunction:function error:&error];
//
//        // 开始计时
//        NSDate *startTime = [NSDate date];
//
//        // 创建 GPU 编码器
//        id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
//        id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
//        [computeEncoder setComputePipelineState:computePipelineState];
//
//        // 设置缓冲区
//        [computeEncoder setBuffer:valuesBuffer offset:0 atIndex:0];
//        [computeEncoder setBuffer:colIndicesBuffer offset:0 atIndex:1];
//        [computeEncoder setBuffer:rowPtrBuffer offset:0 atIndex:2];
//        [computeEncoder setBuffer:vecBuffer offset:0 atIndex:3];
//        [computeEncoder setBuffer:resultBuffer offset:0 atIndex:4];
//        [computeEncoder setBuffer:taskIndexBuffer offset:0 atIndex:5];  // 原子任务索引
//
//        // 启动线程组，行的数量由稀疏矩阵的行数决定
//        MTLSize gridSize = MTLSizeMake(csrMatrix.rows, 1, 1);  // 每个线程对应一行
//        MTLSize threadGroupSize = MTLSizeMake(1, 1, 1);  // 你可以调整线程组大小以优化 GPU 性能
//
//        [computeEncoder dispatchThreads:gridSize threadsPerThreadgroup:threadGroupSize];
//
//        // 结束编码
//        [computeEncoder endEncoding];
//        [commandBuffer commit];
//        [commandBuffer waitUntilCompleted];
//
//        // 结束计时
//        NSDate *endTime = [NSDate date];
//        NSTimeInterval elapsedTime = [endTime timeIntervalSinceDate:startTime];
//        float elapsedTimeInMilliseconds = elapsedTime * 1000;//转换为毫秒
//        
//
//        // 读取 GPU 计算结果
////        float *resultPointer = (float *)[resultBuffer contents];
////        for (int i = 0; i < csrMatrix.rows; i++) {
////            resultArray[i] = resultPointer[i];
////        }
//
//        // 打印计算时间
//       // NSLog(@"计算时间: %f 秒", elapsedTime);
//        NSLog(@"SpMV execution time on GPU: %f ms",elapsedTimeInMilliseconds);
//
//        // 打印结果（可选，只打印前10个）
////        NSLog(@"Result of CSR Matrix-Vector Multiplication (first 10 elements):");
////        for (int i = 0; i < 10; i++) {
////            NSLog(@"%f ", resultArray[i]);
////        }
//    }
//    return 0;
//}




//int main() {
//    @autoreleasepool {
//        // 读取稀疏矩阵文件
//        CSRSparseMatrix csrMatrix(0, 0);
////        readMatrixMarketFile("/Users/zhangmulin/Downloads/mawi_201512020330/mawi_201512020330.mtx", csrMatrix);
//        readMatrixMarketFile("/Users/zhangmulin/Downloads/1138_bus/1138_bus.mtx",csrMatrix );
//        //readMatrixMarketFile("/Users/zhangmulin/Downloads/s3dkq4m2.mtx",csrMatrix );
//        //readMatrixMarketFile("/Users/zhangmulin/Downloads/arabic-2005/arabic-2005.mtx ",csrMatrix );
//        //readMatrixMarketFile("/Users/zhangmulin/Downloads/stokes 2/stokes.mtx", csrMatrix); //这个要保留的。比如
////        readMatrixMarketFile("/Users/zhangmulin/Downloads/delaunay_n20/delaunay_n20.mtx",csrMatrix );
//
//        // 创建一个与矩阵维度相匹配的向量
//        vector<float> vec(csrMatrix.cols, 1.0f);
//        vector<float> resultArray(csrMatrix.rows, 0.0f);
//
//        // Metal 初始化
//        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
//        id<MTLCommandQueue> commandQueue = [device newCommandQueue];
//
//        // 创建 Metal 缓冲区
//        id<MTLBuffer> valuesBuffer = [device newBufferWithBytes:csrMatrix.values.data()
//                                                         length:csrMatrix.values.size() * sizeof(float)
//                                                        options:MTLResourceStorageModeShared];
//        id<MTLBuffer> colIndicesBuffer = [device newBufferWithBytes:csrMatrix.col_indices.data()
//                                                             length:csrMatrix.col_indices.size() * sizeof(int)
//                                                            options:MTLResourceStorageModeShared];
//        id<MTLBuffer> rowPtrBuffer = [device newBufferWithBytes:csrMatrix.row_ptr.data()
//                                                         length:csrMatrix.row_ptr.size() * sizeof(int)
//                                                        options:MTLResourceStorageModeShared];
//        id<MTLBuffer> vecBuffer = [device newBufferWithBytes:vec.data()
//                                                      length:vec.size() * sizeof(float)
//                                                     options:MTLResourceStorageModeShared];
//        id<MTLBuffer> resultBuffer = [device newBufferWithLength:resultArray.size() * sizeof(float)
//                                                         options:MTLResourceStorageModeShared];
//        
//       
//        
//        
//        // 加载 Metal 着色器
//        NSError *error = nil;
//        id<MTLLibrary> library = [device newDefaultLibrary];
//        if (!library) {
//            NSLog(@"无法找到默认的Metal库");
//            return 0;
//        }
//        id<MTLFunction> function = [library newFunctionWithName:@"csr_matrix_vector_mul"];
//        if (!function) {
//            NSLog(@"无法找到指定的函数");
//            return 0;
//        }
//        id<MTLComputePipelineState> computePipelineState = [device newComputePipelineStateWithFunction:function error:&error];
//
//        // 开始计时
//        NSDate *startTime = [NSDate date];
//
//        // 分块处理矩阵的行
//        int block_size = 1024;  // 你可以根据 GPU 内存选择一个合适的块大小
//
//        for (int i = 0; i < csrMatrix.rows; i += block_size) {
//            int current_block_size = std::min(block_size, csrMatrix.rows - i);
//            
//            // 分块：每次只将 current_block_size 行传输到 GPU
//            MTLSize gridSize = MTLSizeMake(current_block_size, 1, 1);
//            MTLSize threadGroupSize = MTLSizeMake(1, 1, 1);  // 可以调整线程组大小以优化 GPU 性能
//
//            // 创建 GPU 编码器
//            id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
//            id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
//            [computeEncoder setComputePipelineState:computePipelineState];
//
//            // 传递当前块的行到 GPU
//            [computeEncoder setBuffer:valuesBuffer offset:(i * sizeof(float)) atIndex:0];
//            [computeEncoder setBuffer:colIndicesBuffer offset:(i * sizeof(int)) atIndex:1];
//            [computeEncoder setBuffer:rowPtrBuffer offset:(i * sizeof(int)) atIndex:2];
//            [computeEncoder setBuffer:vecBuffer offset:0 atIndex:3];  // 向量不需要分块
//            [computeEncoder setBuffer:resultBuffer offset:(i * sizeof(float)) atIndex:4];
//
//            // 提交当前块的计算任务给 GPU
//            [computeEncoder dispatchThreads:gridSize threadsPerThreadgroup:threadGroupSize];
//
//            // 结束编码
//            [computeEncoder endEncoding];
//            [commandBuffer commit];
//            [commandBuffer waitUntilCompleted];
//        }
//
//        // 结束计时
//        NSDate *endTime = [NSDate date];
//        NSTimeInterval elapsedTime = [endTime timeIntervalSinceDate:startTime];
//
//        // 读取 GPU 计算结果
//        float *resultPointer = (float *)[resultBuffer contents];
//        for (int i = 0; i < csrMatrix.rows; i++) {
//            resultArray[i] = resultPointer[i];
//        }
//
//        // 打印计算时间
//        NSLog(@"计算时间: %f 秒", elapsedTime);
//
//        // 打印结果（可选，只打印前10个）
//        NSLog(@"Result of CSR Matrix-Vector Multiplication (first 10 elements):");
//        for (int i = 0; i < 10; i++) {
//            NSLog(@"%f ", resultArray[i]);
//        }
//    }
//    return 0;
//}





#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <iostream>
#import <vector>
#import <fstream>
#import <sstream>
#import <chrono>

class CSRSparseMatrix {
public:
    std::vector<float> values;
    std::vector<int> col_indices;
    std::vector<int> row_ptr;
    int rows;
    int cols;

    CSRSparseMatrix(int rows, int cols) : rows(rows), cols(cols) {
        row_ptr.resize(rows + 1, 0);
    }

    void addElement(int row, int col, float value) {
        values.push_back(value);
        col_indices.push_back(col);
        row_ptr[row + 1]++;
    }

    void finalize() {
        for (int i = 1; i < row_ptr.size(); ++i) {
            row_ptr[i] += row_ptr[i - 1];
        }
    }
};

bool readMatrixMarketFile(const std::string& filename, CSRSparseMatrix& csrMatrix) {
    std::ifstream file(filename);
    if (!file.is_open()) {
        std::cerr << "无法打开文件: " << filename << std::endl;
        return false;
    }

    std::string line;
    while (std::getline(file, line)) {
        if (line[0] != '%') break;
    }

    std::istringstream iss(line);
    int rows, cols, nonZeroCount;
    iss >> rows >> cols >> nonZeroCount;

    csrMatrix = CSRSparseMatrix(rows, cols);

    int row, col;
    float value;
    while (file >> row >> col >> value) {
        csrMatrix.addElement(row - 1, col - 1, value);
    }

    csrMatrix.finalize();
    return true;
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        std::string filePath = "/Users/zhangmulin/Downloads/webbase-2001/webbase-2001.mtx";
        CSRSparseMatrix csrMatrix(0, 0);
        if (!readMatrixMarketFile(filePath, csrMatrix)) {
            return -1;
        }

        std::vector<float> vec(csrMatrix.cols, 1.0f);
        std::vector<float> resultArray(csrMatrix.rows, 0.0f);

        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        id<MTLCommandQueue> commandQueue = [device newCommandQueue];
        id<MTLLibrary> library = [device newDefaultLibrary];
        id<MTLFunction> function = [library newFunctionWithName:@"csr_matrix_vector_mul"];
        NSError *error = nil;
        
        
        
        id<MTLComputePipelineState> pipelineState = [device newComputePipelineStateWithFunction:function error:&error];

        id<MTLBuffer> valuesBuffer = [device newBufferWithBytes:csrMatrix.values.data()
                                                         length:csrMatrix.values.size() * sizeof(float)
                                                        options:MTLResourceStorageModeShared];
        
        id<MTLBuffer> colIndicesBuffer = [device newBufferWithBytes:csrMatrix.col_indices.data()
                                                             length:csrMatrix.col_indices.size() * sizeof(int)
                                                            options:MTLResourceStorageModeShared];
        
        id<MTLBuffer> rowPtrBuffer = [device newBufferWithBytes:csrMatrix.row_ptr.data()
                                                         length:csrMatrix.row_ptr.size() * sizeof(int)
                                                        options:MTLResourceStorageModeShared];
        
        id<MTLBuffer> vecBuffer = [device newBufferWithBytes:vec.data()
                                                      length:vec.size() * sizeof(float)
                                                     options:MTLResourceStorageModeShared];
        
        id<MTLBuffer> resultBuffer = [device newBufferWithLength:resultArray.size() * sizeof(float)
                                                         options:MTLResourceStorageModeShared];

        auto start = std::chrono::high_resolution_clock::now();

        id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
        id<MTLComputeCommandEncoder> encoder = [commandBuffer computeCommandEncoder];
        [encoder setComputePipelineState:pipelineState];
        [encoder setBuffer:valuesBuffer offset:0 atIndex:0];
        [encoder setBuffer:colIndicesBuffer offset:0 atIndex:1];
        [encoder setBuffer:rowPtrBuffer offset:0 atIndex:2];
        [encoder setBuffer:vecBuffer offset:0 atIndex:3];
        [encoder setBuffer:resultBuffer offset:0 atIndex:4];

        MTLSize gridSize = MTLSizeMake(csrMatrix.rows, 1, 1);
        MTLSize threadGroupSize = MTLSizeMake(1, 1, 1);
        [encoder dispatchThreads:gridSize threadsPerThreadgroup:threadGroupSize];
        [encoder endEncoding];
        
        [commandBuffer commit];
        [commandBuffer waitUntilCompleted];

//        auto end = std::chrono::high_resolution_clock::now();
//        auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
//
//        std::cout << "SpMV execution time on GPU: " << elapsed.count() << " ms" << std::endl;
        // 结束计时
        auto end = std::chrono::high_resolution_clock::now();
        auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
        float elapsedInSeconds = elapsed.count() / 1000.0f;  // 转换为秒

        // 打印运行时间（以秒为单位）
        std::cout << "SpMV execution time on GPU: " << elapsedInSeconds << " s" << std::endl;

        float *resultPointer = (float *)[resultBuffer contents];
        for (int i = 0; i < csrMatrix.rows; i++) {
            resultArray[i] = resultPointer[i];
        }

        std::cout << "Result (first 10 elements): ";
        for (int i = 0; i < std::min(10, (int)resultArray.size()); ++i) {
            std::cout << resultArray[i] << " ";
        }
        std::cout << std::endl;
    }
    return 0;
}
