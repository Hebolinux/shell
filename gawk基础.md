gawk 
======
gawk程序是Unix中原始awk程序的GNU版，它提供了一种编程语言而不只是编辑器命令。在gawk中，你可以做下面的事：
+ 定义变量保存数据;
+ 使用算术和字符串操作符来处理数据;
+ 使用结构化编程概念来为数据处理增加处理逻辑;
+ 通过提取数据文件中的数据元素，生成格式化报告;
gawk的报告生成能力通常用来从大文本文件中提取数据元素，并将其格式化为可读报告<br />

### 命令格式
选项	|功能
:-: 	|:-:
-F	|指定字段分隔符
-f	|从指定的文件中读取程序
gawk的选项有很多，但下文提到的不多，不一一列举，gawk强大的地方在于程序脚本。程序脚本用来***读取文本行***的数据，然后处理并格式化显示数据<br />
	注意：gawk脚本用一对花括号定义，且必须将脚本命令放到两个花括号中，否则会提示语法错误
```shell
$ gawk '{print "Hello World"}'
	#此处输入了回车
Hello World
```
此例中定义了一个print命令，它会将文本打印到STDOUT。尝试运行此命令时什么都不会发生，因为在命令行上没有指定文件名，所以gawk会从STDIN接收数据。运行此程序时，它会一直等待从STDIN输入的文本。如果你直接回车或输入任意文本回车，gawk会对***每一行文本***运行一遍程序脚本。由于程序脚本被设为显示一行固定的文本字符，所以无论在数据流中输入什么文本都会得到同样的文本输出
	注意：如果要终止次gawk程序，仅需要Ctrl+D组合键在bash中产生一个EOF字符

### 使用数据字段变量
gawk会自动给一行的每个数据元素分配一个变量：
+ $0表示整个文本行
+ $1表示文本行中的第1个字段
+ $n表示文本行中的第n个字段
```shell
$ gawk -F ":" '{print $1}' /etc/passwd
root
daemon
bin
...
```
此例中用"F"选项指定分隔符为":"，然后输出每行文本中的第1个字段，如果要指定其他分隔符也可以用"F"指定

### 在程序脚本中使用多个命令
与sed相似，gawk在命令行上的程序脚本中使用多条命令时，也需要在命令之间用分号隔开。也可以续行输入，就不用分号了
```shell
$ gawk '{
> $4="YourName"
> print $0}'
My name is Rich
My name is YourName

$ echo "My name is Rich" | gawk '{$4="YourName" ; print $0}'
My name is YourName
```
此例中将使用多条命令的两种方式都演示了一下，程序脚本中的第一条命令会给字段变量$4赋值，第二条命令会打印所有字段。使用续行输入时因为没有指定文本文件，所以只能在STDIN输入字符。

### 从文件中读取程序
与sed编辑器一样，gawk允许将程序脚本存储到文件中，然后再在命令行中引用
```shell
$ cat script.gawk	#创建一个新文件
{print $1 "'s home directory is " $6}

$ gawk -F ":" -f script.gawk /etc/passwd
root's home directory is /root
daemon's home directory is /usr/sbin
bin's home directory is /bin
...
```
script.gawk程序脚本会再次使用print命令打印/etc/passwd文件的主目录字段（$6）和userid字段（$1）<br />
```shell
$ cat script.gawk	#修改脚本程序文件
{
test="'s home directory is "
print $1 test $6
}

$ gawk -F ":" -f script.gawk /etc/passwd
```
此例的输出结果与上一示例的结果是一样的，不过此例在脚本程序文件中定义了一个变量test来保存print命令中用到的文本字符串<br />

### 在处理数据前运行脚本
默认情况下，gawk会从输入中读取一行文本，然后针对该行的数据执行程序脚本。有时可能要在处理数据前运行脚本，这就要用到关键字BEGIN，它会强制gawk在读取数据前执行BEGIN关键字后面指定的程序脚本
```shell
$ gawk 'BEGIN {print "Hello world"}'
Hello world
```
值得一提的是，BEGIN后面的程序脚本会直接执行，且执行完后快速退出，不等待任何数据
```shell
$ gawk 'BEGIN {print "The data file contents:"}
> {print $0}' data
The data file contents:
Line 1
Line 2
Line 3
```
此例中演示了BEGIN插入文本中的常用用法，而与BEGIN类似，END关键字允许指定一个程序脚本
```shell
$ gawk 'BEGIN {print "The data file contents:"}
> {print $0}
> END {print "End of file"}' data
The data file contents:
Line 1
Line 2
Line 3
End of file
```
当gawk程序打印完文件内容后，会执行END脚本中的命令。将以上内容放在一起可以组成一个脚本文件：
```shell
$ cat script.gawk	#创建一个新的程序脚本文件
BEGIN {
print "The latest list of users adn shells"
print " UserID \t Shell"
print "------ \t ------"
FS=":"
}

{
print $1 " \t " $7
}

END {
print "This concludes the listing"
}

$ gawk -f script.gawk /etc/passwd
```
执行的结果就不列举出来了，BEGIN创建了标题，END生成了页脚，中间则是程序脚本处理的特定的数据文件
