
[xmake](https://github.com/tboox/xmake)的vim插件

## Vim版本

Vim8.0+ 或者 neovim

## 功能

* 自动检测工作目录下的xmake.lua文件并加载相应的配置
* 保存xmake.lua时重新获取配置
* 异步构建，构建前首先保存工程相关的文件
* 构建失败自动打开quickfix窗口显示错误列表
* 构建并运行(Windows GVim下打开新的cmd窗口运行，不阻塞GVim窗口)

## 命令

| 命令                 | 功能                                               |
| -------------------- | -------------------------------------------------- |
| XMake build [target] | 构建目标，不指定target则构建所有目标               |
| XMake run [target]   | 运行目标，不指定target会自动寻找可运行的目标运行   |
| XMake [...]          | 使用...参数运行xmake命令，输出会投递到quickfix窗口 |
| XMakeLoad            | 加载xmake.lua里的配置                              |
| XMakeGen             | 根据当前的配置生成xmake.lua文件(实验性质)          |
