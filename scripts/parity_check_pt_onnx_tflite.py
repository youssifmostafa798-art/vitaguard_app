"""Module for Parity Check Pt Onnx Tflite."""

from __future__ import annotations

from pathlib import Path
from typing import Iterable
import argparse

import numpy as np
from PIL import Image


def _softmax(x: np.ndarray) -> np.ndarray:
    """Softmax."""
    z = x.astype(np.float64)
    z = z - np.max(z)
    e = np.exp(z)
    return (e / np.sum(e)).astype(np.float64)


def _collect_images(path: Path, limit: int) -> list[Path]:
    """Collect images."""
    if path.is_file():
        return [path]
    exts = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
    imgs = [p for p in path.rglob("*") if p.suffix.lower() in exts]
    imgs.sort()
    if limit > 0:
        imgs = imgs[:limit]
    return imgs


def _load_fastai_learner(export_pkl: Path):
    """Load fastai learner."""
    # Fastai exports created on Linux may pickle PosixPath; map it on Windows.
    import pathlib
    if hasattr(pathlib, "WindowsPath"):
        pathlib.PosixPath = pathlib.WindowsPath  # type: ignore[assignment]

    from fastai.vision.all import load_learner

    learn = load_learner(export_pkl)
    learn.model.eval()
    return learn


def _imagenet_preprocess_nchw(image_path: Path, size_hw: tuple[int, int]) -> np.ndarray:
    """Imagenet preprocess nchw."""
    # Shared preprocessing used for all three backends in this script:
    # RGB -> resize -> /255 -> ImageNet normalize -> NCHW float32.
    mean = np.array([0.485, 0.456, 0.406], dtype=np.float32)
    std = np.array([0.229, 0.224, 0.225], dtype=np.float32)
    h, w = size_hw
    with Image.open(image_path) as im:
        im = im.convert("RGB").resize((w, h), Image.BILINEAR)
        arr = np.asarray(im, dtype=np.float32) / 255.0  # HWC
    arr = (arr - mean) / std
    arr = np.transpose(arr, (2, 0, 1))  # CHW
    return arr[None, ...].astype(np.float32)  # NCHW


def _run_pytorch_logits(learn, xb) -> np.ndarray:
    """Run pytorch logits."""
    import torch

    x = torch.from_numpy(xb).to(next(learn.model.parameters()).device)
    with torch.inference_mode():
        out = learn.model(x)
    return out.detach().cpu().numpy().reshape(-1)


def _run_onnx_logits(onnx_path: Path, x_nchw: np.ndarray) -> np.ndarray:
    """Run onnx logits."""
    import onnxruntime as ort

    sess = ort.InferenceSession(str(onnx_path), providers=["CPUExecutionProvider"])
    inp = sess.get_inputs()[0]
    out = sess.run(None, {inp.name: x_nchw.astype(np.float32)})[0]
    return out.reshape(-1)

def _onnx_input_hw(onnx_path: Path) -> tuple[int, int]:
    """Onnx input hw."""
    import onnxruntime as ort

    sess = ort.InferenceSession(str(onnx_path), providers=["CPUExecutionProvider"])
    s = sess.get_inputs()[0].shape
    # Expected NCHW [N,3,H,W]
    if len(s) != 4:
        raise ValueError(f"Unexpected ONNX input shape: {s}")
    h = int(s[2])
    w = int(s[3])
    return h, w


def _run_tflite_logits(tflite_path: Path, x_nchw: np.ndarray) -> tuple[np.ndarray, tuple[int, ...]]:
    """Run tflite logits."""
    try:
        import tensorflow as tf

        interp = tf.lite.Interpreter(model_path=str(tflite_path))
    except Exception:
        import tflite_runtime.interpreter as tflite

        interp = tflite.Interpreter(model_path=str(tflite_path))

    interp.allocate_tensors()
    in_det = interp.get_input_details()[0]
    out_det = interp.get_output_details()[0]

    in_shape = tuple(int(v) for v in in_det["shape"])
    x = x_nchw.astype(np.float32)

    # Support both NCHW and NHWC TFLite inputs.
    if len(in_shape) == 4 and in_shape[1] == 3:
        x_in = x
    elif len(in_shape) == 4 and in_shape[-1] == 3:
        x_in = np.transpose(x, (0, 2, 3, 1))
    else:
        raise ValueError(f"Unsupported TFLite input shape: {in_shape}")

    if tuple(x_in.shape) != in_shape:
        raise ValueError(
            f"TFLite input shape mismatch. model={in_shape}, from_fastai={tuple(x_in.shape)}"
        )

    interp.set_tensor(in_det["index"], x_in)
    interp.invoke()
    out = interp.get_tensor(out_det["index"]).reshape(-1)
    return out, in_shape


def _fmt_row(
    image: Path,
    pt: np.ndarray,
    ox: np.ndarray,
    tx: np.ndarray,
    vocab: Iterable[str],
) -> str:
    p_pt = _softmax(pt)
    p_ox = _softmax(ox)
    p_tx = _softmax(tx)
    labels = list(vocab)

    def pick(arr: np.ndarray) -> str:
        """Pick."""
        idx = int(np.argmax(arr))
        name = labels[idx] if 0 <= idx < len(labels) else f"idx{idx}"
        return f"{name} ({arr[idx]:.6f})"

    return (
        f"\nIMAGE: {image}\n"
        f"  PT     logits={pt.tolist()}  pred={pick(p_pt)}\n"
        f"  ONNX   logits={ox.tolist()}  pred={pick(p_ox)}\n"
        f"  TFLITE logits={tx.tolist()}  pred={pick(p_tx)}\n"
        f"  deltas: max|PT-ONNX|={float(np.max(np.abs(pt-ox))):.6f}, "
        f"max|PT-TFL|={float(np.max(np.abs(pt-tx))):.6f}\n"
    )


def main() -> int:
    """Main."""
    ap = argparse.ArgumentParser(
        description="Parity check for FastAI export.pkl vs ONNX vs TFLite logits."
    )
    ap.add_argument("--export-pkl", default="vitaguard_artifacts/export.pkl")
    ap.add_argument("--onnx", default="vitaguard_artifacts/model.onnx")
    ap.add_argument("--tflite", default="vitaguard_artifacts/model.tflite")
    ap.add_argument(
        "--images",
        default="chest_xray/test",
        help="Image file or directory to sample images from.",
    )
    ap.add_argument("--limit", type=int, default=12)
    args = ap.parse_args()

    export_pkl = Path(args.export_pkl).resolve()
    onnx_path = Path(args.onnx).resolve()
    tflite_path = Path(args.tflite).resolve()
    images_path = Path(args.images).resolve()

    for p in [export_pkl, onnx_path, tflite_path, images_path]:
        if not p.exists():
            raise FileNotFoundError(f"Path not found: {p}")

    images = _collect_images(images_path, args.limit)
    if not images:
        raise RuntimeError(f"No images found under: {images_path}")

    learn = _load_fastai_learner(export_pkl)
    vocab = [str(v) for v in learn.dls.vocab]

    print("=== PARITY CHECK ===")
    print(f"export.pkl : {export_pkl}")
    print(f"onnx       : {onnx_path}")
    print(f"tflite     : {tflite_path}")
    print(f"images     : {images_path} (n={len(images)})")
    print(f"vocab      : {vocab}")

    hw = _onnx_input_hw(onnx_path)
    print(f"onnx input hw: {hw}")

    # Probe tflite input shape once.
    _, t_in_shape = _run_tflite_logits(tflite_path, _imagenet_preprocess_nchw(images[0], hw))
    print(f"tflite input shape: {t_in_shape}")

    for im in images:
        x_nchw = _imagenet_preprocess_nchw(im, hw)

        pt = _run_pytorch_logits(learn, x_nchw)
        ox = _run_onnx_logits(onnx_path, x_nchw)
        tx, _ = _run_tflite_logits(tflite_path, x_nchw)

        print(_fmt_row(im, pt, ox, tx, vocab))

    print("\nDone.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
