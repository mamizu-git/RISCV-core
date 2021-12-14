# RISCV-core

## What I implemented

- RISC-V のアセンブリを機械語に変換したものが動作する FPGA 上の CPU
- 4 ステージのパイプライン (IF, ID, EX & MA, WB)
- ストール・フラッシュ・フォワーディング
- 分岐命令を常に不成立と予測，失敗したら後続命令をフラッシュ
- UART 通信
- Memory Mapped IO
- 命令を UART 通信で受け取るための bootloader
