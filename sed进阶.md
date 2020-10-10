sed进阶 
=======
基础中提及了大多数日常文本编辑需求，进阶中会有更多高级特性，这些功能不一定常用，但需要时，知道这些功能和如何使用肯定是好事。

### 多行命令
在使用sed编辑器的基础命令时有一个局限，所有的sed编辑器命令都是针对单行数据执行操作的。sed编辑器读取数据流时，会基于换行符的位置将数据分成行。sed编辑器根据定义好的脚本命令一次处理一行数据，然后移到下一行，重复此过程。<br />
如果要对跨多行的数据执行特定操作，普通的sed编辑器命令就无法完成这种操作。为了处理多行数据，sed编辑器包含了三个特殊指令:
指令	|功能
:-:	|:-:
 N	|将数据流中的下一行加进来创建一个多行组 (multiline group) 进行处理
 D	|删除多行组中的一行
 P	|打印多行组中的一行

在后续文章中将会说明这些多行命令的作用。

#### next命令
在了解多行next (N) 指令之前，先看一下单行next (n) 指令是如何工作的，两者对比有助理解。
##### 单行的next命令
n命令会告诉sed编辑器移动到数据流的下一行，而不用重新重头执行一遍脚本命令。这听起来很抽象，看一下示例：
```shell
$ cat data	#创建一个新文件
This is the header line.

This is a data line.

This is the last line.
```
此文件中包含有两行空行，在不使用n指令时，sed编辑器每换一行就会重新执行脚本命令。所以结果应该是两处空行都会被sed脚本命令匹配。
```shell
$ sed '/^$/d' data
This is the header line.
This is a data line.
This is the last line.
```
不出所料，但如果仅想删除一处空行时，就需要用到n指令，先看一下结果：
```shell
$ sed '/header/{n;d}' data
This is the header line.
This is a data line.

This is the last line.
```
由于要删除的是空行，没有任何字符文本可供寻址（当然，你也可以用数字寻址，但这种做法的实用性不如字符寻址强）。解决办法是n指令，在这个示例中，脚本命令中查找含有单词'header'的行。找到之后，n命令会让sed编辑器移动到下一行，也就是空行。此时sed会继续执行命令列表，也就是d指令，删除空白行。<br />
执行完脚本命令后，sed编辑器会继续从数据流中读取下一行，并重新开始执行命令脚本。因为sed编辑器再也找不到包含'header'的行了，所以剩下的空行不会被删除。
##### 合并文本行（多行的next命令）
在学习多行的next (N) 指令之前，有一个很重要的概念：***模式空间***，n指令会将数据流中的下一行移动到sed编辑器的模式空间 (就是工作空间)，而N指令则是直接将下一行文本添加到模式空间中已有的文本之后，也可以将N指令看作为n指令的增强版。
```shell
$ sed '/header/{n ; s/\n/ /}' data
This is the header line.

This is a data line.

This is the last line.
```
此实例中命令脚本的意思是想要将换行符替换为空格，这样输出的文本看起来就像是删除的空行一样，但很明显，n指令只是跳转到空行了，并不能识别到转义字符。再看看N指令:
```shell
$ sed '/header/{N ; s/\n/ /}' data
This is the header line. 
This is a data line.

This is the last line.
```
```diff
- sed编辑器查找含有'header'单词的行，找到该行后会将下一行合并到该行。文本行中仍用换行符分隔，但sed编辑器会将两行当作一行来处理。
```
如果要在数据文件中查找一个可能会分散在两行中的文本短语，N指令会很实用：
```shell
$ cat data	#创建一个新文件
On Tuesday, the Linux System
Administrator's group meeting will be held.
All System Administrators should attend.
Thank you for your attendance.

$ sed 'N
>s/System\nAdministrator/Desktop\nUser/
>s/System Administrator/Desktop User/
>' data
On Tuesday, the Linux Desktop
User's group meeting will be held.
All Desktop Users should attend.
Thank you for your attendance.
```
此示例中使用了两个s指令，分别对应不同的数据流进行替换。还有两个有趣的脚本命令，有兴趣自己实验下，这里不做解释：
```shell
$ sed 'N ; s/System.Administrator/Desktop User/' data

$ sed 'N ; s/System Administrator/Desktop User/' data
```
尽管两个s指令已经能对数据流中大部分行进行匹配了，但仍有个问题。此命令总是在执行sed编辑器命令前将下一行文本读入到模式空间。到最后一行文本时，因为没有下一行可读，所以N指令会叫sed编辑器停止。如果要匹配的文本正好在最后一行上，那命令就不会发现要匹配的数据。
```shell
$ cat data	#创建一个新文件
On Tuesday, the Linux System
Administrator's group meeting will be held.
All System Administrators should attend.

$ sed 'N 
>s/System\nAdministrator/Desktop\nUser/
>s/System Administrator/Desktop User/     
>' data
On Tuesday, the Linux Desktop
User's group meeting will be held.
All System Administrators should attend.
```
可以看到，最后一行的文本内容并没有被替换。因为没有其他行可读到模式空间中与这行合并，所以N指令会错过它。解决这个问题只需要将单行命令放到N命令前面，将多行命令放到N命令后面：
```shell
$ sed '
s/System Administrator/Desktop User/
N
s/System\nAdministrator/Desktop\nUser/
' data
On Tuesday, the Linux Desktop
User's group meeting will be held.
All Desktop Users should attend.
```
小结一下next单行命令和next多行命令的区别：
命令|思路
:-:|:-:
n|匹配到指定文本后跳转到下一行继续sed编辑器上的脚本命令
N|将下一行合并到此行后开始执行sed编辑器上的脚本命令

#### 多行删除命令
```diff
N指令与D指令连用时，sed编辑器执行到D指令，就会删除多行中的第一行。
通常sed编辑器会从脚本头部一直执行到脚本尾部，但执行到D指令时，D指令会强制sed编辑器重新返回到脚本命令头部，而不读取新的行。
```
在sed基础部分学习的删除指令d，在与N指令连用时需要小心：
```shell
$ sed 'N ; d' data
All System Administrators should attend.
```
由于指令N会合并下一行，而指令d会删除一整行，所以看起来就像是删除了两行。还有一点思考：为什么在d指令的前面没有用寻址，但是最后一行却没有被删除。寻址有时候是为了找到特定的行进行操作，但也可以理解为限制只对特定的行进行操作。<br />
sed编辑器提供了多行删除指令D，它只删除模式空间中的第一行：
```shell
$ sed 'N ; /System\nAdministrator/D' data
Administrator's group meeting will be held.
All System Administrators should attend.
```
此例中第二行被N指令合并到了模式空间，但仍然完好。再看一个示例:
```shell
$ cat data	#创建新文件

This is the header line.
This is a data line.

This is the last line.
-----------------------------------
$ sed '/^$/{N ; /header/D}' data
This is the header line.
This is a data line.

This is the last line.
```
sed编辑器脚本命令会查找空白行，然后N指令将下一行文本合并到模式空间。如果下一行文本内容中含有'header'，则D指令会删除模式空间中的第一行。有一个有意思的地方，本人也不是很确定的问题：
```shell
$ sed 'N ; /header/D' data
This is a data line.

This is the last line.
```
此处很好理解，N指令将第二行合并到模式空间，第二行中被匹配到'header'，第一行被删除。然后N指令将第二行与第三行合并到模式空间，还是第二行中被匹配到'header'，所以模式空间中的第一行 (在文本内容中是第二行) 被删除。
```shell
$ sed 'N ; /^$/D' data

This is the header line.
This is a data line.

This is the last line.
```
此例中sed编辑器执行后无任何改变让我很是费解，我的本意是N指令会将空行与第二行合并，然后D指令删除第一个空行，尽管我知道脚本命令这样写得不到我想要的结果，但它毫无反映也让我摸不着头脑。
#### 多行打印命令
多行打印命令P与D指令非常相似，仅打印多行模式空间中的第一行：
```shell
$ sed -n 'N ; /header/P' data

```
匹配到'header'后打印第一行，也就是空行。P指令的强大之处在于与N指令及D指令的组合使用。N指令的独到之处在于强制sed编辑器返回到脚本的起始处，对同一模式空间中的内容重新执行这些命令（它不会从数据流中读取新的文本行）。在命令脚本中加入N指令就能单步扫过整个模式空间，将多行一起匹配。<br />
接下来使用P指令打印出第一行，然后用D命令删除第一行并绕回到脚本的起始处。一旦返回，N命令就会读取下一行文本并重新开始这个过程。这个循环会一直继续下去，直到数据流结束。
### 保持空间
模式空间(pattern space)是一块活跃的缓冲区，sed编辑器执行命令时它会保存待检查的文本。但sed还有另一块缓冲区称作保持空间(hold space)，处理模式空间中的某些行时，可以用保持空间临时保存。关于保持空间，我认为暂时仅做了解即可，有5条操作保持空间的命令：
命令|描述
:-:|:-:
h|将模式空间复制到保持空间
H|将模式空间附加到保持空间
g|将保持空间复制到模式空间
G|将保持空间附加到模式空间
x|交换模式空间与保持空间的内容
由于有两个缓冲区，弄明白文本在哪个缓冲区会比较麻烦，下面示例用h和g命令将数据在两个缓冲区之间移动：
```shell
$ cat data	#创建一个新文件
This is the header line.
This is the first data line.
This is the second data line.
This is the last line.

$ sed -n '/first/{h ; p ; n ; p ; g ; p}' data
This is the first data line.
This is the second data line.
This is the first data line.
```
步骤解析：
1. 寻址找到含有'first'的行，并将其复制到保持空间
2. 打印模式空间的内容，也就是文本内容的第二行
3. n指令跳转到下一行
4. 打印模式空间的内容，也就是文本内容的第三行
5. 将保持空间中含有'first'的行复制到模式空间
6. 打印模式空间的内容
也可以通过保持空间来反向排序输出文本内容，仅需要去掉一个打印指令p：
```shell
$ sed -n '/first/{h ; n ; p ; g ; p}' data
This is the second data line.
This is the first data line.
```
### 排除命令
sed基础篇中演示了如何对整个数据流进行操作，和使用寻址对单个地址或地址区间进行操作。也可以通过感叹号命令'!'用来排除(negate)操作。
```shell
$ sed -n '/header/!p' data
This is the first data line.
This is the second data line.
This is the last line.
```
在合并文本行小节中有提及过，N指令无法处理数据流中的最后一行。这也可以通过排除命令实现：
```shell
$ sed '$!N
> s/System\nAdministrator/Desktop\nUser/
> s/System Administrator/Desktop User/
> ' data
On Tuesday, the Linux Desktop
User's group meeting will be held.
All Desktop Users should attend.
```
我觉得下面对初学者来说是一个难点，但是我也觉得下面的知识点可能没有很大必要掌握。<br />
关于保持空间，前面就提及过了，可以利用保持空间反转数据流中的文本顺序。在思路上：
1. 在模式空间中放置一行（当你使用sed编辑器时，这一点就已经达到了）
2. 将模式空间中的行放到保持空间中(利用保持空间命令)
3. 在模式空间放入下一行（sed编辑器处理完一行后会开始处理下一行）
4. 将保持空间附加到模式空间后
5. 将模式空间中的所有内容放到保持空间
6. 重复3～5步
7. 打印行
实际的命令行与这个思路有一些差异，也还比较好理解，下面是执行命令和结果，请暂时记住此命令：
```shell
$ sed -n '1!G ; h ; $p' data
This is the last line.
This is the second data line.
This is the first data line.
This is the header line.
```
命令行脚本中，首先将保持空间附加到模式空间，然后将模式空间的所有内容又复制到保持空间，打印最后一行，一直循环直到数据流结束。这里有几个点需要提及，这些都是我理解的观点，不代表绝对正确，但我会拿出示例证实我的观点：
```diff
- 1.默认情况下保持空间是有一个空行的，使用复制命令，从模式空间复制到保持空间时，会覆盖掉保持空间下的所有内容，空行也会被覆盖。从保持空间复制到模式空间时就需要注意，保持空间内是否已有内容，如果没有，那么模式空间就会被一个空行覆盖。使用附加命令时更要特别注意保持空间的空行，因为附加命令不会覆盖任何内容，也就意味着这个空行会一直存在。

- 2.保持空间可以保存数据内容，但sed编辑器的脚本命令不会对保持空间内的内容进行打印。任何时候都应该是打印模式空间内的内容。

- 3.这一点是我不确定的一点，保持空间内的所有内容，在同一个时间点，会被sed编辑器认做同一行内容。而且在数据流结束之前，sed脚本命令操作后产生的所有内容都同属于一个文本内容。
```
那么，首先解析一下上面的脚本示例吧，下面是sed命令执行流程：
```diff
	模式空间					保持空间		解析	
	header		<--1!G--	[ 空行 ]		通过寻址和排除命令取消附加命令

	header		---h--->	header		将模式空间复制到保持空间

	$p header							输出模式空间 header

	first		<---G---	header		将保持空间附加到模式空间后面

	first		---h--->	first		将模式空间复制到保持空间
	header					header

	$p first							输出模式空间 first
	   header									   header

	下面的流程依此类推....
```
首先，'1!G'指令和'h'指令的执行流程很好理解，最主要的是'$p'指令。从前面学习的正则表达式可以得知'$'表示最后一行，'$p'则表示输出最后一行。在此示例中，我的理解是'$p'表示输出模式空间的最后一行。<br />
那么，根据我理解的sed命令执行流程来看，'p'的每一次输出如下：
第一次|第二次|第三次|第四次
:-:|:-:|:-:|:-:
header|first|second|last
	  |header|first|second
	  |		 |header|first
	  |		 |		|header
首先证明我的观点3,现将sed命令的'$p'更改为'p'：
```shell
$ sed -n '1!G ; h ; p' data
This is the header line.
This is the first data line.
This is the header line.
This is the second data line.
This is the first data line.
This is the header line.
This is the last line.
This is the second data line.
This is the first data line.
This is the header line.
```
可以看到这个结果是符合我理解的sed命令执行流程的结果的，'$p'看起来输出了最后'4'行，而实际上'$p'仅表示输出文本内容的最后一行，所以我认为在一个时间点内，保持空间内的所有内容被sed编辑器认做同一行，包括换行符。<br />
接着证明我的观点1和2,看下面两个示例：
```shell
$ sed -n '/first/{h ; n ; p }' data
This is the second data line.

$ sed -n '/first/{H ; n ; p ; g ; p}' data
This is the second data line.

This is the first data line.
```
第一个示例中将含有'first'的行从模式空间复制到保持空间后，模式空间立马跳转到'second'行，而保持空间内应该仍然还是'first'行，由此可见sed编辑器仅打印模式空间的内容。<br />
再看第二个示例，将h指令更改为H，直接将模式空间附加到保持空间。先输出模式空间，然后将保持空间的内容复制到模式空间进行输出，可以看到中间有一个空白行。
```diff
# tac命令可以直接倒序显示一个文本文件
```

### 改变流
改变流有一点类似if判断语句，匹配条件时跳转执行指定的脚本命令