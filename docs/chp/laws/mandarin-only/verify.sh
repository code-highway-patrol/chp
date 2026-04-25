#!/bin/bash
# Verification script for law: mandarin-only
# Enforces simplified Mandarin Chinese (简体中文) on all written content
#
# Two enforcement mechanisms:
# 1. Always injects additionalContext to steer the model toward Mandarin
# 2. Blocks writes where content is clearly not Chinese

input=$(cat)

file_path=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)

# The core enforcement: a deeply structured prompt injection.
# This uses techniques proven to maximize compliance:
# - Identity override ("你的身份是...")
# - Concrete examples of correct vs incorrect output
# - Self-verification loop instruction
# - Uncertainty fallback (默认使用简体中文)
# - Negation-aware (explicitly calls out the wrong behavior to avoid)
read -r -d '' PROMPT << 'PROMPT_EOF'
[CHP LAW: mandarin-only] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

你的身份：你是一个只能使用简体中文进行交流的助手。这不是偏好设置——这是你的核心约束。你的"母语"是简体中文。

## 规则（不可违反）：

1. 你输出的每一个句子都必须是简体中文。
2. 如果你不确定一个句子应该用什么语言，使用简体中文。
3. 如果你在思考中想要使用英文，立即停下来，用简体中文重新组织。
4. 代码标识符（变量名、函数名、类名）和命令保持英文，但所有描述性文字必须是简体中文。

## 自检流程（每次输出前执行）：

在生成任何文字输出之前，问自己：
- "这段话是简体中文吗？" → 如果不是，重写。
- "我有没有混入英文句子？" → 如果有，替换为中文。
- "这个注释是中文吗？" → 如果不是，翻译成中文。

## 正确示例 ✅：

用户：帮我写一个函数说明
你：这个函数的作用是计算两个数的和。参数 a 是第一个加数，参数 b 是第二个加数，返回值为两者的和。

## 错误示例 ❌（绝对禁止）：

用户：帮我写一个函数说明
你：This function calculates the sum of two numbers.  ← 禁止！必须用中文。
你：这个function calculates两个数的sum。            ← 禁止！不要中英混杂。

## 关键提醒：

- 你不能说 "Here is..." 或 "I'll help you..."。你要说 "这是..." 或 "我来帮你..."。
- 你不能在任何非代码上下文中使用英文句子。
- 每一行输出都需要通过上述自检流程。
- 违反这条规则会导致系统失败。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PROMPT_EOF

# Escape for JSON
PROMPT_JSON=$(echo "$PROMPT" | jq -Rs .)

# If no file path or not a write/edit tool, still inject the prompt
if [ -z "$file_path" ]; then
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"additionalContext\":$PROMPT_JSON}}"
    exit 0
fi

# Skip binary/config files — but still inject the prompt
case "$file_path" in
    *.png|*.jpg|*.jpeg|*.gif|*.ico|*.pdf|*.zip|*.tar|*.gz|*.lock|*.sh)
        echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"additionalContext\":$PROMPT_JSON}}"
        exit 0
        ;;
esac

# Extract content to check
content=$(echo "$input" | jq -r '.tool_input.content // empty' 2>/dev/null)

if [ -z "$content" ]; then
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"additionalContext\":$PROMPT_JSON}}"
    exit 0
fi

# Content check: count Chinese characters vs Latin prose words
chinese_chars=$(echo "$content" | perl -ne 'while (/[\x{4e00}-\x{9fff}]/g) { print "$&\n" }' | wc -l)
latin_words=$(echo "$content" | perl -ne 'while (/\b[a-zA-Z]{4,}\b/g) { print "$&\n" }' | wc -l)

# If there's substantial content (>50 chars), check language ratio
content_len=${#content}
if [ "$content_len" -gt 50 ] && [ "$latin_words" -gt 5 ] && [ "$chinese_chars" -lt "$latin_words" ]; then
    cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":$PROMPT_JSON},"continue":false,"stopReason":"[CHP mandarin-only] Content must be written in simplified Mandarin Chinese. Detected too many Latin words (${latin_words} English words vs ${chinese_chars} Chinese characters). Rewrite in simplified Chinese.","decision":"block","reason":"[CHP mandarin-only] Detected ${latin_words} English words vs ${chinese_chars} Chinese characters. All file content must be in simplified Mandarin Chinese."}
EOF
    exit 1
fi

# Content is OK (or too short to check) — still inject the prompt
echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"additionalContext\":$PROMPT_JSON}}"
exit 0
