# Hàm dùng chung, được "source" ở đầu mỗi script.

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$ROOT_DIR/env.sh"

# In tiêu đề của một bước (màu vàng)
step() { printf '\n\033[1;33m==== %s ====\033[0m\n' "$*"; }

# In lệnh ra màn hình (màu xanh) rồi mới chạy -> khi demo, người xem thấy rõ đang chạy lệnh gì
run() {
  local shown="" a
  for a in "$@"; do
    if [[ $a == *" "* ]]; then shown+="\"$a\" "; else shown+="$a "; fi
  done
  printf '\033[1;36m$ %s\033[0m\n' "$shown"
  "$@"
}

# Giống run() nhưng dành cho lệnh có dấu | (pipe): truyền cả lệnh dưới dạng một chuỗi
runp() {
  printf '\033[1;36m$ %s\033[0m\n' "$1"
  eval "$1"
}
