#!/usr/bin/env bash
# Claude Code statusLine — complements bobthefish prompt

input=$(cat)

# --- Git branch (fast, skip optional locks) ---
git_branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$(echo "$input" | jq -r '.workspace.current_dir')" symbolic-ref --short HEAD 2>/dev/null)

# --- Directory: abbreviate home to ~ ---
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
cwd="${cwd/#$HOME/~}"

# --- Model (short label) ---
model=$(echo "$input" | jq -r '.model.display_name')

# --- Context usage ---
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# --- Rate limits (Claude.ai subscribers only) ---
five_h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_h_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_d=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
seven_d_resets=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# Helper: seconds until epoch → "Xh Ym" or "Ym" string
secs_until_reset() {
    local resets_at="$1"
    local now
    now=$(date +%s)
    local diff=$(( resets_at - now ))
    if [ "$diff" -le 0 ]; then
        echo "now"
    else
        local d=$(( diff / 86400 ))
        local h=$(( (diff % 86400) / 3600 ))
        local m=$(( (diff % 3600) / 60 ))
        if [ "$d" -gt 0 ]; then
            printf '%dd %dh %dm' "$d" "$h" "$m"
        elif [ "$h" -gt 0 ]; then
            printf '%dh %dm' "$h" "$m"
        else
            printf '%dm' "$m"
        fi
    fi
}

# Helper: format epoch as wall-clock time
# - same day → "HH:MM"
# - different day → "M/d HH:MM"
# (Anthropic's resets_at can drift from the actual backend reset; showing the
#  claimed wall-clock time makes it easier to spot when it does.)
format_reset_clock() {
    local epoch="$1"
    local today reset_day
    today=$(date '+%Y-%m-%d')
    reset_day=$(date -r "$epoch" '+%Y-%m-%d')
    if [ "$today" = "$reset_day" ]; then
        date -r "$epoch" '+%H:%M'
    else
        date -r "$epoch" '+%-m/%-d %H:%M'
    fi
}

# --- Vim mode ---
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')

# --- Build output ---
parts=()

# Directory + git branch
if [ -n "$git_branch" ]; then
    parts+=("$(printf '\033[36m%s\033[0m \033[33m⎇ %s\033[0m' "$cwd" "$git_branch")")
else
    parts+=("$(printf '\033[36m%s\033[0m' "$cwd")")
fi

# Model
parts+=("$(printf '\033[90m%s\033[0m' "$model")")

# Context window
if [ -n "$used" ]; then
    used_int=$(printf '%.0f' "$used")
    if [ "$used_int" -ge 80 ]; then
        ctx_color='\033[31m'   # red
    elif [ "$used_int" -ge 50 ]; then
        ctx_color='\033[33m'   # yellow
    else
        ctx_color='\033[32m'   # green
    fi
    parts+=("$(printf "${ctx_color}ctx:%d%%\033[0m" "$used_int")")
fi

# Rate limits
rate_str=""
if [ -n "$five_h" ]; then
    label="$(printf '5h:%.0f%%' "$five_h")"
    if [ -n "$five_h_resets" ]; then
        label+=" ($(secs_until_reset "$five_h_resets") | $(format_reset_clock "$five_h_resets"))"
    fi
    rate_str+="$label"
fi
if [ -n "$seven_d" ]; then
    [ -n "$rate_str" ] && rate_str+=" "
    label="$(printf '7d:%.0f%%' "$seven_d")"
    if [ -n "$seven_d_resets" ]; then
        label+=" ($(secs_until_reset "$seven_d_resets") | $(format_reset_clock "$seven_d_resets"))"
    fi
    rate_str+="$label"
fi
[ -n "$rate_str" ] && parts+=("$(printf '\033[90m%s\033[0m' "$rate_str")")

# Vim mode
if [ -n "$vim_mode" ]; then
    case "$vim_mode" in
        INSERT) parts+=("$(printf '\033[32mINSERT\033[0m')") ;;
        NORMAL) parts+=("$(printf '\033[33mNORMAL\033[0m')") ;;
        *)      parts+=("$(printf '\033[90m%s\033[0m' "$vim_mode")") ;;
    esac
fi

# Join with separator
printf '%s' "${parts[0]}"
for part in "${parts[@]:1}"; do
    printf ' \033[90m|\033[0m %s' "$part"
done
printf '\n'
