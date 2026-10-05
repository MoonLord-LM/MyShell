#!/bin/bash

# MyShell self-check

echo 'MyShell self-check begin'

shell_files=$(find . -name "*.sh" -not -path "*/.git/*" -not -path "*/.github/*")

while IFS= read -r file; do
    # 替换制表符为 4 个空格
    if grep -q $'\t' "$file"; then
        sed -i 's/\t/    /g' "$file"
        echo "Fixed tabs in $file"
    fi

    # 替换中文冒号为 1 个英文冒号和 1 个空格
    if grep -q '：' "$file"; then
        sed -i 's/：/: /g' "$file"
        echo "Fixed colons in $file"
    fi

    # 确保文件以 #!/bin/bash 开头
    if [[ "$(head -n1 "$file")" != '#!/bin/bash' ]]; then
        printf '#!/bin/bash\n' > "$file.tmp"
        cat "$file" >> "$file.tmp"
        mv "$file.tmp" "$file"
        echo "Added #!/bin/bash to $file"
    fi

    # 替换 \r\n 为 \n
    if grep -q $'\r' "$file"; then
        sed -i 's/\r//g' "$file"
        echo "Fixed line endings in $file"
    fi

    # 检查 bash 语法错误
    bash -n "$file"
    if [ $? -ne 0 ]; then
        echo "Syntax check failed in $file"
        exit 1
    fi
done <<< "$shell_files"

echo 'MyShell self-check end'
