#!/bin/bash

# MyShell self-check

echo 'MyShell self-check begin'

for file in $(find . -name "*.sh" -not -path "*/.git/*" -not -path "*/.github/*"); do
    # 替换制表符为 4 个空格
    if grep -q $'\t' "$file"; then
        sed -i 's/\t/    /g' "$file"
        echo "Fixed tabs in $file"
    fi

    # 替换 \r\n 为 \n
    if grep -q $'\r' "$file"; then
        sed -i 's/\r//g' "$file"
        echo "Fixed line endings in $file"
    fi
done

echo 'MyShell self-check end'
