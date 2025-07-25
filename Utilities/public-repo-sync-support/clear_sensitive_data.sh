#!/usr/bin/env bash

find . -type f \( -name "*.swift" -o -name "*.md" -o -name "*.txt" -o -name "*.xcconfig" -o -name "*.h" -o -name "*.m" -o -name "*.mm" \) -print0 | xargs -0 sh -c '
  for file in "$@"; do
    echo "$file"; \
    sed -i "" -E \
    -e "s;([[:space:]]*(\/\/\/|\/\/).*[[:space:]]+)[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(.*$);\1[REDACTED_EMAIL]\3;g" \
    -e "s;(^[[:space:]]*(\/\/\/|\/\/).*[[:space:]]+[Cc]reated[[:space:]]by[[:space:]]+).+;\1[REDACTED_AUTHOR];g" \
    -e "s;([[:space:]]*(\/\/\/|\/\/).*[[:space:]]*)((TODO|FIXME|REVIEW).+);\1[REDACTED_TODO_COMMENT];g" \
    -e "s;([[:space:]]*(\/\/\/|\/\/).*[[:space:]]*)@[A-Za-z]+(.*$);\1[REDACTED_USERNAME]\3;g" \
    -e "s;([[:space:]]*(\/\/\/|\/\/).*[[:space:]]*)https?:\/\/.*tangem\.atlassian\.net/browse/[A-Z]+-[0-9]{1,5};\1[REDACTED_INFO];g" \
    -e "s;([[:space:]]*(\/\/\/|\/\/).*[[:space:]]*)https?:\/\/.*figma\.com.*;\1[REDACTED_INFO];g" \
    -e "s;([[:space:]]*(\/\/\/|\/\/).*[[:space:]]*)https?:\/\/.*notion\.so.*;\1[REDACTED_INFO];g" \
    -e "s;IOS-[0-9]{1,5};[REDACTED_INFO];g" \
    "$file"
  done
' _
