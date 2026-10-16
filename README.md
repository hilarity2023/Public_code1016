# Order Spectrum Based Fault Diagnosis / 基于阶次谱的故障诊断

## English

### Overview

This folder contains MATLAB and Python code for order spectrum preprocessing, runtime measurement, synthetic sample generation, and ResNet18-based classification. The descriptions below refer to the current scripts and their default configurations. Measured datasets and trained model weights are not included.

### Files

| File | Function |
| --- | --- |
| `demo0122_2_timing.m` | Reads a sample list from Excel, locates the corresponding MAT files, aligns audio and speed signals, performs audio preprocessing, STFT and order conversion, optionally applies wavelet processing or directional filtering and NEP, and exports order spectrum images and runtime statistics. The required processing functions are included as local functions. |
| `genarate.m` | Constructs synthetic order spectra by superimposing triangular peaks with randomized amplitudes, positions and widths. Selected configurations also add interfering peaks or remove peaks. Spectra are repeated along the time axis and exported as images. The currently enabled section generates 50 hub-bearing images with a characteristic-order spacing of 0.8; other generation sections are commented out. |
| `model1120.py` | Defines the `Residual` block and a ResNet18-style classifier with configurable input channels and number of classes. Running this file directly prints example model summaries. |
| `classes5_train_3methods_multi_runs.py` | Trains and evaluates classifiers for unfiltered, wavelet-processed and directionally filtered images, including order-coordinate input variants. Repeats training with multiple random seeds and saves model weights, training logs, per-run results and summary statistics. |
| `classes5_test_3methods.py` | Provides test data loading and evaluation functions used by the training script. Reports accuracy, macro F1, a classification report and a confusion matrix, and saves prediction and misclassification logs. It also includes a standalone checkpoint evaluation entry point. |

### Dependencies

- MATLAB with functions from Signal Processing Toolbox, Audio Toolbox, Image Processing Toolbox and Wavelet Toolbox, depending on the selected processing mode. A version supporting script-local functions and `exportgraphics` is required.
- Python packages: `torch`, `torchvision`, `numpy`, `pandas`, `matplotlib`, `seaborn`, `scikit-learn`, `torchsummary`, and `Pillow`.
- A compatible CUDA environment is optional; the Python scripts select CUDA when available and otherwise use the CPU.

Example Python dependency installation:

```bash
pip install torch torchvision numpy pandas matplotlib seaborn scikit-learn torchsummary Pillow
```

Package versions are not pinned in this release; configure compatible PyTorch and torchvision versions for your environment.

### MATLAB preprocessing and timing

Edit `excelFile`, `searchRoot`, `outputDir`, `numRuns` and `mode` at the beginning of `demo0122_2_timing.m` before running it.

| Mode | Processing |
| --- | --- |
| `1` | Apply `dwt_max1` during audio preprocessing; skip directional filtering and NEP. |
| `2` | Skip `dwt_max1`; apply the local `filter1010Timed` function after order conversion. |
| `3` | Skip both optional processing branches. |

The current defaults are `mode = 3` and `numRuns = 5`. The script reads sample names from the first Excel column and currently indexes the first 100 valid entries. Supply at least 100 entries or adapt the loop to your list length. MAT inputs must follow the signal structure expected by `processOneMat`, including `Signal_0`, `Signal_1`, nested signal values, and an audio sampling interval.

Outputs are written to `E:\data\_timing_benchmark` by default:

- Order spectrum images (`.jpg`) and MATLAB figures (`.fig`).
- `timing_per_run_<mode>.csv`: accumulated stage times and success/failure counts for each dataset pass.
- `timing_summary_<mode>.csv`: mean and sample standard deviation across repeated passes, plus values divided by the number of listed files found.

Timing covers input loading/alignment, audio preprocessing, STFT, order conversion, directional filtering, NEP and image export. Excel reading and initial file searching are excluded. One sample is used for warm-up, which is excluded from the reported statistics. Check failure counts when interpreting the results. Repeated passes reuse output filenames.

For synthetic images, configure the desired section and output directory in `genarate.m`, and create the output directory before execution. This script constructs idealized order-domain patterns, not time-domain acoustic signals. It does not add Gaussian or measured background noise. Random variations occur between peaks and samples; the repeated image does not introduce temporal fluctuations.

### Python training and evaluation

Keep the three Python files together. Prepare grayscale images at 224 × 224 pixels; these scripts do not perform image resizing. The expected dataset layout is:

```text
E:\classes5_224gray\
  noFilter\
    train\<class_name>\<image files>
    test\<class_name>\<image files>
  WTfilter\
    train\<class_name>\<image files>
    test\<class_name>\<image files>
  DirFilter\
    train\<class_name>\<image files>
    test\<class_name>\<image files>
```

Use consistent class folders across methods and splits. Training images are matched across methods by filename stem after removing `_filter` and `_dwt`; use unique sample stems across classes.

Supported input modes:

- `single`: grayscale image only.
- `order`: grayscale image plus a normalized horizontal order-coordinate channel.
- `order3`: grayscale image plus the order-coordinate channel and its square.

The coordinate map varies horizontally and is repeated vertically inside the configured plot region. Adjust the image-margin parameters if your image layout differs.

Run training after configuring dataset paths and parameters:

```bash
python classes5_train_3methods_multi_runs.py
```

The current script runs five configurations using seeds `[1, 2, 3]`, 5 epochs, batch size 256 and 5 classes. It uses Adam with learning rate 0.001 and cross-entropy loss. **The train/validation partition is created once using seed 42 and reused across runs; changing training seeds does not repartition the dataset.** Test images are read from the separate test directories. Multiple `MEAN_STD_DICT` definitions are present; the last definition takes effect. Set normalization statistics for your own training data.

Outputs in the working directory include `best_model_<tag>.pth`, `trainlog_<tag>.csv`, prediction logs, confusion matrices, `all_runs_results.csv` and `summary_results.csv`.

For standalone evaluation, configure `weight_path`, `root_test`, `mode`, `num_classes` and normalization arguments in `classes5_test_3methods.py`, then run:

```bash
python classes5_test_3methods.py
```

The standalone example currently uses 8 classes, whereas the training entry point uses 5. Match the class count, input mode and normalization to the checkpoint. Update `SIMHEI_PATH` if the configured Windows font is unavailable.

All `E:\...` paths are example locations and should be adapted to your machine. These scripts require separately prepared inputs; this folder does not include a complete automated raw-data-to-training-image preparation workflow.

---

## 中文

### 项目简介

本文件夹提供用于阶次谱预处理、运行时间统计、合成样本生成及 ResNet18 分类的 MATLAB 和 Python 代码。以下说明对应当前脚本及其默认配置，不包含实测数据集或已训练的模型权重。

### 文件功能

| 文件 | 功能 |
| --- | --- |
| `demo0122_2_timing.m` | 从 Excel 读取样本列表并查找对应 MAT 文件，完成音频与速度信号对齐、音频预处理、STFT 和阶次转换，可选择小波处理或方向滤波与 NEP，输出阶次谱图像及运行时间统计。相关处理函数已作为局部函数包含在文件内。 |
| `genarate.m` | 通过叠加三角形峰构建合成阶次谱，对峰幅值、位置和宽度进行随机化，并在部分配置中加入干扰峰或删除峰。沿时间轴重复阶次谱后导出图像。当前启用轮毂轴承部分，生成 50 张特征阶次间隔为 0.8 的图像；其他生成部分处于注释状态。 |
| `model1120.py` | 定义 `Residual` 残差模块及 ResNet18 结构的分类器，支持配置输入通道数和类别数。直接运行时输出示例模型的结构摘要。 |
| `classes5_train_3methods_multi_runs.py` | 对未滤波、小波处理和方向滤波图像开展训练与评估，并比较阶次坐标输入配置。使用多个随机种子重复训练，保存模型权重、训练日志、逐次结果和汇总统计。 |
| `classes5_test_3methods.py` | 为训练脚本提供测试集加载和评估函数，输出准确率、宏平均 F1、分类报告和混淆矩阵，保存预测与误分类日志；同时提供独立加载权重进行评估的入口。 |

### 环境依赖

- MATLAB：根据所选模式，需要 Signal Processing Toolbox、Audio Toolbox、Image Processing Toolbox 和 Wavelet Toolbox 中的函数；版本需支持脚本局部函数及 `exportgraphics`。
- Python：`torch`、`torchvision`、`numpy`、`pandas`、`matplotlib`、`seaborn`、`scikit-learn`、`torchsummary` 和 `Pillow`。
- CUDA 为可选项；Python 脚本在 CUDA 可用时使用 GPU，否则使用 CPU。

Python 依赖安装示例：

```bash
pip install torch torchvision numpy pandas matplotlib seaborn scikit-learn torchsummary Pillow
```

本次发布未固定依赖版本，请根据运行环境选择相互兼容的 PyTorch 和 torchvision 版本。

### MATLAB 预处理与计时

运行 `demo0122_2_timing.m` 前，修改开头的 `excelFile`、`searchRoot`、`outputDir`、`numRuns` 和 `mode`。

| 模式 | 处理方式 |
| --- | --- |
| `1` | 在音频预处理阶段使用 `dwt_max1`，跳过方向滤波与 NEP。 |
| `2` | 不使用 `dwt_max1`，在阶次转换后调用局部函数 `filter1010Timed`。 |
| `3` | 不使用上述两个可选处理分支。 |

当前默认设置为 `mode = 3`、`numRuns = 5`。脚本从 Excel 第一列读取样本名，当前循环访问前 100 个有效条目。请提供至少 100 个条目，或根据列表长度调整循环。MAT 文件需符合 `processOneMat` 中使用的信号结构，包括 `Signal_0`、`Signal_1`、嵌套信号数值及音频采样间隔。

默认输出目录为 `E:\data\_timing_benchmark`，包含：

- 阶次谱图像（`.jpg`）和 MATLAB 图形文件（`.fig`）。
- `timing_per_run_<mode>.csv`：每轮完整数据处理的阶段累计耗时及成功、失败数量。
- `timing_summary_<mode>.csv`：多轮耗时的均值、样本标准差，以及除以列表中已找到文件数量后的结果。

计时阶段包括读取与对齐、音频预处理、STFT、阶次转换、方向滤波、NEP 和图像导出。Excel 读取及初始文件搜索不计入各轮耗时；使用一个样本进行预热，预热不计入统计。解释统计结果时需同时查看失败数量。多轮处理会复用输出文件名。

生成合成图像时，在 `genarate.m` 中选择需要启用的部分、设置输出路径，并提前创建输出目录。该脚本直接构建理想化阶次域模式，不生成时域声音信号，也未加入高斯噪声或实测背景噪声。随机变化发生在不同峰和样本之间，沿时间轴重复不会引入随时间变化的波动。

### Python 训练与测试

将三个 Python 文件放在同一目录。输入图像应提前处理为 224 × 224 像素的灰度图，这些脚本不执行图像缩放。数据目录结构如下：

```text
E:\classes5_224gray\
  noFilter\
    train\<类别名>\<图像文件>
    test\<类别名>\<图像文件>
  WTfilter\
    train\<类别名>\<图像文件>
    test\<类别名>\<图像文件>
  DirFilter\
    train\<类别名>\<图像文件>
    test\<类别名>\<图像文件>
```

不同方法及训练、测试目录需使用一致的类别文件夹。训练样本通过去除 `_filter`、`_dwt` 后的文件名主体进行跨方法匹配，因此不同类别之间的样本文件名主体也应唯一。

支持三种输入配置：

- `single`：仅灰度图像。
- `order`：灰度图像与归一化的横向阶次坐标通道。
- `order3`：灰度图像、阶次坐标通道及其平方通道。

坐标通道在配置的绘图区内沿水平方向变化，沿竖直方向重复。如果图像版式不同，需要修改图像边距参数。

配置数据路径和训练参数后运行：

```bash
python classes5_train_3methods_multi_runs.py
```

当前脚本包含五种实验配置，随机种子为 `[1, 2, 3]`，训练轮数为 5，批量大小为 256，类别数为 5；使用学习率为 0.001 的 Adam 优化器和交叉熵损失。**当前训练/验证划分使用种子 42 一次性生成，并在多次训练中复用；改变训练随机种子不会重新划分数据集。** 测试图像来自独立的测试目录。脚本中存在多次 `MEAN_STD_DICT` 定义，实际生效的是最后一次定义，请根据自己的训练数据设置归一化统计量。

工作目录中的输出包括 `best_model_<tag>.pth`、`trainlog_<tag>.csv`、预测日志、混淆矩阵、`all_runs_results.csv` 和 `summary_results.csv`。

独立测试时，在 `classes5_test_3methods.py` 中配置 `weight_path`、`root_test`、`mode`、`num_classes` 和归一化参数，然后运行：

```bash
python classes5_test_3methods.py
```

独立测试示例当前设置为 8 类，训练入口设置为 5 类。类别数、输入模式及归一化参数需要与权重文件匹配。如果系统中没有指定的 Windows 字体，请修改 `SIMHEI_PATH`。

所有 `E:\...` 均为示例路径，使用前需根据本机环境调整。本文件夹需要另行准备输入数据，未包含从原始数据到训练图像的完整自动化整理流程。
