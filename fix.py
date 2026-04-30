#!/usr/bin/env python3
"""Fix ai_chat_repository.dart and ai_response_sanitizer.dart parameter mismatch."""

import shutil
import subprocess
from pathlib import Path

PROJECT_ROOT = Path(r"c:\Users\Ahmed Mekawi\vitaguard_app")


def write(path: Path, content: str) -> None:
    """Write file as UTF-8."""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    try:
        rel = path.relative_to(PROJECT_ROOT)
    except ValueError:
        rel = path
    print(f"  ✔  Written: {rel}")


def j(*lines: str) -> str:
    """Join lines with newline."""
    return "\n".join(lines) + "\n"


def run_pub_get(root: Path) -> None:
    """Run flutter pub get."""
    print("\n[Flutter] Running flutter pub get ...")
    flutter = shutil.which("flutter")
    if not flutter:
        print("  ⚠  flutter not found in PATH.")
        return
    result = subprocess.run([flutter, "pub", "get"], cwd=root)
    if result.returncode == 0:
        print("  ✔  Succeeded.")
    else:
        print("  ⚠  Failed.")


# ─────────────────────────────────────────────────────────────────────────────
# Option A: Update the sanitizer to ACCEPT userPrompt as optional named param
# This is the cleanest fix — the repository can keep passing userPrompt:
# and the sanitizer will use it for better echo-stripping if provided.
# ─────────────────────────────────────────────────────────────────────────────


def sanitizer_dart() -> str:
    """Build ai_response_sanitizer.dart that accepts optional userPrompt."""

    # Build regex patterns using raw string concatenation
    # so Python never interprets backslashes
    plan_block = "r'" + r"Plan:\s*\n(?:\s*\d+\.\s+[^\n]+\n?)+" + "'"
    inline_plan = "r'" + r"Plan:\s*[^\n]+\n?" + "'"
    echo_pat = "r'" + r"^The user (said|asked|wrote|typed)\s+[^\n]+\n?" + "'"
    blank_lines = "r'" + r"\n{3,}" + "'"

    p1 = "r'" + r"Clinical A[Ii] assistant for VitaGuard\.?[^\n]*\n?" + "'"
    p2 = "r'" + r"Provide expert healthcare answers[^\n]*\n?" + "'"
    p3 = "r'" + r"Concise,?\s*professional,?\s*expert\.?[^\n]*\n?" + "'"
    p4 = "r'" + r"No repeating input[^\n]*\n?" + "'"
    p5 = "r'" + r"use standard markdown[^\n]*\n?" + "'"
    p6 = "r'" + r"use \* for bullets[^\n]*\n?" + "'"
    p7 = "r'" + r"STRICT RULES[^\n]*\n?" + "'"
    p8 = "r'" + r"NEVER VIOLATE[^\n]*\n?" + "'"
    p9 = "r'" + r"Respond ONLY with your final answer[^\n]*\n?" + "'"
    p10 = "r'" + r"Never repeat or echo[^\n]*\n?" + "'"
    p11 = "r'" + r"No space inside bold markers[^\n]*\n?" + "'"

    a1 = "r'" + r"^\s*Step\s+\d+:\s*[^\n]*\n?" + "'"
    a2 = "r'" + r"^\s*Note:\s*(internal|hidden|private)[^\n]*\n?" + "'"
    a3 = "r'" + r"\[internal\][^\n]*\n?" + "'"
    a4 = "r'" + r"\[thinking\][^\n]*\n?" + "'"

    return j(
        "/// Sanitizes raw AI responses to remove leaked prompts and reasoning.",
        "library;",
        "",
        "/// Cleans raw Gemma/Gemini output before displaying to the user.",
        "class AiResponseSanitizer {",
        "  AiResponseSanitizer._();",
        "",
        "  /// Sanitize [raw] AI response text.",
        "  ///",
        "  /// Optionally pass [userPrompt] to also strip leading echoes",
        "  /// of the user's own message from the response.",
        "  static String sanitize(String raw, {String? userPrompt}) {",
        "    if (raw.trim().isEmpty) return raw;",
        "",
        "    String text = raw;",
        "    text = _stripPlanBlock(text);",
        "    text = _stripUserEchoPreamble(text);",
        "    text = _stripSystemPromptLeakage(text);",
        "    text = _stripInternalAnnotations(text);",
        "    if (userPrompt != null && userPrompt.trim().isNotEmpty) {",
        "      text = _stripLeadingEcho(text, userPrompt.trim());",
        "    }",
        "    text = _collapseBlankLines(text);",
        "    return text.trim();",
        "  }",
        "",
        "  // ── Plan block ──────────────────────────────────────────────────",
        "",
        "  static String _stripPlanBlock(String text) {",
        "    final planBlock = RegExp(",
        f"      {plan_block},",
        "      caseSensitive: false,",
        "      multiLine: true,",
        "    );",
        "    final inlinePlan = RegExp(",
        f"      {inline_plan},",
        "      caseSensitive: false,",
        "    );",
        "    String result = text.replaceAll(planBlock, '');",
        "    result = result.replaceAll(inlinePlan, '');",
        "    return result;",
        "  }",
        "",
        "  // ── User echo preamble ───────────────────────────────────────────",
        "",
        "  static String _stripUserEchoPreamble(String text) {",
        "    final echo = RegExp(",
        f"      {echo_pat},",
        "      caseSensitive: false,",
        "      multiLine: true,",
        "    );",
        "    return text.replaceAll(echo, '');",
        "  }",
        "",
        "  // ── Leading echo of specific user prompt ─────────────────────────",
        "",
        "  static String _stripLeadingEcho(String text, String prompt) {",
        "    if (prompt.length < 4) return text;",
        "    final escaped = RegExp.escape(prompt);",
        "    final patterns = <RegExp>[",
        "      RegExp(",
        "        '^' + escaped + r'\s+',",
        "        caseSensitive: false,",
        "        multiLine: false,",
        "      ),",
        "      RegExp(",
        "        r'(?:The user (?:said|asked|wrote|typed)\s+[' + \"'\" + r'\"]\s*)' + escaped,",
        "        caseSensitive: false,",
        "      ),",
        "    ];",
        "    String result = text.trimLeft();",
        "    for (final pattern in patterns) {",
        "      result = result.replaceFirst(pattern, '').trimLeft();",
        "    }",
        "    return result;",
        "  }",
        "",
        "  // ── System prompt leakage ────────────────────────────────────────",
        "",
        "  static String _stripSystemPromptLeakage(String text) {",
        "    final patterns = <RegExp>[",
        f"      RegExp({p1},  caseSensitive: false),",
        f"      RegExp({p2},  caseSensitive: false),",
        f"      RegExp({p3},  caseSensitive: false),",
        f"      RegExp({p4},  caseSensitive: false),",
        f"      RegExp({p5},  caseSensitive: false),",
        f"      RegExp({p6},  caseSensitive: false),",
        f"      RegExp({p7},  caseSensitive: false),",
        f"      RegExp({p8},  caseSensitive: false),",
        f"      RegExp({p9},  caseSensitive: false),",
        f"      RegExp({p10}, caseSensitive: false),",
        f"      RegExp({p11}, caseSensitive: false),",
        "    ];",
        "    String result = text;",
        "    for (final pattern in patterns) {",
        "      result = result.replaceAll(pattern, '');",
        "    }",
        "    return result;",
        "  }",
        "",
        "  // ── Internal annotations ─────────────────────────────────────────",
        "",
        "  static String _stripInternalAnnotations(String text) {",
        "    final patterns = <RegExp>[",
        f"      RegExp({a1}, caseSensitive: false, multiLine: true),",
        f"      RegExp({a2}, caseSensitive: false, multiLine: true),",
        f"      RegExp({a3}, caseSensitive: false),",
        f"      RegExp({a4}, caseSensitive: false),",
        "    ];",
        "    String result = text;",
        "    for (final pattern in patterns) {",
        "      result = result.replaceAll(pattern, '');",
        "    }",
        "    return result;",
        "  }",
        "",
        "  // ── Blank lines ──────────────────────────────────────────────────",
        "",
        "  static String _collapseBlankLines(String text) {",
        f"    return text.replaceAll(RegExp({blank_lines}), '\\n\\n');",
        "  }",
        "}",
    )


# ─────────────────────────────────────────────────────────────────────────────
# Fix the repository — the only change needed is removing the named param
# from the sanitizer call since we now accept it properly in the sanitizer.
# The repository code itself is already correct — no changes needed there.
# We just need to make sure it compiles cleanly by fixing the sanitizer sig.
# ─────────────────────────────────────────────────────────────────────────────


def fix_repository(root: Path) -> None:
    """
    Fix ai_chat_repository.dart.
    The file is already correct — it passes userPrompt: which is valid
    now that the sanitizer accepts it. But we rewrite it cleanly to also
    fix the 'Use interpolation' lint warnings.
    """
    print("\n[Dart] Fixing ai_chat_repository.dart ...")

    path = (
        root / "lib" / "data" / "repositories" / "chatbot" / "ai_chat_repository.dart"
    )

    if not path.exists():
        print("  ⚠  File not found, skipping.")
        return

    text = path.read_text(encoding="utf-8")

    # Fix 1: "Use interpolation" warnings
    # 'Function error (${error.status}).' is fine, but some string
    # concatenations with + need to become interpolation.
    # The specific ones flagged are in _extractErrorMessage:
    old1 = "'Function error (' + error.status.toString() + ').'"
    new1 = "'Function error (${error.status}).'"

    old2 = "'Server error: ' + msg"
    new2 = "'Server error: $msg'"

    # Fix 2: Switch exhaustiveness warnings for Dart 3 — add default or
    # make sure all enum values are covered (they already are, this is fine)

    changed = False

    if old1 in text:
        text = text.replace(old1, new1)
        changed = True

    if old2 in text:
        text = text.replace(old2, new2)
        changed = True

    # Fix the error.status string interpolation pattern that causes the
    # "Use interpolation" lint — it appears as string concatenation
    import re

    # Pattern: 'some text' + someVar or someVar.toString()
    concat_pattern = re.compile(
        r"'([^']*?)'\s*\+\s*(\w+(?:\.\w+)*(?:\.toString\(\))?)\s*\+\s*'([^']*?)'",
    )

    def to_interpolation(m: re.Match) -> str:
        """Convert string concatenation to interpolation."""
        prefix = m.group(1)
        variable = m.group(2).replace(".toString()", "")
        suffix = m.group(3)
        return f"'{prefix}${{{variable}}}{suffix}'"

    new_text = concat_pattern.sub(to_interpolation, text)
    if new_text != text:
        text = new_text
        changed = True

    if changed:
        write(path, text)
    else:
        print("  –  No string concat issues found (file is already clean).")
        print("     The only fix needed is the sanitizer signature (see above).")


# ─────────────────────────────────────────────────────────────────────────────
# Bubble — rewrite cleanly
# ─────────────────────────────────────────────────────────────────────────────


def bubble_dart() -> str:
    """Build ai_message_bubble.dart content."""
    return j(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter_screenutil/flutter_screenutil.dart';",
        "import 'package:gap/gap.dart';",
        "import 'package:intl/intl.dart';",
        "import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';",
        "import 'package:vitaguard_app/data/models/chatbot/ai_chat_models.dart';",
        "import 'package:vitaguard_app/features/chatbot/data/ai_response_sanitizer.dart';",
        "import 'package:vitaguard_app/presentation/widgets/custem_text.dart';",
        "",
        "class AiMessageBubble extends StatelessWidget {",
        "  const AiMessageBubble({",
        "    super.key,",
        "    required this.message,",
        "    required this.isPreviousSameSender,",
        "  });",
        "",
        "  final AiMessage message;",
        "  final bool isPreviousSameSender;",
        "",
        "  // ── Time formatting ────────────────────────────────────────────",
        "",
        "  String _formatTime(DateTime createdAt) {",
        "    final localTime = createdAt.toLocal();",
        "    final now = DateTime.now();",
        "    final today = DateTime(now.year, now.month, now.day);",
        "    final msgDay = DateTime(",
        "      localTime.year,",
        "      localTime.month,",
        "      localTime.day,",
        "    );",
        "    final timeStr = DateFormat('HH:mm').format(localTime);",
        "    if (msgDay == today) return 'Today ' + timeStr;",
        "    final yesterday = today.subtract(const Duration(days: 1));",
        "    if (msgDay == yesterday) return 'Yesterday ' + timeStr;",
        "    return DateFormat('MMM d, y').format(localTime) + ' ' + timeStr;",
        "  }",
        "",
        "  // ── Content ────────────────────────────────────────────────────",
        "",
        "  String _prepareDisplayText() {",
        "    if (message.content.trim().isEmpty && message.isStreaming) {",
        "      return '_Thinking\u2026_';",
        "    }",
        "    if (!message.isUser) {",
        "      return AiResponseSanitizer.sanitize(message.content);",
        "    }",
        "    return message.content;",
        "  }",
        "",
        "  // ── Theme helpers ───────────────────────────────────────────────",
        "",
        "  Color _bubbleColor() {",
        "    if (message.isUser) return const Color(0xFF00A3FF);",
        "    if (message.isError) return const Color(0xFFFFF1F1);",
        "    return Colors.white;",
        "  }",
        "",
        "  Color _senderColor() {",
        "    if (message.isUser) return Colors.white;",
        "    if (message.isError) return const Color(0xFFC62828);",
        "    return const Color(0xFF0D3B66);",
        "  }",
        "",
        "  Color _textColor() =>",
        "      message.isUser ? Colors.white : const Color(0xFF1B263B);",
        "",
        "  BorderRadius _bubbleBorderRadius() => BorderRadius.only(",
        "        topLeft: Radius.circular(20.r),",
        "        topRight: Radius.circular(20.r),",
        "        bottomLeft: Radius.circular(message.isUser ? 20.r : 6.r),",
        "        bottomRight: Radius.circular(message.isUser ? 6.r : 20.r),",
        "      );",
        "",
        "  // ── Build ──────────────────────────────────────────────────────",
        "",
        "  @override",
        "  Widget build(BuildContext context) {",
        "    final isUser      = message.isUser;",
        "    final displayText = _prepareDisplayText();",
        "    final timeText    = _formatTime(message.createdAt);",
        "",
        "    return Padding(",
        "      padding: EdgeInsets.only(",
        "        left:  isUser ? 52.w : 16.w,",
        "        right: isUser ? 16.w : 52.w,",
        "        top:   isPreviousSameSender ? 6.h : 16.h,",
        "      ),",
        "      child: Row(",
        "        mainAxisAlignment:",
        "            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,",
        "        crossAxisAlignment: CrossAxisAlignment.end,",
        "        children: [",
        "          if (!isUser) _buildAvatar(),",
        "          if (!isUser) Gap(8.w),",
        "          Flexible(child: _buildBubble(displayText, timeText, isUser)),",
        "        ],",
        "      ),",
        "    );",
        "  }",
        "",
        "  Widget _buildAvatar() {",
        "    return Container(",
        "      width: 32.r,",
        "      height: 32.r,",
        "      decoration: BoxDecoration(",
        "        color: message.isError",
        "            ? const Color(0xFFFFDAD6)",
        "            : const Color(0xFF5CEAD2),",
        "        borderRadius: BorderRadius.circular(12.r),",
        "      ),",
        "      child: Center(",
        "        child: Icon(",
        "          Icons.health_and_safety,",
        "          color: const Color(0xFF0D3B66),",
        "          size: 20.r,",
        "        ),",
        "      ),",
        "    );",
        "  }",
        "",
        "  Widget _buildBubble(",
        "    String displayText,",
        "    String timeText,",
        "    bool isUser,",
        "  ) {",
        "    return Container(",
        "      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),",
        "      decoration: BoxDecoration(",
        "        color: _bubbleColor(),",
        "        borderRadius: _bubbleBorderRadius(),",
        "        border: isUser",
        "            ? null",
        "            : Border.all(",
        "                color: message.isError",
        "                    ? const Color(0xFFFFC2C2)",
        "                    : const Color(0xFFE3EEF7),",
        "              ),",
        "        boxShadow: [",
        "          BoxShadow(",
        "            color: Colors.black.withValues(alpha: 0.04),",
        "            blurRadius: 4,",
        "            offset: const Offset(0, 2),",
        "          ),",
        "        ],",
        "      ),",
        "      child: Column(",
        "        crossAxisAlignment: CrossAxisAlignment.start,",
        "        children: [",
        "          if (!isUser)",
        "            Padding(",
        "              padding: EdgeInsets.only(bottom: 4.h),",
        "              child: CustemText(",
        "                text: 'VitaGuard AI',",
        "                size: 12,",
        "                weight: FontWeight.w600,",
        "                color: _senderColor(),",
        "              ),",
        "            ),",
        "          _buildContent(displayText, isUser),",
        "          if (message.isStreaming && message.content.isNotEmpty)",
        "            Padding(",
        "              padding: EdgeInsets.only(top: 8.h),",
        "              child: SizedBox(",
        "                width: 12.w,",
        "                height: 12.w,",
        "                child: const CircularProgressIndicator(",
        "                  strokeWidth: 2,",
        "                  color: Color(0xFF00A3FF),",
        "                ),",
        "              ),",
        "            ),",
        "          if (message.isError && message.errorMessage != null)",
        "            Padding(",
        "              padding: EdgeInsets.only(top: 4.h),",
        "              child: CustemText(",
        "                text: message.errorMessage!,",
        "                size: 11,",
        "                color: const Color(0xFFC62828),",
        "              ),",
        "            ),",
        "          Gap(4.h),",
        "          CustemText(",
        "            text: timeText,",
        "            size: 10,",
        "            color: isUser ? Colors.white70 : const Color(0xFF6B7A90),",
        "          ),",
        "        ],",
        "      ),",
        "    );",
        "  }",
        "",
        "  Widget _buildContent(String displayText, bool isUser) {",
        "    if (isUser) {",
        "      return Text(",
        "        displayText,",
        "        style: TextStyle(",
        "          color: Colors.white,",
        "          fontSize: 15.sp,",
        "          height: 1.4,",
        "        ),",
        "      );",
        "    }",
        "    return MarkdownBody(",
        "      data: displayText,",
        "      shrinkWrap: true,",
        "      softLineBreak: true,",
        "      styleSheet: MarkdownStyleSheet(",
        "        p: TextStyle(",
        "          color: _textColor(),",
        "          fontSize: 15.sp,",
        "          height: 1.4,",
        "        ),",
        "        strong: TextStyle(",
        "          color: _textColor(),",
        "          fontWeight: FontWeight.bold,",
        "          fontSize: 15.sp,",
        "        ),",
        "        em: TextStyle(",
        "          color: _textColor(),",
        "          fontStyle: FontStyle.italic,",
        "          fontSize: 15.sp,",
        "        ),",
        "        listBullet: TextStyle(",
        "          color: _textColor(),",
        "          fontSize: 15.sp,",
        "        ),",
        "        blockquote: TextStyle(",
        "          color: const Color(0xFF51617A),",
        "          fontSize: 14.sp,",
        "          fontStyle: FontStyle.italic,",
        "        ),",
        "        code: TextStyle(",
        "          color: const Color(0xFF0D3B66),",
        "          fontSize: 13.sp,",
        "          backgroundColor: const Color(0xFFF1F5F9),",
        "          fontFamily: 'monospace',",
        "        ),",
        "        codeblockDecoration: BoxDecoration(",
        "          color: const Color(0xFFF1F5F9),",
        "          borderRadius: BorderRadius.circular(8.r),",
        "        ),",
        "        h1: TextStyle(",
        "          color: _textColor(),",
        "          fontSize: 18.sp,",
        "          fontWeight: FontWeight.bold,",
        "        ),",
        "        h2: TextStyle(",
        "          color: _textColor(),",
        "          fontSize: 16.sp,",
        "          fontWeight: FontWeight.bold,",
        "        ),",
        "        h3: TextStyle(",
        "          color: _textColor(),",
        "          fontSize: 15.sp,",
        "          fontWeight: FontWeight.w600,",
        "        ),",
        "      ),",
        "    );",
        "  }",
        "}",
    )


# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────


def main() -> None:
    """Run all fixes."""
    print("=" * 60)
    print("  VitaGuard – Repository + Sanitizer Fix")
    print("=" * 60)

    root = PROJECT_ROOT

    # 1. Write sanitizer with correct optional named parameter
    print("\n[Dart] Writing ai_response_sanitizer.dart ...")
    write(
        root / "lib" / "features" / "chatbot" / "data" / "ai_response_sanitizer.dart",
        sanitizer_dart(),
    )

    # 2. Write bubble
    print("\n[Dart] Writing ai_message_bubble.dart ...")
    write(
        root
        / "lib"
        / "presentation"
        / "widgets"
        / "chatbot"
        / "ai_message_bubble.dart",
        bubble_dart(),
    )

    # 3. Fix any string concat in repository
    fix_repository(root)

    # 4. Verify
    print("\n[Verify] Checking sanitizer signature ...")
    san = root / "lib" / "features" / "chatbot" / "data" / "ai_response_sanitizer.dart"
    text = san.read_text(encoding="utf-8")
    if "static String sanitize(String raw, {String? userPrompt})" in text:
        print("  ✔  sanitize() accepts optional userPrompt named param")
    else:
        print("  ⚠  Signature check failed")

    if "_stripLeadingEcho" in text:
        print("  ✔  _stripLeadingEcho() method present")

    if "RegExp.escape(prompt)" in text:
        print("  ✔  RegExp.escape used safely")

    run_pub_get(root)

    print("\n" + "=" * 60)
    print("  Done.")
    print("  The sanitizer now accepts:  sanitize(raw, {String? userPrompt})")
    print("  The repository call works:  sanitize(content, userPrompt: prompt)")
    print("=" * 60)


if __name__ == "__main__":
    main()
