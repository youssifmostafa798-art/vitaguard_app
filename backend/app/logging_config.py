"""VitaGuard — Structured logging configuration using structlog."""

import logging
import sys

import structlog


def setup_logging(environment: str = "development", log_level: str = "info") -> None:
    """Configure structlog for JSON output in production and pretty-print in development."""
    processors = [
        structlog.contextvars.merge_contextvars,
        structlog.processors.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
    ]

    if environment == "production":
        # JSON logs for production (Logstash/ELK/CloudWatch)
        processors.append(structlog.processors.JSONRenderer())
    else:
        # Pretty-print for development
        processors.append(structlog.dev.ConsoleRenderer())

    structlog.configure(
        processors=processors,
        logger_factory=structlog.PrintLoggerFactory(),
        cache_logger_on_first_use=True,
    )

    # Bridge standard logging to structlog
    logging.basicConfig(
        format="%(message)s",
        stream=sys.stdout,
        level=getattr(logging, log_level.upper(), logging.INFO),
    )
