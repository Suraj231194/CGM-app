#ifndef SG_FILTER_H
#define SG_FILTER_H

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include <ctype.h>
#include <errno.h>

// 线性回归结构体
typedef struct {
    double slope;
    double intercept;
} LinregResult;

// 函数声明
/**
 * @brief 执行线性回归分析
 * 
 * 使用最小二乘法对给定的x和y数据点进行线性回归分析，
 * 计算斜率和截距等回归参数
 * 
 * @param x[] x坐标值数组
 * @param y[] y坐标值数组  
 * @param n 数据点的数量
 * @return LinregResult 包含斜率、截距、相关系数等回归结果的结构体
 */
LinregResult linregress(double x[], double y[], int n);

/**
 * @brief SG滤波算法单元
 * 
 * @param SG_val_list 原始值数组，可以是任意长度
 * @param list_size SG_val_list数组的长度
 * @param SG_val_list_pre 前6个原始值，必须为长度为6的数组，
 *                        作为SG_val_list[0]的前6个历史原始值
 * @param SG_val_fil_pre 前一个算法计算后的血糖值
 * @param cal 校准参数
 * @param time_index 前一个血糖值index
 * @param input_string code码字串
 * @return double* 返回处理后的数据数组指针，长度与SG_val_list相同
 */
double* SG_filter_outlier(double* SG_val_list, int list_size, 
                         double* SG_val_list_pre, 
                         double SG_val_fil_pre,
                         double cal,
                         int time_index,
                         char *input_string);
void test_SG_filter();

#endif