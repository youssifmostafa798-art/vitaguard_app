"""
TFLite diagnostics for vitaguard DenseNet-style chest X-ray model.

Run from repo root:
  python scratch/tflite_densenet_diagnostics.py

Steps covered:
  1) Tensor metadata (shapes, dtypes, names)
  2) Input sensitivity: two different random images -> logits should differ if model is wired correctly
  3) Normalization variants (Fastai/torchvision DenseNet vs EfficientNet-style vs raw /255)
  4) RGB vs BGR probe (solid colors)
  5) Logit vs probability: softmax of outputs for display
"""
from __future__ import annotations

import math
import sys
from pathlib import Path

import numpy as np

REPO = Path(__file__).resolve().parents[1]
MODEL_PATH = REPO / "assets" / "models" / "model.tflite"

# torchvision / Fastai ImageNet normalization (RGB, pixel in 0..255 before /255)
IMAGENET_MEAN = np.array([0.485, 0.456, 0.406], dtype=np.float32)
IMAGENET_STD = np.array([0.229, 0.224, 0.225], dtype=np.float32)


def softmax(x: np.ndarray) -> np.ndarray:
    x = x.astype(np.float64)
    x = x - np.max(x)
    e = np.exp(x)
    return (e / np.sum(e)).astype(np.float32)


def make_nhwc(h: int = 320, w: int = 320) -> np.ndarray:
    """Empty float32 NHWC template."""
    return np.zeros((1, h, w, 3), dtype=np.float32)


def fill_random(rng: np.random.Generator, out: np.ndarray) -> None:
    out[...] = rng.uniform(0.0, 255.0, size=out.shape).astype(np.float32)


def normalize_efficientnet_nhwc(x255: np.ndarray) -> np.ndarray:
    """Match current Flutter: (pixel/127.5) - 1  -> approx [-1, 1]"""
    return (x255 / 127.5) - 1.0


def normalize_imagenet_nhwc(x255: np.ndarray) -> np.ndarray:
    """torchvision DenseNet121: x in [0,1] then (x-mean)/std; channels last."""
    x01 = x255 / 255.0
    return (x01 - IMAGENET_MEAN) / IMAGENET_STD


def normalize_scale01_nhwc(x255: np.ndarray) -> np.ndarray:
    return x255 / 255.0


def swap_rb_nhwc(x: np.ndarray) -> np.ndarray:
    y = x.copy()
    y[..., 0], y[..., 2] = y[..., 2].copy(), y[..., 0].copy()
    return y


def solid_color_nhwc(rgb: tuple[int, int, int]) -> np.ndarray:
    t = make_nhwc()
    t[..., 0] = rgb[0]
    t[..., 1] = rgb[1]
    t[..., 2] = rgb[2]
    return t


def run_tflite(model_path: Path, inp: np.ndarray) -> tuple[np.ndarray, dict, dict]:
    import tensorflow as tf

    interp = tf.lite.Interpreter(model_path=str(model_path))
    interp.allocate_tensors()
    in_det = interp.get_input_details()[0]
    out_det = interp.get_output_details()[0]

    x = inp.astype(np.float32, copy=False)
    if tuple(x.shape) != tuple(in_det["shape"]):
        raise ValueError(f"Input shape {x.shape} != model {in_det['shape']}")

    interp.set_tensor(in_det["index"], x)
    interp.invoke()
    out = np.copy(interp.get_tensor(out_det["index"]))
    return out, in_det, out_det


def main() -> int:
    if not MODEL_PATH.is_file():
        print(f"Missing model: {MODEL_PATH}", file=sys.stderr)
        return 1

    import tensorflow as tf

    interp = tf.lite.Interpreter(model_path=str(MODEL_PATH))
    interp.allocate_tensors()
    in_details = interp.get_input_details()
    out_details = interp.get_output_details()

    print("=== MODEL ===", MODEL_PATH)
    print("=== INPUT TENSORS ===")
    for d in in_details:
        print(
            f"  index={d['index']} name={d.get('name')} shape={d['shape']} "
            f"dtype={d['dtype']} quant={d.get('quantization', (0,0))}"
        )
    print("=== OUTPUT TENSORS ===")
    for d in out_details:
        print(
            f"  index={d['index']} name={d.get('name')} shape={d['shape']} "
            f"dtype={d['dtype']} quant={d.get('quantization', (0,0))}"
        )

    rng = np.random.default_rng(0)

    scenarios: list[tuple[str, np.ndarray]] = []

    # Random A / B with different seeds -> different raw 0..255
    ra = make_nhwc()
    fill_random(rng, ra)
    rb = make_nhwc()
    fill_random(np.random.default_rng(1), rb)

    scenarios.append(("random_A raw 0-255 (WRONG if model expects normalized)", ra.copy()))
    scenarios.append(("random_B raw 0-255", rb.copy()))

    scenarios.append(("random_A EfficientNet (x/127.5)-1", normalize_efficientnet_nhwc(ra)))
    scenarios.append(("random_B EfficientNet (x/127.5)-1", normalize_efficientnet_nhwc(rb)))

    scenarios.append(("random_A ImageNet mean/std on x/255", normalize_imagenet_nhwc(ra)))
    scenarios.append(("random_B ImageNet mean/std on x/255", normalize_imagenet_nhwc(rb)))

    scenarios.append(("random_A scale 0-1 only", normalize_scale01_nhwc(ra)))
    scenarios.append(("random_B scale 0-1 only", normalize_scale01_nhwc(rb)))

    # Solid probes (still 0-255 before norm — use ImageNet path like training)
    red255 = solid_color_nhwc((255, 0, 0))
    blue255 = solid_color_nhwc((0, 0, 255))
    scenarios.append(("solid RED (255,0,0) ImageNet norm", normalize_imagenet_nhwc(red255)))
    scenarios.append(("solid BLUE (0,0,255) ImageNet norm", normalize_imagenet_nhwc(blue255)))
    scenarios.append(("solid RED BGR-swapped tensor (OpenCV order as RGB layout)", normalize_imagenet_nhwc(swap_rb_nhwc(red255))))

    print("\n=== LOGITS / SOFTMAX BY SCENARIO ===")
    print("(Fastai DenseNet121 on ImageNet pretrain almost always uses: /255 then ImageNet mean/std, RGB, NCHW in PyTorch — TFLite is NHWC but same channel order.)\n")

    prev_logits = None
    for name, tensor in scenarios:
        logits, _, _ = run_tflite(MODEL_PATH, tensor)
        flat = logits.reshape(-1)
        probs = softmax(flat)
        print(f"-- {name}")
        print(f"   logits: {flat.tolist()}")
        print(f"   softmax: {[float(f'{p:.6f}') for p in probs]}")
        if prev_logits is not None and "random_A" in name and "random_B" in name:
            pass
        if "random_A" in name and "EfficientNet" in name:
            prev_logits = flat
        if "random_B" in name and "EfficientNet" in name and prev_logits is not None:
            d = float(np.max(np.abs(flat - prev_logits)))
            print(f"   [check] diff vs random_A EfficientNet max_abs: {d:.6f}")

    print("\n=== COLLAPSE / SENSITIVITY CHECK ===")
    a = normalize_imagenet_nhwc(ra)
    b = normalize_imagenet_nhwc(rb)
    la, _, _ = run_tflite(MODEL_PATH, a)
    lb, _, _ = run_tflite(MODEL_PATH, b)
    la = la.reshape(-1)
    lb = lb.reshape(-1)
    diff = float(np.max(np.abs(la - lb)))
    print(f"ImageNet-norm random A vs B: max|logit_diff| = {diff:.6f}")
    if diff < 1e-5:
        print("WARNING: logits nearly identical — possible graph issue, constant folding bug, or broken export.")
    else:
        print("OK: model output changes with different inputs (under ImageNet norm).")

    print("\n=== DENSENET / FASTAI NOTE ===")
    print("Your scripts/convert_to_onnx.py uses torchvision densenet121; default training pipeline")
    print("for fastai + ImageNet pretrained backbone is nearly always:")
    print("  pixel in [0,255] -> /255 -> standard ImageNet normalize (RGB).")
    print("EfficientNet-style (x/127.5-1) is usually WRONG for this backbone unless you retrained that way.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
