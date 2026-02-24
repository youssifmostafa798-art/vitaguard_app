"""VitaGuard — X-ray ML inference service using TFLite."""

from __future__ import annotations

import logging
import os
from pathlib import Path

import numpy as np
from PIL import Image

from app.config import settings

logger = logging.getLogger(__name__)

# Module-level interpreter (loaded once at startup)
_interpreter = None
_input_details = None
_output_details = None

# Class labels for the pneumonia detection model
CLASS_LABELS = ["NORMAL", "PNEUMONIA"]


def load_model() -> None:
    """Load the TFLite model into memory. Called once at app startup."""
    global _interpreter, _input_details, _output_details  # noqa: PLW0603

    model_path = Path(settings.TFLITE_MODEL_PATH)
    if not model_path.exists():
        logger.warning("TFLite model not found at %s — inference disabled", model_path)
        return

    try:
        import tflite_runtime.interpreter as tflite
    except ImportError:
        # Fallback to full TensorFlow if tflite-runtime not available
        try:
            import tensorflow.lite as tflite  # type: ignore[import-untyped]
        except ImportError:
            logger.warning("Neither tflite-runtime nor tensorflow found — inference disabled")
            return

    _interpreter = tflite.Interpreter(model_path=str(model_path))
    _interpreter.allocate_tensors()
    _input_details = _interpreter.get_input_details()
    _output_details = _interpreter.get_output_details()

    logger.info(
        "TFLite model loaded: input_shape=%s, output_shape=%s",
        _input_details[0]["shape"],
        _output_details[0]["shape"],
    )


def is_model_loaded() -> bool:
    """Check if the ML model is available for inference."""
    return _interpreter is not None


def validate_xray_image(file_path: str) -> tuple[bool, str]:
    """
    Validate that the uploaded file is a valid X-ray image.

    Per flowchart: "Is X-ray Valid?" decision gate.
    Returns (is_valid, error_message).
    """
    path = Path(file_path)

    # Check file exists
    if not path.exists():
        return False, "File not found"

    # Check file extension
    allowed_extensions = {".jpg", ".jpeg", ".png"}
    if path.suffix.lower() not in allowed_extensions:
        return False, "Invalid file type. Please upload a JPEG or PNG image."

    # Check file size
    file_size = path.stat().st_size
    if file_size > settings.max_upload_bytes:
        return False, f"File too large. Maximum size is {settings.MAX_UPLOAD_SIZE_MB}MB."

    # Validate it's a real image
    try:
        with Image.open(path) as img:
            img.verify()
    except Exception:
        return False, "Invalid image file. Please upload a valid X-ray image."

    # Re-open to check properties (verify() invalidates the image object)
    try:
        with Image.open(path) as img:
            width, height = img.size
            # Basic sanity: image should be reasonably sized
            if width < 50 or height < 50:
                return False, "Image too small. Please upload a higher resolution X-ray."
            if width > 10000 or height > 10000:
                return False, "Image too large in dimensions. Please resize and re-upload."
    except Exception:
        return False, "Could not read image properties."

    return True, ""


def run_inference(file_path: str) -> dict:
    """
    Run TFLite inference on a validated X-ray image.

    Per flowchart: "AI Model Analysis" → "Display Result: Infected / Not Infected"

    Returns dict with prediction, confidence, and report_text.
    """
    if not is_model_loaded():
        return {
            "prediction": None,
            "confidence": None,
            "report_text": "AI model not available. Please contact support.",
        }

    # Load and preprocess image
    with Image.open(file_path) as img:
        # Get model input shape
        input_shape = _input_details[0]["shape"]  # e.g., [1, 224, 224, 3]
        target_height = input_shape[1]
        target_width = input_shape[2]
        channels = input_shape[3] if len(input_shape) > 3 else 1

        # Convert to RGB or grayscale based on model input
        if channels == 3:
            img = img.convert("RGB")
        elif channels == 1:
            img = img.convert("L")

        # Resize to model input size
        img = img.resize((target_width, target_height), Image.Resampling.LANCZOS)

        # Convert to numpy array and normalize
        img_array = np.array(img, dtype=np.float32)

        # Normalize to [0, 1]
        img_array = img_array / 255.0

        # Add batch dimension and channel dimension if needed
        if channels == 1 and len(img_array.shape) == 2:
            img_array = np.expand_dims(img_array, axis=-1)
        img_array = np.expand_dims(img_array, axis=0)

    # Run inference
    _interpreter.set_tensor(_input_details[0]["index"], img_array)
    _interpreter.invoke()
    output = _interpreter.get_tensor(_output_details[0]["index"])

    # Parse output
    output_shape = _output_details[0]["shape"]
    if len(output_shape) >= 2 and output_shape[-1] == 2:
        # Binary classification [NORMAL, PNEUMONIA]
        probabilities = output[0]
        predicted_class = int(np.argmax(probabilities))
        confidence = float(probabilities[predicted_class])
        prediction = CLASS_LABELS[predicted_class]
    elif len(output_shape) >= 2 and output_shape[-1] == 1:
        # Single sigmoid output
        prob = float(output[0][0])
        predicted_class = 1 if prob > 0.5 else 0
        confidence = prob if predicted_class == 1 else (1.0 - prob)
        prediction = CLASS_LABELS[predicted_class]
    else:
        # Fallback
        prob = float(output.flat[0])
        predicted_class = 1 if prob > 0.5 else 0
        confidence = prob if predicted_class == 1 else (1.0 - prob)
        prediction = CLASS_LABELS[predicted_class]

    # Generate report text matching Flutter UI format
    report_text = _generate_report(prediction, confidence)

    return {
        "prediction": prediction,
        "confidence": round(confidence, 4),
        "report_text": report_text,
    }


def _generate_report(prediction: str, confidence: float) -> str:
    """Generate a structured radiology report matching the Flutter UI."""
    confidence_pct = round(confidence * 100, 1)

    if prediction == "PNEUMONIA":
        return (
            f"• The scan shows findings suggestive of pneumonia, "
            f"with areas of increased lung opacity. (Confidence: {confidence_pct}%)\n\n"
            f"• Clinical correlation and medical follow-up are recommended.\n\n"
            f"• ⚠ This is a preliminary automated report and does not "
            f"replace a physician's diagnosis."
        )
    else:
        return (
            f"• The scan does not show significant findings suggestive of pneumonia. "
            f"The lung fields appear clear. (Confidence: {confidence_pct}%)\n\n"
            f"• Routine follow-up is recommended as appropriate.\n\n"
            f"• ⚠ This is a preliminary automated report and does not "
            f"replace a physician's diagnosis."
        )


def save_uploaded_image(content: bytes, filename: str) -> str:
    """Save an uploaded image to the configured uploads directory."""
    upload_dir = Path(settings.UPLOAD_DIR) / "xray"
    upload_dir.mkdir(parents=True, exist_ok=True)

    # Generate unique filename
    import uuid

    ext = Path(filename).suffix
    safe_name = f"{uuid.uuid4()}{ext}"
    file_path = upload_dir / safe_name

    with open(file_path, "wb") as f:
        f.write(content)

    return str(file_path)
