//
//  SpMV.metal
//  SpMVTest
//
//  Created by 张木林 on 9/30/24.
//

#include <metal_stdlib>
using namespace metal;







kernel void csr_matrix_vector_mul(
    constant float* values [[buffer(0)]],
    constant int* col_indices [[buffer(1)]],
    constant int* row_ptr [[buffer(2)]],
    constant float* vec [[buffer(3)]],
    device float* result [[buffer(4)]],
    uint gid [[thread_position_in_grid]]
) {
    // 每个线程处理矩阵的一行
    if (gid < row_ptr[0]) return;  // 行数以 row_ptr[0] 的长度为准

    int row_start = row_ptr[gid];
    int row_end = row_ptr[gid + 1];
    float sum = 0.0;

    // 遍历当前行的所有非零元素
    for (int j = row_start; j < row_end; j++) {
        sum += values[j] * vec[col_indices[j]];
    }

    // 将结果写入 result 缓冲区
    result[gid] = sum;
}
