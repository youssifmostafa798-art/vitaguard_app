"""VitaGuard — Generic file upload and validation service."""

from __future__ import annotations

import logging
import uuid
from pathlib import Path

from app.config import settings

logger = logging.getLogger(__name__)

# Allowed MIME-type sets keyed by category
ALLOWED_IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png"}
ALLOWED_DOCUMENT_EXTENSIONS = {".jpg", ".jpeg", ".png", ".pdf"}


class FileValidationError(Exception):
    """Raised when uploaded file fails validation."""


def validate_file(
    content: bytes,
    filename: str,
    *,
    allowed_extensions: set[str] | None = None,
    max_bytes: int | None = None,
) -> None:
    """Validate file content and extension.

    Raises FileValidationError on failure.
    """
    if allowed_extensions is None:
        allowed_extensions = ALLOWED_IMAGE_EXTENSIONS
    if max_bytes is None:
        max_bytes = settings.max_upload_bytes

    ext = Path(filename).suffix.lower()
    if ext not in allowed_extensions:
        allowed = ", ".join(sorted(allowed_extensions))
        raise FileValidationError(
            f"Invalid file type '{ext}'. Allowed: {allowed}"
        )

    if len(content) > max_bytes:
        max_mb = max_bytes / (1024 * 1024)
        raise FileValidationError(
            f"File too large. Maximum allowed size is {max_mb:.0f} MB."
        )

    if len(content) == 0:
        raise FileValidationError("File is empty.")


def save_file(content: bytes, filename: str, subdirectory: str) -> str:
    """Save file to UPLOAD_DIR/{subdirectory}/{uuid}.{ext}.

    Returns the relative path from UPLOAD_DIR suitable for storage in DB.
    """
    upload_dir = Path(settings.UPLOAD_DIR) / subdirectory
    upload_dir.mkdir(parents=True, exist_ok=True)

    ext = Path(filename).suffix.lower()
    safe_name = f"{uuid.uuid4()}{ext}"
    file_path = upload_dir / safe_name

    with open(file_path, "wb") as f:
        f.write(content)

    logger.info("Saved file: %s (%d bytes)", file_path, len(content))
    return str(file_path)


def validate_and_save(
    content: bytes,
    filename: str,
    subdirectory: str,
    *,
    allowed_extensions: set[str] | None = None,
    max_bytes: int | None = None,
) -> str:
    """Validate then save. Convenience wrapper.

    Returns the saved file path.
    """
    validate_file(
        content,
        filename,
        allowed_extensions=allowed_extensions,
        max_bytes=max_bytes,
    )
    return save_file(content, filename, subdirectory)
