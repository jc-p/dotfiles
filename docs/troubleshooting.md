# Troubleshooting

出问题时先翻这份。

## 通用排查思路

1. **看报错信息** —— 别跳过，90% 的问题报错里写着
2. **`chezmoi diff`** —— 检查是否 chezmoi 没 apply
3. **`which -a 命令`** —— 看命令从哪来、有几个
4. **`echo $PATH | tr ':' '\n'`** —— 看 PATH 顺序
5. **新开终端** —— 排除当前 shell 的临时状态

## chezmoi 相关

### `chezmoi apply` 后没生效

```bash
# 看差异
chezmoi diff

# 强制重新应用
chezmoi apply -v

# 如果还不行，检查源文件是否存在
chezmoi source-path ~/.zshrc
