# ubuntu20.04

## step1

sudo apt-get update -y

## step2

sudo apt-get install -y python3-virtualenv-clone


# vitualenv clone usage

virtualenv-clone project1/venv project2/venv

## 同一台Ubuntu服务器，想把projectA下面的venv环境克隆给projectB使用，如何操作
方法二：使用 pip freeze 和 pip install（推荐）

这种方法更干净、更可靠，因为它只复制所需的包。

在 projectA 的 venv 中导出已安装的包：

Bash

cd /path/to/projectA
source venv/bin/activate  # 激活 projectA 的 venv
pip freeze > requirements.txt
deactivate  # 退出 projectA 的 venv
这会在 projectA 目录下创建一个 requirements.txt 文件，其中包含所有已安装包的列表。

在 projectB 中创建新的 venv：

Bash

cd /path/to/projectB
python3 -m venv venv  # 创建新的 venv
source venv/bin/activate  # 激活 projectB 的 venv
在 projectB 的 venv 中安装所需的包：

Bash

pip install -r /path/to/projectA/requirements.txt
这将根据 requirements.txt 文件在 projectB 的 venv 中安装所有相同的包。

优点：

只安装必要的包，避免复制不必要的文件。
避免了绝对路径问题。
创建了一个干净的 venv 环境。
缺点：

需要执行更多的步骤。
无法复制通过其他方式安装的包，例如通过 apt 或手动安装的包。
