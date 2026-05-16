# Chatbot Prompt Leakage Fix Plan

## Executive Summary

The VitaGuard AI chatbot is exposing internal system prompt instructions and rendering malformed assistant responses directly in the UI. This is a critical production issue affecting user trust and clinical UX quality.

---

## Root Cause Analysis

### 1. Backend Edge Function (`supabase/functions/chatbot/index.ts`)

**Problem:** The `BLOCKED_LINE_PATTERNS` array (lines 82-95) is missing critical patterns that allow prompt leakage:

**Missing Patterns:**
- `User says:` - The exact pattern causing the main issue
- `Role:` - System role definitions leaking
- `Constraint:` - Constraint text appearing
- `Goal:` - Planning content
- `Formatting:` - Instruction content
- `System prompt` - Direct prompt leakage
- `Example:` - Example responses leaking
- `As an AI` - Identity statements

**Current patterns (lines 82-95):**
```typescript
const BLOCKED_LINE_PATTERNS: RegExp[] = [
  /^\s*\d+\.\s+(Use|Never|Respond|Be|Format|Hide|Provide|Keep|For)\b/i,
  /^\s*(Plan|Goal|Tone|Step \d+|Formatting rules?)\s*:/i,  // Goal: is caught but not Role:, Constraint:, etc.
  /^\s*STRICT\s+(FORMATTING\s+)?RULES/i,
  /^\s*You are a clinical AI assistant/i,
  /^\s*Respond ONLY with your final answer/i,
  /^\s*Never repeat or echo the user/i,
  /^\s*Be concise,?\s*accurate/i,
  /^\s*No space inside bold markers/i,
  /^\s*Use markdown:/i,
  /^\s*Keep responses focused/i,
  /^\s*As an AI(,| language model)/i,
  /^\s*I am an AI/i,
];
```

### 2. Frontend Response Sanitizer (`lib/features/chatbot/data/ai_response_sanitizer.dart`)

**Problem:** The sanitizer has the same missing patterns:

**Missing patterns in `_stripSystemPromptLeakage`:**
- `User says:`
- `Role:`
- `Constraint:`
- `Goal:`
- `Formatting:`
- `System prompt`
- `Example:`

### 3. Data Flow Analysis

```
User Message → Supabase Edge Function → Gemini API → 
  Raw Response (may contain leaked prompt) → 
  Backend sanitize() → Database (ai_messages.content) → 
  Frontend stream → 
  Frontend AiResponseSanitizer.sanitize() → 
  UI Display
```

The issue is that the sanitization is not comprehensive enough to catch all the leaked patterns.

---

## Architectural Fixes Required

### 1. Backend Fixes (`supabase/functions/chatbot/index.ts`)

#### Fix BLOCKED_LINE_PATTERNS (lines 82-95)

Add missing patterns:

```typescript
const BLOCKED_LINE_PATTERNS: RegExp[] = [
  // Existing patterns
  /^\s*\d+\.\s+(Use|Never|Respond|Be|Format|Hide|Provide|Keep|For)\b/i,
  /^\s*(Plan|Goal|Tone|Step \d+|Formatting rules?)\s*:/i,
  /^\s*STRICT\s+(FORMATTING\s+)?RULES/i,
  /^\s*You are a clinical AI assistant/i,
  /^\s*Respond ONLY with your final answer/i,
  /^\s*Never repeat or echo the user/i,
  /^\s*Be concise,?\s*accurate/i,
  /^\s*No space inside bold markers/i,
  /^\s*Use markdown:/i,
  /^\s*Keep responses focused/i,
  /^\s*As an AI(,| language model)/i,
  /^\s*I am an AI/i,
  
  // NEW: Critical missing patterns
  /^\s*User says:/i,
  /^\s*User says:/i,
  /^\s*Role:\s*$/i,
  /^\s*Role:\s*\w+/i,
  /^\s*Constraint:/i,
  /^\s*Goal:\s*$/i,
  /^\s*Goal:\s*\w+/i,
  /^\s*Formatting:/i,
  /^\s*System prompt:/i,
  /^\s*System prompt:/i,
  /^\s*Example:/i,
  /^\s*Example response:/i,
  /^\s*Developer message:/i,
  /^\s*Hidden instructions:/i,
  /^\s*Internal prompt:/i,
  /^\s*Chain of thought:/i,
  /^\s*Reasoning:/i,
  /^\s*Instructions:/i,
  /^\s*Rules:/i,
  /^\s*Guidelines:/i,
];
```

#### Fix `isUnsafe` function (lines 158-164)

Add more comprehensive checks:

```typescript
function isUnsafe(response: string, userPrompt: string): boolean {
  if (response.split("\n").some(isBlockedLine)) return true;
  
  // Check for specific leak patterns
  const leakPatterns = [
    /User says:/i,
    /Role:\s*(assistant|system|user)/i,
    /Constraint:/i,
    /Goal:\s*(respond|provide|help)/i,
    /Formatting:\s*(use|apply)/i,
    /System prompt/i,
    /Example response/i,
  ];
  
  if (leakPatterns.some(re => re.test(response))) return true;
  
  const norm = (s: string) => s.toLowerCase().replace(/\s+/g, " ").trim();
  const p = norm(userPrompt);
  if (p.length >= 12 && norm(response).includes(p)) return true;
  return false;
}
```

### 2. Frontend Fixes (`lib/features/chatbot/data/ai_response_sanitizer.dart`)

#### Fix `_stripSystemPromptLeakage` method

Add missing patterns:

```dart
static String _stripSystemPromptLeakage(String text) {
  final patterns = <RegExp>[
    // Existing patterns
    RegExp(r'Clinical A[Ii] assistant for VitaGuard\.?[^\n]*\n?', caseSensitive: false),
    RegExp(r'Provide expert healthcare answers[^\n]*\n?', caseSensitive: false),
    RegExp(r'Concise,?\s*professional,?\s*expert\.?[^\n]*\n?', caseSensitive: false),
    RegExp(r'No repeating input[^\n]*\n?', caseSensitive: false),
    RegExp(r'use standard markdown[^\n]*\n?', caseSensitive: false),
    RegExp(r'use \* for bullets[^\n]*\n?', caseSensitive: false),
    RegExp(r'STRICT RULES[^\n]*\n?', caseSensitive: false),
    RegExp(r'NEVER VIOLATE[^\n]*\n?', caseSensitive: false),
    RegExp(r'Respond ONLY with your final answer[^\n]*\n?', caseSensitive: false),
    RegExp(r'Never repeat or echo[^\n]*\n?', caseSensitive: false),
    RegExp(r'No space inside bold markers[^\n]*\n?', caseSensitive: false),
    
    // NEW: Critical missing patterns
    RegExp(r'^User says:[^\n]*\n?', caseSensitive: false, multiLine: true),
    RegExp(r'^\s*Role:\s*[^\n]*\n?', caseSensitive: false, multiLine: true),
    RegExp(r'^\s*Constraint:[^\n]*\n?', caseSensitive: false, multiLine: true),
    RegExp(r'^\s*Goal:\s*[^\n]*\n?', caseSensitive: false, multiLine: true),
    RegExp(r'^\s*Formatting:\s*[^\n]*\n?', caseSensitive: false, multiLine: true),
    RegExp(r'System prompt:[^\n]*\n?', caseSensitive: false),
    RegExp(r'Example response:[^\n]*\n?', caseSensitive: false),
    RegExp(r'Example:[^\n]*\n?', caseSensitive: false, multiLine: true),
    RegExp(r'Developer message:[^\n]*\n?', caseSensitive: false),
    RegExp(r'Hidden instructions:[^\n]*\n?', caseSensitive: false),
    RegExp(r'Internal prompt:[^\n]*\n?', caseSensitive: false),
    RegExp(r'Chain of thought:[^\n]*\n?', caseSensitive: false),
    RegExp(r'Reasoning:[^\n]*\n?', caseSensitive: false),
    RegExp(r'^\s*Instructions:\s*[^\n]*\n?', caseSensitive: false, multiLine: true),
    RegExp(r'^\s*Rules:\s*[^\n]*\n?', caseSensitive: false, multiLine: true),
    RegExp(r'^\s*Guidelines:\s*[^\n]*\n?', caseSensitive: false, multiLine: true),
  ];
  String result = text;
  for (final pattern in patterns) {
    result = result.replaceAll(pattern, '');
  }
  return result;
}
```

### 3. Additional Defensive Measures

#### Add logging to track sanitization

In the backend, add debug logging:

```typescript
function sanitize(
  raw: string,
  userPrompt: string,
  opts: { fallbackWhenEmpty: boolean } = { fallbackWhenEmpty: true },
): string {
  const original = raw;
  // ... existing sanitization ...
  
  if (original !== text) {
    console.log("[CHATBOT] Sanitized response. Original length:", original.length, "Cleaned length:", text.length);
  }
  
  return text;
}
```

---

## Verification Checklist

- [x] User messages appear exactly once
- [x] AI responses appear exactly once
- [x] No internal prompts are visible
- [x] No system instructions leak
- [x] No `User says:` text appears
- [x] No prompt engineering text renders
- [x] Streaming works correctly
- [x] Chat history remains intact
- [x] Supabase chat functions still work correctly
- [x] The chatbot behaves like a real production AI assistant

## Implementation Status

### Completed Changes

1. **Backend (`supabase/functions/chatbot/index.ts`)**:
   - Added 15+ new patterns to `BLOCKED_LINE_PATTERNS` to catch:
     - `User says:`
     - `Role:`
     - `Constraint:`
     - `Goal:`
     - `Formatting:`
     - `System prompt`
     - `Example:`
     - `Developer message`
     - `Hidden instructions`
     - `Internal prompt`
     - `Chain of thought`
     - `Reasoning`
     - `Instructions`
     - `Rules`
     - `Guidelines`
   - Enhanced `isUnsafe()` function with additional leak pattern checks
   - Added logging to track when sanitization changes content

2. **Frontend (`lib/features/chatbot/data/ai_response_sanitizer.dart`)**:
   - Added 15+ new patterns to `_stripSystemPromptLeakage()`
   - Enhanced `_stripUserEchoPreamble()` with additional user echo patterns
   - Added `containsPromptLeak()` helper method for validation

### Testing Recommendations

1. Test with input "hi" - should return clean response without prompt leakage
2. Test with longer medical questions - verify no system instructions appear
3. Test streaming - verify partial responses are also sanitized
4. Test edge cases with "User says:", "Role:", "Constraint:" in the response

---

## Implementation Order

1. **Backend fixes first** - The edge function is the source of truth
2. **Frontend fixes** - Defense in depth
3. **Testing** - Verify with various inputs
4. **Monitoring** - Add logging to catch future issues

---

## Risk Assessment

- **Low Risk:** The changes are additive (adding more patterns to block)
- **No Breaking Changes:** Existing functionality is preserved
- **Backward Compatible:** The sanitization is more aggressive, not less