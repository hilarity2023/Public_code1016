import os
import torch
import numpy as np
from torchvision.datasets import ImageFolder
from torchvision import transforms
import torch.utils.data as Data
import matplotlib.pyplot as plt
import seaborn as sns

from sklearn.metrics import (
    confusion_matrix,
    classification_report,
    f1_score,
)

from matplotlib.font_manager import FontProperties

# =============== 基本配置 & 阶次模板（与训练保持一致） ===============
# 默认测试集路径（会被训练脚本传入覆盖）
ROOT_TEST_DEFAULT = r"E:\classes5_224gray\DirFilter\test"

RESIZE_W = 224
RESIZE_H = 224

W_RAW = 6848
H_RAW = 3181
LEFT_MARGIN_RAW   = 20
RIGHT_MARGIN_RAW  = 46
TOP_MARGIN_RAW    = 5
BOTTOM_MARGIN_RAW = 118

LEFT_RATIO   = LEFT_MARGIN_RAW   / W_RAW
RIGHT_RATIO  = RIGHT_MARGIN_RAW  / W_RAW
TOP_RATIO    = TOP_MARGIN_RAW    / H_RAW
BOTTOM_RATIO = BOTTOM_MARGIN_RAW / H_RAW

def build_order_map(H=RESIZE_H, W=RESIZE_W):
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

    order = order.unsqueeze(0)
    return order

ORDER_MAP = build_order_map()
ORDER_MAP_SQ = ORDER_MAP ** 2

SIMHEI_PATH = r"C:\Windows\Fonts\simhei.ttf"  # 改成你自己机器的黑体路径


def add_order_channel(t: torch.Tensor):
    assert t.dim() == 3 and t.shape[0] == 1
    order = ORDER_MAP.to(t.device)
    x_2ch = torch.cat([t, order], dim=0)
    return x_2ch

def add_order_channel_3(t: torch.Tensor):
    assert t.dim() == 3 and t.shape[0] == 1
    order = ORDER_MAP.to(t.device)
    order_sq = ORDER_MAP_SQ.to(t.device)
    x_3ch = torch.cat([t, order, order_sq], dim=0)
    return x_3ch


def get_test_transform(mode: str, mean: float, std: float):
    if mode == "single":
        return transforms.Compose([
            transforms.Grayscale(),
            transforms.ToTensor(),
            transforms.Normalize([mean], [std]),
        ])
    elif mode == "order":
        return transforms.Compose([
            transforms.Grayscale(),
            transforms.ToTensor(),
            transforms.Normalize([mean], [std]),
            transforms.Lambda(add_order_channel),
        ])
    elif mode == "order3":
        return transforms.Compose([
            transforms.Grayscale(),
            transforms.ToTensor(),
            transforms.Normalize([mean], [std]),
            transforms.Lambda(add_order_channel_3),
        ])
    else:
        raise ValueError(f"Unknown mode: {mode}")


def build_test_loader(mode: str,
                      batch_size: int = 256,
                      root_test: str = None,
                      mean: float = 0.0,
                      std: float =1.0):
    if root_test is None:
        root_test = ROOT_TEST_DEFAULT

    transform = get_test_transform(mode, mean, std)
    test_dataset = ImageFolder(root_test, transform=transform)

    test_loader = Data.DataLoader(
        test_dataset,
        batch_size=batch_size,
        shuffle=False,
        num_workers=2
    )

    classes = test_dataset.classes
    samples = test_dataset.samples
    return test_loader, classes, samples


def test_model_process(model,
                       test_dataloader,
                       classes,
                       samples,
                       tag: str = ""):
    suffix = f"_{tag}" if tag else ""

    result_file = open(f"result{suffix}.txt", "w", encoding="utf-8")
    error_file  = open(f"error{suffix}.txt", "w", encoding="utf-8")

    device = "cuda" if torch.cuda.is_available() else "cpu"
    print("Test device:", device)

    model = model.to(device)
    model.eval()

    test_corrects = 0.0
    test_num = 0

    all_preds = []
    all_labels = []

    with torch.no_grad():
        for batch_idx, (test_data_x, test_data_y) in enumerate(test_dataloader):
            test_data_x = test_data_x.to(device)
            test_data_y = test_data_y.to(device)

            output = model(test_data_x)
            pre_lab = torch.argmax(output, dim=1)

            test_corrects += torch.sum(pre_lab == test_data_y.data)
            test_num += test_data_x.size(0)

            all_preds.extend(pre_lab.cpu().numpy())
            all_labels.extend(test_data_y.cpu().numpy())

            probs = torch.softmax(output, dim=1)
            top2_vals, top2_idx = torch.topk(probs, k=2, dim=1)

            for i in range(len(pre_lab)):
                idx_global = batch_idx * test_dataloader.batch_size + i

                first_cls, second_cls = top2_idx[i][0].item(), top2_idx[i][1].item()
                first_prob, second_prob = top2_vals[i][0].item(), top2_vals[i][1].item()

                result_file.write(
                    f"{samples[idx_global][0]}\t"
                    f"{classes[first_cls]}:{first_prob:.6f}\t"
                    f"{classes[second_cls]}:{second_prob:.6f}\n"
                )

                if pre_lab[i].item() != test_data_y[i].item():
                    error_file.write(
                        f"{samples[idx_global][0]}\t"
                        f"{classes[first_cls]}:{first_prob:.6f}\t"
                        f"{classes[second_cls]}:{second_prob:.6f}\n"
                    )

    test_acc = test_corrects.double().item() / test_num
    print("Test accuracy:", test_acc)

    all_labels = np.array(all_labels)
    all_preds  = np.array(all_preds)

    macro_f1 = f1_score(all_labels, all_preds, average='macro')
    print("Macro-F1 score:", macro_f1)

    print("\nClassification report:")
    print(classification_report(all_labels, all_preds, target_names=classes, digits=4))

    cm = confusion_matrix(all_labels, all_preds, labels=list(range(len(classes))))

    fig, ax = plt.subplots(figsize=(10, 8))
    chinese_font = FontProperties(fname=SIMHEI_PATH, size=12)

    sns.heatmap(
        cm, annot=True, fmt='d', cmap='Blues', ax=ax,
        xticklabels=classes, yticklabels=classes, cbar=False
    )
    ax.set_ylabel('True label')
    ax.set_xlabel('Predicted label')
    ax.set_title(
        '测试集的整体准确率为：' + f'{test_acc * 100:.3f}%',
        fontproperties=chinese_font
    )

    epsilon = 1e-8
    cm_normalized_row = cm.astype('float') / (cm.sum(axis=1)[:, np.newaxis] + epsilon)
    cm_normalized_col = cm.astype('float') / (cm.sum(axis=0)[np.newaxis, :] + epsilon)

    for j in range(cm.shape[1]):
        plt.text(j + 0.5, -0.5,
                 f'{cm_normalized_col[j, j] * 100:.2f}%',
                 ha='center', va='center', color='green')

    for i in range(cm.shape[0]):
        plt.text(cm.shape[1] + 0.5, i + 0.5,
                 f'{cm_normalized_row[i, i] * 100:.2f}%',
                 ha='center', va='center', color='red')

    plt.tight_layout()
    plt.savefig(f"confusion_matrix{suffix}.png")
    # plt.show()

    result_file.close()
    error_file.close()

    return test_acc, macro_f1


# 可单独测试用
if __name__ == "__main__":
    from model1120 import ResNet18, Residual

    mode = "order3"
    root_test = ROOT_TEST_DEFAULT
    tag  = "demo_test"

    in_channels = {"single": 1, "order": 2, "order3": 3}[mode]
    num_classes = 8

    weight_path = r"E:\best_model_demo.pth"
    model = ResNet18(Residual, in_channels=in_channels, num_classes=num_classes)
    model.load_state_dict(torch.load(weight_path, map_location="cpu"))

    test_loader, classes, samples = build_test_loader(mode, batch_size=256, root_test=root_test)
    test_acc, macro_f1 = test_model_process(model, test_loader, classes, samples, tag=tag)
    print("Done. Acc = {:.4f}, macro-F1 = {:.4f}".format(test_acc, macro_f1))
