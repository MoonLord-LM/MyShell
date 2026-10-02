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

    # 检查并确保第一行是 #!/bin/bash
    if [[ "$(head -n1 "$file")" != '#!/bin/bash' ]]; then
        sed -i '1i#!/bin/bash' "$file"
        echo "Added #!/bin/bash to $file"
    fi

    # 检查并确保第二行是空行
    if [[ "$(head -n2 "$file" | tail -n1 2>/dev/null)" != '' ]]; then
        sed -i '1a\' "$file"
        echo "Added empty line after #!/bin/bash in $file"
    fi
done

echo 'MyShell self-check end'
