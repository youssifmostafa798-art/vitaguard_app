"""Module for Export Verify Tflite."""

import onnx
from __future__ import annotations

import shutil
from pathlib import Path
import argparse

import numpy as np
import torch


def _load_fastai_learner(export_pkl: Path):
    """Load fastai learner."""
    import pathlib
    if hasattr(pathlib, "WindowsPath"):
        pathlib.PosixPath = pathlib.WindowsPath  # type: ignore[assignment]

    from fastai.vision.all import load_learner

    learn = load_learner(export_pkl)
    learn.model.eval()
    return learn


def _collect_images(path: Path, limit: int) -> list[Path]:
    """Collect images."""
    if path.is_file():
        return [path]
    exts = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
    images = [p for p in path.rglob("*") if p.suffix.lower() in exts]
    images.sort()
    return images[:limit] if limit > 0 else images


def _imagenet_preprocess_nchw(image_path: Path, size_hw: tuple[int, int]) -> np.ndarray:
    """Imagenet preprocess nchw."""
    from PIL import Image

    mean = np.array([0.485, 0.456, 0.406], dtype=np.float32)
    std = np.array([0.229, 0.224, 0.225], dtype=np.float32)
    h, w = size_hw
    with Image.open(image_path) as im:
        im = im.convert("RGB").resize((w, h), Image.BILINEAR)
        arr = np.asarray(im, dtype=np.float32) / 255.0
    arr = (arr - mean) / std
    arr = np.transpose(arr, (2, 0, 1))
    return arr[None, ...].astype(np.float32)


def _run_pt(learn, x_nchw: np.ndarray) -> np.ndarray:
    """Run pt."""
    x = torch.from_numpy(x_nchw).to(next(learn.model.parameters()).device)
    with torch.inference_mode():
        y = learn.model(x)
    return y.detach().cpu().numpy().reshape(-1)


def _run_onnx(onnx_path: Path, x_nchw: np.ndarray) -> np.ndarray:
    """Run onnx."""
    import onnxruntime as ort

    sess = ort.InferenceSession(str(onnx_path), providers=["CPUExecutionProvider"])
    inp = sess.get_inputs()[0]
    y = sess.run(None, {inp.name: x_nchw.astype(np.float32)})[0]
    return y.reshape(-1)


def _export_onnx_from_export_pkl(learn, onnx_path: Path, input_size: int) -> None:
    """Export onnx from export pkl."""
    onnx_path.parent.mkdir(parents=True, exist_ok=True)
    model = learn.model.cpu().eval()
    dummy = torch.zeros(1, 3, input_size, input_size, dtype=torch.float32)
    torch.onnx.export(
        model,
        dummy,
        str(onnx_path),
        opset_version=18,
        export_params=True,
        do_constant_folding=True,
        input_names=["input"],
        output_names=["output"],
        dynamic_axes={"input": {0: "batch"}, "output": {0: "batch"}},
        dynamo=False,
    )


def _parity_gate(learn, onnx_path: Path, images: list[Path], input_size: int,
    max_diff: float) -> float:
    """Parity gate."""
    worst = 0.0
    for im in images:
        x = _imagenet_preprocess_nchw(im, (input_size, input_size))
        pt = _run_pt(learn, x)
        ox = _run_onnx(onnx_path, x)
        d = float(np.max(np.abs(pt - ox)))
        worst = max(worst, d)
        print(f"[PARITY] {im.name}: max|PT-ONNX|={d:.6f}")
    print(f"[PARITY] worst max|PT-ONNX|={worst:.6f}")
    if worst > max_diff:
        raise RuntimeError(
            f"Parity gate FAILED: worst diff {worst:.6f} exceeds threshold {max_diff:.6f}. "
            "Refusing to produce TFLite from a mismatched ONNX."
        )
    return worst


def _convert_onnx_to_tflite(onnx_path: Path, tflite_path: Path, temp_dir: Path) -> None:
    """Convert onnx to tflite."""
    import onnx2tf

    model = onnx.load(str(onnx_path))
    onnx.checker.check_model(model)

    if temp_dir.exists():
        shutil.rmtree(temp_dir, ignore_errors=True)
    temp_dir.mkdir(parents=True, exist_ok=True)

    onnx2tf.convert(
        input_onnx_file_path=str(onnx_path),
        output_folder_path=str(temp_dir),
        copy_onnx_input_output_names_to_tflite=True,
        non_verbose=True,
    )

    candidates = sorted(temp_dir.glob("*.tflite"))
    if not candidates:
        raise RuntimeError("onnx2tf produced no .tflite files")
    src = candidates[0]
    tflite_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy(src, tflite_path)


def main() -> int:
    """Main."""
    ap = argparse.ArgumentParser(
        description="Canonical export pipeline: export.pkl -> ONNX -> parity gate -> TFLite"
    )
    ap.add_argument("--export-pkl", required=True, help="Path to fastai export.pkl")
    ap.add_argument("--images", required=True, help="Image file/folder for parity checks")
    ap.add_argument("--output-dir", default="vitaguard_artifacts")
    ap.add_argument("--input-size", type=int, default=224)
    ap.add_argument("--sample-count", type=int, default=12)
    ap.add_argument("--max-diff", type=float, default=1e-3)
    ap.add_argument("--skip-tflite", action="store_true")
    args = ap.parse_args()

    export_pkl = Path(args.export_pkl).resolve()
    images_root = Path(args.images).resolve()
    out_dir = Path(args.output_dir).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    onnx_path = out_dir / "model.onnx"
    tflite_path = out_dir / "model.tflite"
    temp_dir = out_dir / "tflite_tmp"

    if not export_pkl.exists():
        raise FileNotFoundError(f"export.pkl not found: {export_pkl}")
    if not images_root.exists():
        raise FileNotFoundError(f"images path not found: {images_root}")

    images = _collect_images(images_root, args.sample_count)
    if not images:
        raise RuntimeError(f"No images found in: {images_root}")

    print("=== Export + Verify Pipeline ===")
    print(f"export.pkl : {export_pkl}")
    print(f"images     : {images_root} (n={len(images)})")
    print(f"output dir : {out_dir}")
    print(f"input size : {args.input_size}")

    learn = _load_fastai_learner(export_pkl)
    print(f"vocab      : {[str(v) for v in learn.dls.vocab]}")

    print("\n[1/3] Exporting ONNX directly from learn.model...")
    _export_onnx_from_export_pkl(learn, onnx_path, args.input_size)
    print(f"Saved ONNX : {onnx_path}")

    print("\n[2/3] Running PT vs ONNX parity gate...")
    _parity_gate(learn, onnx_path, images, args.input_size, args.max_diff)
    print("[PARITY] PASSED")

    if args.skip_tflite:
        print("\n[3/3] Skipped TFLite conversion (--skip-tflite).")
        return 0

    print("\n[3/3] Converting ONNX -> TFLite...")
    _convert_onnx_to_tflite(onnx_path, tflite_path, temp_dir)
    print(f"Saved TFLite: {tflite_path}")
    print("\nDone.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
