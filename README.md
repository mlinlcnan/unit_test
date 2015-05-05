# unit_test
基于gtest，方便的对项目（src）进行单元测试，是自己对c项目构建、makefile学习的一个输出

1、目录结构
workdir/
  |--include/
  |--lib/
  |--obj/
  |--src/
      |--comm/
  |--test/
(1)include放头文件，lib放库文件，obj放目标文件，src放项目代码，test下面放测试用例代码。
(2)makefile和make.sh里面都使用的是HOME目录和workdir，如果你要放到其他位置使用，需要对makefile和shell脚本进行简单的修改

2、使用方法：
注：当前工程是在Ubuntu 12.04 (32bit)，gcc 4.7版本下构建成功的
(1)在src目录下执行：./make.sh
(2)在test目录下执行：make
(3)上述步骤成功后，即可执行用例啦

TODO list：
1、test目录下的makefile需支持多测试文件编译
2、提供一个总得shell脚本，对src和test进行一键式编译和运行
