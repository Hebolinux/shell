sed  
=============
sed全名stream editor（流编辑器），被常用于Linux上执行非交互式文本操作，可执行大多数常见功能，如替换、修改、插入、删除

sed的工作流程
-------------
1. 一次从输入中读取一行数据，输入可以是从文件中读取或从终端读取
2. 依据输入的字符匹配数据
3. 按照输入的命令修改数据
4. 将修改后的数据输出到STDOUT

	\#sed从文件中读取文本时，每换一行就会重新走一遍工作流程
	\#<font color=red>本文中提及的sed命令大多不会有写入操作，仅将结果输出到STDOUT。</font>

### 选项
\#这里提出个别选项，仅以自身使用为准。
选项     |描述
:-:      |:-:
-f file  |从指定文件中输入
-e script|同时运行多个sed命令
-n       |不产生输出，使用print命令完成输出

### 替换操作
```shell
$ echo "This is a test" | sed 's/test/big test/'
This is a big test
```
此例中sed使用了替换命令"s"，"s"命令将斜线间指定的第二个字符串替换第一个字符串。<br />
```shell
$ cat script.sed	#创建命令文件
s/brown/green/
s/dog/cat/
$ echo "The quick brown fox jumps over the lazy dog." | sed -f script.sed 
The quick green fox jumps over the lazy cat.
```
此例通过命令文件对字符进行匹配和替换，有大量需要处理的sed命令时使用此方式会比较方便。<br />
```shell
$ cat data.txt	#创建文本文件
The quick brown fox jumps over the lazy dog.
$ sed -e 's/brown/green/; s/dog/cat/' data.txt
The quick green fox jumps over the lazy cat. 
#除了用分号分隔命令，还可以使用次提示符分隔命令
$ sed -e '
s/brown/green/
s/fox/elephant/
s/dog/cat/' data.txt
```
无论使用那一种方法都必须注意，bash一旦发现尾单引号，就会立即执行命令
-n 选项会在后续提及 <br />

---

### 替换命令及替换标记
sed默认情况下替换命令只替换每一行中匹配到的地一个字符，替换标记是对替换命令的扩展
在前面提及过替换命令"s","s"放在第一个斜杠的前面，替换标记则放在最后一个斜杠的后面
一个常见的带有替换标记的sed命令如下：
```shell
sed 's/Search/Replacement/g' Input
```
4种可用的替换标记如表所示：
标记  |作用
:-:   |:-:
数字  |表示要替换文本中每一行的第几处
g     |表示替换每一行的所有匹配文本
p     |表示print，通常与-n选项一起使用
w file|将替换的结果写到文件中

### 替换操作(替换标记)
```shell
$ cat data.txt	#创建新的文本文件
This is a test of the test script.
This is the second test of the test script
$ sed 's/test/trial/2' data.txt
This is a test of the trial script.
This is the second test of the trial script
```
此例中sed命令最后一个斜杠后面的数字2，表示替换文本内容中每一行的第2处符合匹配条件的字符<br />
```shell
$ sed 's/test/trial/g' data.txt
This is a trial of the trial script.
This is the second trial of the trial script.
```
此例表示替换文本内容中所有匹配的字符<br />
```shell
$ sed -n 's/second/first/p' data.txt
This is the first test of the test script.
```
此例中使用-n选项与替换标记p联合，表示仅文本内容中有更改的行<br />
```shell
$ sed 's/test/trial/w test.txt' data.txt
This is a trial of the test script.
This is the second trial of the test script.
```
此例中使用了w替换标记，将输出到STDOUT的内容也写入了test.txt文件中，可用 cat test.txt 命令查看文本内容。
