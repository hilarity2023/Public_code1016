# train_multi_runs_originIMG.py

import copy
import time
import torch
from torchvision.datasets import ImageFolder
from torchvision import transforms
import torch.utils.data as Data
from torch.utils.data import Subset
import numpy as np
import matplotlib.pyplot as plt
from model1120 import ResNet18, Residual
import torch.nn as nn
import pandas as pd
import os
import random

from classes5_test_3methods import build_test_loader, test_model_process  # 测试模块

os.environ['KMP_DUPLICATE_LIB_OK'] = 'TRUE'
PROCESSED_ROOT = r"E:\classes5_224gray"
# ========================== 1. 随机种子 ==========================

def setup_seed(seed=42):
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)
    torch.backends.cudnn.deterministic = False
    torch.backends.cudnn.benchmark = True


# ========================== 2. 归一化参数 & 阶次模板 ==========================
# 仅使用原始数据集做模型训练时的归一化参数
MEAN_STD_DICT = {
    "noFilter": (0.2769222712, 0.2282527316),
    "WTfilter": (0.0873140235, 0.2085373184),
    "DirFilter": (0.0584046804, 0.2061348321),
}
# 各类型中添加50个理想数据，做模型训练时的归一化参数
MEAN_STD_DICT = {
    "noFilter": (0.1541902107, 0.2189556438),
    "WTfilter": (0.0723139219, 0.2104421700),
    "DirFilter": (0.0598303420, 0.2094047327),
}

# 使用提供的“第一批数据”时，带有理想数据情况下的归一化参数
MEAN_STD_DICT = {
    "noFilter": (0.2207996066, 0.2327668714),
    "WTfilter": (0.0743728133, 0.2125352032),
    "DirFilter": (0.0640122214, 0.2133335465),
}

# 单通道归一化参数（沿用你之前的）
# MEAN = 0.0615453766584048
# STD  = 0.05967102034949946

# 预处理后都是 224×224
RESIZE_W = 224
RESIZE_H = 224

# 原始白边信息（你的代码里已有）
W_RAW = 6848
H_RAW = 3181
LEFT_MARGIN_RAW   = 20
RIGHT_MARGIN_RAW  = 46
TOP_MARGIN_RAW    =5
BOTTOM_MARGIN_RAW = 118

LEFT_RATIO   = LEFT_MARGIN_RAW   / W_RAW
RIGHT_RATIO  = RIGHT_MARGIN_RAW  / W_RAW
TOP_RATIO    = TOP_MARGIN_RAW    / H_RAW
BOTTOM_RATIO = BOTTOM_MARGIN_RAW / H_RAW

def build_order_map(H=RESIZE_H, W=RESIZE_W):
    """只在导入脚本时调用一次，生成 (1, H, W) 的阶次矩阵"""
    left_margin   = int(round(LEFT_RATIO   * W))
    right_margin  = int(round(RIGHT_RATIO  * W))
    top_margin    = int(round(TOP_RATIO    * H))
    bottom_margin = int(round(BOTTOM_RATIO * H))

    x0 = left_margin
    x1 = W - right_margin
    y0 = top_margin
    y1 = H - bottom_margin

    valid_w = max(x1 - x0, 1)
    valid_h = max(y1 - y0, 1)

    order = torch.zeros((H, W), dtype=torch.float32)
    x_ramp = torch.linspace(0., 1., steps=valid_w, dtype=torch.float32)
    ramp_2d = x_ramp.view(1, valid_w).expand(valid_h, valid_w)
    order[y0:y1, x0:x1] = ramp_2d

    order = order.unsqueeze(0)  # (1,H,W)
    return order

# 全局模板（CPU 上）
ORDER_MAP = build_order_map()          # (1,224,224)
ORDER_MAP_SQ = ORDER_MAP ** 2         # 阶次平方 (1,224,224)


def add_order_channel(t: torch.Tensor):
    """
    原来的 2 通道版：
    输入 t: (1,H,W) 单通道灰度图
    输出:  (2,H,W) [原图, order]
    """
    assert t.dim() == 3 and t.shape[0] == 1
    # 把 ORDER_MAP 移动到和 t 相同的 device
    order = ORDER_MAP.to(t.device)
    x_2ch = torch.cat([t, order], dim=0)
    return x_2ch


def add_order_channel_3(t: torch.Tensor):
    """
    新增 3 通道版：
    输入 t: (1,H,W)
    输出:  (3,H,W) [原图, order, order^2]
    """
    assert t.dim() == 3 and t.shape[0] == 1
    order = ORDER_MAP.to(t.device)
    order_sq = ORDER_MAP_SQ.to(t.device)
    x_3ch = torch.cat([t, order, order_sq], dim=0)
    return x_3ch


def get_transform(mode: str, mean: float, std: float):
    """
    mode:
      'single' → 1 通道灰度
      'order'  → 2 通道 (原 + 阶次)
      'order3' → 3 通道 (原 + 阶次 + 阶次平方)
    注意：这里不再 Resize/Grayscale，因为已在预处理阶段完成。
    """
    if mode == 'single':
        return transforms.Compose([
            transforms.Grayscale(),
            transforms.ToTensor(),
            transforms.Normalize([mean], [std]),
        ])
    elif mode == 'order':
        return transforms.Compose([
            transforms.Grayscale(),
            transforms.ToTensor(),
            transforms.Normalize([mean], [std]),
            transforms.Lambda(add_order_channel),
        ])
    elif mode == 'order3':
        return transforms.Compose([
            transforms.Grayscale(),
            transforms.ToTensor(),
            transforms.Normalize([mean], [std]),
            transforms.Lambda(add_order_channel_3),
        ])
    else:
        raise ValueError(f"Unknown mode: {mode}")


# ========================== 3. 构建固定划分的 DataLoader ==========================
# 默认先用 DirFilter 的 train 做划分，后面每个方法覆盖 root_train
ROOT_TRAIN_DEFAULT = os.path.join(PROCESSED_ROOT, "DirFilter", "train")
ROOT_TEST_DEFAULT  = os.path.join(PROCESSED_ROOT, "DirFilter", "test")

def build_aligned_splits_three_roots(root_no, root_wt, root_dir, train_ratio=0.8):
    """
    输入：三个方法各自的 train 路径
    输出：
      indices_no_train, indices_no_val,
      indices_wt_train, indices_wt_val,
      indices_dir_train, indices_dir_val
    """
    # 1. 分别构建 ImageFolder（transform=None）
    ds_no  = ImageFolder(root_no, transform=None)
    ds_wt  = ImageFolder(root_wt, transform=None)
    ds_dir = ImageFolder(root_dir, transform=None)

    # 2. 扫描 samples，构建 id -> idx 映射
    def build_id2idx(ds):
        d = {}
        for idx, (path, _) in enumerate(ds.samples):
            name = os.path.basename(path)
            stem, _ = os.path.splitext(name)  # 先去掉 .jpg/.png 等
            # 去掉后缀标志
            stem = stem.replace("_filter", "").replace("_dwt", "")
            d[stem] = idx
        return d

    id2idx_no  = build_id2idx(ds_no)
    id2idx_wt  = build_id2idx(ds_wt)
    id2idx_dir = build_id2idx(ds_dir)

    # 3. 求三个的交集 ID
    common_ids = sorted(set(id2idx_no) & set(id2idx_wt) & set(id2idx_dir))

    # 4. 做一次随机划分
    rng = np.random.RandomState(42)
    rng.shuffle(common_ids)
    n_total = len(common_ids)
    n_train = int(train_ratio * n_total)
    train_ids = common_ids[:n_train]
    val_ids   = common_ids[n_train:]

    # 5. 映射回各自数据集 indices
    train_idx_no = [id2idx_no[i] for i in train_ids]
    val_idx_no   = [id2idx_no[i] for i in val_ids]

    train_idx_wt = [id2idx_wt[i] for i in train_ids]
    val_idx_wt   = [id2idx_wt[i] for i in val_ids]

    train_idx_dir = [id2idx_dir[i] for i in train_ids]
    val_idx_dir   = [id2idx_dir[i] for i in val_ids]

    return (train_idx_no,  val_idx_no,
            train_idx_wt,  val_idx_wt,
            train_idx_dir, val_idx_dir)


def get_dataloaders(train_indices, val_indices,
                    mode, batch_size=256,
                    root_train: str = None,
                    root_test: str = None,
                    mean: float = 0.0,
                    std: float = 1.0):
    """
    根据固定的 train/val 索引 + 当前 mode 的 transform
    构建 train/val/test dataloader
    """
    if root_train is None:
        root_train = ROOT_TRAIN_DEFAULT
    if root_test is None:
        root_test = ROOT_TEST_DEFAULT

    transform = get_transform(mode, mean, std)

    full_train_dataset = ImageFolder(root_train, transform=transform)
    train_dataset = Subset(full_train_dataset, train_indices)
    val_dataset   = Subset(full_train_dataset, val_indices)

    test_dataset  = ImageFolder(root_test, transform=transform)

    pin_mem = torch.cuda.is_available()
    train_loader = Data.DataLoader(train_dataset, batch_size=batch_size,
                                   shuffle=True, num_workers=4, pin_memory=pin_mem)
    val_loader   = Data.DataLoader(val_dataset, batch_size=batch_size,
                                   shuffle=False, num_workers=4, pin_memory=pin_mem)
    test_loader  = Data.DataLoader(test_dataset, batch_size=batch_size,
                                   shuffle=False, num_workers=4, pin_memory=pin_mem)
    return train_loader, val_loader, test_loader


# ========================== 4. 训练一个模型 ==========================

def train_model_once(model, train_loader, val_loader, num_epochs, tag=""):
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print("Device:", device)

    optimizer = torch.optim.Adam(model.parameters(), lr=0.001)
    criterion = nn.CrossEntropyLoss()
    model = model.to(device)

    best_model_wts = copy.deepcopy(model.state_dict())
    best_acc = 0.0

    train_loss_all, val_loss_all = [], []
    train_acc_all,  val_acc_all  = [], []

    since = time.time()

    for epoch in range(num_epochs):
        print("Epoch {}/{} is running".format(epoch + 1, num_epochs))
        print("-" * 10)

        train_loss = 0.0
        val_loss   = 0.0
        train_corrects = 0
        val_corrects   = 0
        train_num = 0
        val_num   = 0

        # ---- train ----
        model.train()
        for b_x, b_y in train_loader:
            b_x = b_x.to(device)
            b_y = b_y.to(device)

            output = model(b_x)
            pre_lab = torch.argmax(output, dim=1)
            loss = criterion(output, b_y)

            optimizer.zero_grad()
            loss.backward()
            optimizer.step()

            train_loss += loss.item() * b_x.size(0)
            train_corrects += torch.sum(pre_lab == b_y.data)
            train_num += b_x.size(0)

        # ---- val ----
        model.eval()
        with torch.no_grad():
            for b_x, b_y in val_loader:
                b_x = b_x.to(device)
                b_y = b_y.to(device)

                output = model(b_x)
                pre_lab = torch.argmax(output, dim=1)
                loss = criterion(output, b_y)

                val_loss += loss.item() * b_x.size(0)
                val_corrects += torch.sum(pre_lab == b_y.data)
                val_num += b_x.size(0)

        train_loss_epoch = train_loss / train_num
        val_loss_epoch   = val_loss / val_num
        train_acc_epoch  = train_corrects.double().item() / train_num
        val_acc_epoch    = val_corrects.double().item() / val_num

        train_loss_all.append(train_loss_epoch)
        val_loss_all.append(val_loss_epoch)
        train_acc_all.append(train_acc_epoch)
        val_acc_all.append(val_acc_epoch)

        print("{} train loss:{:.4f} train acc:{:.4f}".format(epoch, train_loss_epoch, train_acc_epoch))
        print("{} val   loss:{:.4f} val   acc:{:.4f}".format(epoch, val_loss_epoch, val_acc_epoch))

        if val_acc_epoch > best_acc:
            best_acc = val_acc_epoch
            best_model_wts = copy.deepcopy(model.state_dict())

        time_use = time.time() - since
        print("time used: {:.0f}m {:.0f}s".format(time_use // 60, time_use % 60))

    # 还原 best 权重
    model.load_state_dict(best_model_wts)

    # 保存训练过程
    df = pd.DataFrame({
        "epoch": list(range(1, len(train_loss_all)+1)),
        "train_loss_all": train_loss_all,
        "val_loss_all":   val_loss_all,
        "train_acc_all":  train_acc_all,
        "val_acc_all":    val_acc_all
    })
    if tag:
        df.to_csv(f'trainlog_{tag}.csv', index=False)

    # 保存模型
    if tag:
        torch.save(best_model_wts, f'best_model_{tag}.pth')

    return model, df, best_acc


# ========================== 5. 主实验：多方法 × 多 seed ==========================

if __name__ == '__main__':
    # 预处理后数据集根目录（和 data_preprocess_originIMG.py 对应）
    PROCESSED_ROOT = r"E:\classes5_224gray"

    root_no  = os.path.join(PROCESSED_ROOT, "noFilter", "train")
    root_wt  = os.path.join(PROCESSED_ROOT, "WTfilter", "train")
    root_dir = os.path.join(PROCESSED_ROOT, "DirFilter", "train")

    (train_no,  val_no,
    train_wt,  val_wt,
    train_dir, val_dir) = build_aligned_splits_three_roots(root_no, root_wt, root_dir)  

    # 4+1 种实验设置：
    #   - noFilter：single
    #   - WTfilter：single
    #   - DirFilter：single, order(2ch), order3(3ch)
    EXPERIMENTS = [
        {
            "exp_name": "noFilter_single",
            "mode": "single",
            "root_train": os.path.join(PROCESSED_ROOT, "noFilter", "train"),
            "root_test":  os.path.join(PROCESSED_ROOT, "noFilter", "test"),
            "dataset_key": "noFilter",      # ★ 新增
        },
        {
            "exp_name": "WTfilter_single",
            "mode": "single",
            "root_train": os.path.join(PROCESSED_ROOT, "WTfilter", "train"),
            "root_test":  os.path.join(PROCESSED_ROOT, "WTfilter", "test"),
            "dataset_key": "WTfilter",      # ★ 新增
        },
        {
            "exp_name": "DirFilter_single",
            "mode": "single",
            "root_train": os.path.join(PROCESSED_ROOT, "DirFilter", "train"),
            "root_test":  os.path.join(PROCESSED_ROOT, "DirFilter", "test"),
            "dataset_key": "DirFilter",     # ★ 新增
        },
        {
            "exp_name": "DirFilter_order2",
            "mode": "order",
            "root_train": os.path.join(PROCESSED_ROOT, "DirFilter", "train"),
            "root_test":  os.path.join(PROCESSED_ROOT, "DirFilter", "test"),
            "dataset_key": "DirFilter",     # ★ 新增
        },
        {
            "exp_name": "DirFilter_order3",
            "mode": "order3",
            "root_train": os.path.join(PROCESSED_ROOT, "DirFilter", "train"),
            "root_test":  os.path.join(PROCESSED_ROOT, "DirFilter", "test"),
            "dataset_key": "DirFilter",     # ★ 新增
        },
    ]


    SEEDS = [1, 2, 3]
    NUM_EPOCHS = 5
    BATCH_SIZE = 256
    NUM_CLASSES = 5   # 或 7，看你数据集实际类别数

    all_results = []

    for exp in EXPERIMENTS:
        exp_name   = exp["exp_name"]
        mode       = exp["mode"]
        root_train = exp["root_train"]
        root_test  = exp["root_test"]
        dataset_key = exp["dataset_key"]
        mean, std = MEAN_STD_DICT[dataset_key]

        print("\n" + "#" * 70)
        print(f"Experiment: {exp_name} | mode = {mode}")
        print("#" * 70)

        if dataset_key == "noFilter":
            train_indices = train_no
            val_indices   = val_no
        elif dataset_key == "WTfilter":
            train_indices = train_wt
            val_indices   = val_wt
        elif dataset_key == "DirFilter":
            train_indices = train_dir
            val_indices   = val_dir
        else:
            raise ValueError("Unknown dataset_key")

        for run_id, seed in enumerate(SEEDS, start=1):
            print("=" * 60)
            print(f"  Run {run_id} | Seed = {seed}")
            print("=" * 60)

            setup_seed(seed)

            train_loader, val_loader, _ = get_dataloaders(
                train_indices, val_indices,
                mode=mode, batch_size=BATCH_SIZE,
                root_train=root_train, root_test=root_test,
                mean=mean, std=std
            )

            in_channels = {
                "single": 1,
                "order":  2,
                "order3": 3,
            }[mode]

            model = ResNet18(Residual, in_channels=in_channels, num_classes=NUM_CLASSES)

            tag = f"{exp_name}_run{run_id}_seed{seed}"
            model, df_train, best_val_acc = train_model_once(
                model, train_loader, val_loader,
                num_epochs=NUM_EPOCHS, tag=tag
            )

            # ====== 测试阶段 ======
            test_loader, classes, samples = build_test_loader(
                mode=mode,
                batch_size=BATCH_SIZE,
                root_test=root_test,
                mean = mean,
                std = std
            )

            test_acc, macro_f1 = test_model_process(
                model,
                test_loader,
                classes,
                samples,
                tag=tag
            )

            all_results.append({
                "exp_name": exp_name,
                "mode": mode,
                "run": run_id,
                "seed": seed,
                "best_val_acc": best_val_acc,
                "test_acc": test_acc,
                "macro_F1": macro_f1,
            })

    # 保存所有 raw 结果
    results_df = pd.DataFrame(all_results)
    results_df.to_csv("all_runs_results.csv", index=False)

    # 按 exp_name 汇总 mean/std
    summary = results_df.groupby("exp_name")[["test_acc", "macro_F1"]].agg(["mean", "std"])
    summary.to_csv("summary_results.csv")
    print("\nSummary:")
    print(summary)