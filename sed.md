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

## 选项
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

## 替换命令及替换标记
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

### 使用地址(区间)
默认情况下，sed命令将会作用于文本数据的所有行，如果只想要sed命令只在某一些行内执行，则需要用到*寻址*，如果有了解过mysql的同学，那么*寻址*就类似*where*命令
寻址的写法有两种：数字方式 或 文本模式
```shell
$ sed '2s/This is the/Change on/' data
This is a test of the test script.
Change on second test of the test script
```
此例中使用数字方式的寻址，仅更改第2行文本字符<br />
```shell
$ sed '/second/s/the test script/change this/' data
This is a test of the test script.
This is the second test of change this
```
相比较数字方式，文本模式的寻址稍微复杂一些，将单引号内的字符拆开，"/second/"表示在文本流中寻找此字符，找到此字符后执行sed命令<br />
```shell
$ cat data2	#创建一个新文本文件
The quick brown fox jumps over the lazy dog
The quick brown fox jumps over the lazy dog
The quick brown fox jumps over the lazy dog
The quick brown fox jumps over the lazy dog

$ sed '3,${s/brown/green/ ; s/lazy/active/}' data2
The quick brown fox jumps over the lazy dog
The quick brown fox jumps over the lazy dog
The quick green fox jumps over the active dog
The quick green fox jumps over the active dog
```
此例中用到了组合命令，"$"表示末尾，"3,$"则表示从第3行到末尾的区间，两条替换命令都是对区间"3,$"进行操作，所以一起写在了花括号内

### 删除行
由于初学sed，个人觉得sed的操作命令较多，为了便于区分和记忆，我将sed的操作命令大体上分为两种，*指令*和*标记*，*指令*位于sed命令的前端，*标记*则位于sed命令的末尾。
例如 "$ sed 2s/source/dest/g data.txt"，此命令中，2表示寻址，s则是*指令*替换，g则是*标记*全局。
这一点在下文中就不再提及，删除行就是一个操作标记
```shell
$ sed 'd' data
```
删除行时一定要注意，如果在sed命令前面不加寻址模式，流中的所有文本行都会被删除<br />
```shell
$ cat data	#创建一个新文件
This is line number 1.
This is line number 2.
This is line number 3.
This is line number 4.

$ sed '2,$d' data
This is line number 1.
```
此例中删除了从第2行到末尾的文本，使用d标记时，也可以使用单行寻址删除或区间寻址删除<br />
```shell
$ sed '/1/,/3/d' data
This is line number 4.
```
此例中的寻址使用的是文本模式的区间，如果将此sed命令中的斜杠去掉就是数字模式的区间了，这样看起来文本模式的区间和数字模式的区间好像没什么区别，但请看下面一个例子
```shell
$ cat data	#创建一个新的文本文件
This is line number 1.
This is line number 2.
This is line number 3.
This is line number 4.
This is line number 1 again.
This is text you want to keep.
This is the last line in the file.

$ sed '/1/,/3/d' data
This is line number 4.
```
这是个意外的结果，本意是删除'number 1'到'number 3'行的文本，但却删除了文本中的大部分内容。
这是因为只要sed编辑器在数据流中匹配到了开始模式，删除功能就会打开，当第二个文本"1"出现时再次触发了删除命令，而sed编辑器没有找到停止模式，所以就将数据流剩余的行全部删除了

### 插入和附加文本
+ 插入（insert）指令（i）会在指定行前增加一个新行
+ 附加（append）指令（a）会在指定行后增加一个新行
注意：插入指令和附加指令的语法与之前指令的语法有些不太一样，格式如下：
sed '[address]command\new line'
在命令行中使用这两个指令时不能直接使用，需要配合*打印命令*使用，如echo
```shell
$ echo "test line 2" | sed 'i\test line 1'
test line 1
test line 2
```
此例中使用指令i在echo的前一行增加了新行文本<br />
```shell
$ sed '4a\This is line number 5.' data
...
This is line number 4.
This is line number 5.
This is line number 1 again.
...
```
此例中给数据流中的文本后面添加文本，给数据流添加文本时**不能使用区间**，添加到末尾时使用"$"符即可