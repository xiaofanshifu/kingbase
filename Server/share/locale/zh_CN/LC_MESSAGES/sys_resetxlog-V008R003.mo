��    l      |  �   �      0	     1	  9   K	  1   �	  :   �	  -   �	  4    
  9   U
  O   �
  1   �
  +     O   =  ;   �  I   �        +   4  "   `  )   �     �  >   �  !     ,   *  +   W  '   �  6   �  *   �  #     <   1  &   n  -   �  !   �  1   �  ?     &   W  !   ~  =   �  "   �  )        +  S   @  #   �  \   �  +     0   A      r  2   �  A   �  E     4   N  G   �  &   �  -   �        )   0  )   Z  )   �     �  )   �  )   �  )      )   J  )   t  )   �  )   �     �  V     )   g  )   �  )   �  ,   �  )     )   <  )   f  )   �  )   �  )   �  )     )   8  )   b  )   �  )   �  )   �  )   
  )   4  )   ^  )   �  )   �  )   �  )     )   0  )   Z  )   �  	   �  )   �  �   �     �  &   �  !   �  )   �  +        9     F     O  )   f     �  )   �     �  *   �  �  �     �  0   �  2   �  >     5   X  H   �  5   �  G     B   U      �  P   �  ?   
   F   J   '   �   ,   �       �   "   !     *!  8   D!     }!  #   �!  #   �!      �!  /    "  (   0"      Y"  5   z"      �"  -   �"      �"  3    #  8   T#      �#      �#  4   �#     $  %   "$     H$  E   ^$     �$  z   �$  #   >%  &   b%     �%  ,   �%  N   �%  E   #&  .   i&  1   �&     �&  $   �&     '  1   '  0   M'  +   ~'     �'  $   �'  /   �'  1   (  1   N(  *   �(  9   �(  9   �(     )  U   <)  0   �)  /   �)  /   �)  *   #*  /   N*  '   ~*  '   �*  +   �*  '   �*  4   "+  '   W+  2   +  ,   �+  8   �+  .   ,  1   G,  7   y,  -   �,  3   �,  (   -  *   <-  )   g-  %   �-  0   �-  )   �-  )   .     <.  '   E.  �   m.     �.  *   /  -   1/  )   _/  -   �/  	   �/     �/  	   �/  !   �/     �/  !   �/     0  ,   $0     7           N      (   X   ?       I   ^       L   ,              0      "   >   W   a   9      S   5         f   R       M                  _         +          O       [      C       V       i         !   b   =   Q   	   K          2       `   \             j   Y       c      U       e              h            G   '           #       
       D   .       4   -   k   F   P   T   6   ]   l           3   E   Z       8       %      g          H      *                 B                  @   $       &       <   ;               A   d   /   J       1   :   )       

Values to be changed:

 
If these values seem acceptable, use -f to force reset.
 
Report bugs to <kingbase-bugs@kingbase.com.cn>.
                    (zero in either value means no change)
   -?, --help       show this help, then exit
   -O OFFSET        set next multitransaction offset
   -V, --version    output version information, then exit
   -c XID,XID       set oldest and newest transactions bearing commit timestamp
   -e XIDEPOCH      set next transaction ID epoch
   -f               force update to be done
   -l XLOGFILE      force minimum WAL starting location for new transaction log
   -m MXID,MXID     set next and oldest multitransaction ID
   -n               no update, just show what would be done (for testing)
   -o OID           set next OID
   -x XID           set next transaction ID
  [-D] DATADIR      data directory
 %s resets the Kingbase transaction log.

 %s: OID (-o) must not be 0
 %s: WARNING: cannot create restricted tokens on this platform
 %s: cannot be executed by "root"
 %s: could not allocate SIDs: error code %lu
 %s: could not change directory to "%s": %s
 %s: could not close directory "%s": %s
 %s: could not create restricted token: error code %lu
 %s: could not create sys_control file: %s
 %s: could not delete file "%s": %s
 %s: could not get exit code from subprocess: error code %lu
 %s: could not open directory "%s": %s
 %s: could not open file "%s" for reading: %s
 %s: could not open file "%s": %s
 %s: could not open process token: error code %lu
 %s: could not re-execute with restricted token: error code %lu
 %s: could not read directory "%s": %s
 %s: could not read file "%s": %s
 %s: could not start process for command "%s": error code %lu
 %s: could not write file "%s": %s
 %s: could not write sys_control file: %s
 %s: fsync error: %s
 %s: internal error -- sizeof(ControlFileData) is too large ... fix PG_CONTROL_SIZE
 %s: invalid argument for option %s
 %s: lock file "%s" exists
Is a server running?  If not, delete the lock file and try again.
 %s: multitransaction ID (-m) must not be 0
 %s: multitransaction offset (-O) must not be -1
 %s: no data directory specified
 %s: oldest multitransaction ID (-m) must not be 0
 %s: sys_control exists but has invalid CRC; proceed with caution
 %s: sys_control exists but is broken or unknown version; ignoring it
 %s: too many command-line arguments (first is "%s")
 %s: transaction ID (-c) must be either 0 or greater than or equal to 2
 %s: transaction ID (-x) must not be 0
 %s: transaction ID epoch (-e) must not be -1
 64-bit integers Blocks per segment of large relation: %u
 Bytes per WAL segment:                %u
 Catalog version number:               %u
 Current sys_control values:

 Data page checksum version:           %u
 Database block size:                  %u
 Database system identifier:           %s
 Date/time type storage:               %s
 First log segment after reset:        %s
 Float4 argument passing:              %s
 Float8 argument passing:              %s
 Guessed sys_control values:

 If you are sure the data directory path is correct, execute
  touch %s
and try again.
 Latest checkpoint's NextMultiOffset:  %u
 Latest checkpoint's NextMultiXactId:  %u
 Latest checkpoint's NextOID:          %u
 Latest checkpoint's NextXID:          %u:%u
 Latest checkpoint's TimeLineID:       %u
 Latest checkpoint's full_page_writes: %s
 Latest checkpoint's newestCommitTsXid:%u
 Latest checkpoint's oldestActiveXID:  %u
 Latest checkpoint's oldestCommitTsXid:%u
 Latest checkpoint's oldestMulti's DB: %u
 Latest checkpoint's oldestMultiXid:   %u
 Latest checkpoint's oldestXID's DB:   %u
 Latest checkpoint's oldestXID:        %u
 Maximum columns in an index:          %u
 Maximum data alignment:               %u
 Maximum length of identifiers:        %u
 Maximum size of a TOAST chunk:        %u
 NextMultiOffset:                      %u
 NextMultiXactId:                      %u
 NextOID:                              %u
 NextXID epoch:                        %u
 NextXID:                              %u
 OldestMulti's DB:                     %u
 OldestMultiXid:                       %u
 OldestXID's DB:                       %u
 OldestXID:                            %u
 Options:
 Size of a large-object chunk:         %u
 The database server was not shut down cleanly.
Resetting the transaction log might cause data to be lost.
If you want to proceed anyway, use -f to force reset.
 Transaction log reset
 Try "%s --help" for more information.
 Usage:
  %s [OPTION]... DATADIR

 WAL block size:                       %u
 You must run %s as the Kingbase superuser.
 by reference by value floating-point numbers newestCommitTsXid:                    %u
 off oldestCommitTsXid:                    %u
 on sys_control version number:            %u
 Project-Id-Version: sys_resetxlog (Kingbase V008R003C002B0290)
Report-Msgid-Bugs-To: kingbase-bugs@kingbase.com.cn
POT-Creation-Date: 2016-04-18 04:44+0000
PO-Revision-Date: 2016-05-19 20:41+0800
Last-Translator: Yuwei Peng <ywpeng@whu.edu.cn>
Language-Team: Chinese (Simplified) <ywpeng@whu.edu.cn>
Language: zh_CN
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: 8bit
X-Generator: Poedit 1.5.7
 

将被改变的值:

 
如果这些值可接受, 用 -f 强制重置.
 
报告错误至 <kingbase-bugs@kingbase.com.cn>.
                    （任一值中的零表示没有改变）
   -?, --help       显示帮助信息，然后退出
   -O OFFSET        设置下一个多事务（multitransaction）偏移
   -V, --version    输出版本信息，然后退出
   -c XID,XID       设置承受提交时间戳的最旧和最新事务
   -e XIDEPOCH      设置下一个事务ID时间单元（epoch）
   -f               强制更新
   -l XLOGFILE      为新的事务日志强制使用最小WAL日志起始位置
   -m MXID,MXID    　设置下一个事务和最老的事务ID
   -n               未更新, 只显示将要做什么 (测试用途)
   -o OID           设置下一个 OID
   -x XID           设置下一个事务 ID
  [-D] DATADIR      数据目录
 %s 重置 Kingbase 事务日志.

 %s: OID (-o) 不能为 0
 %s: WARNING: 无法为该平台创建受限制的令牌
 %s:不能由"root"执行
 %s: 无法分配SID: 错误码 %lu
 %s: 无法切换目录至 "%s": %s
 %s: 无法关闭目录 "%s": %s
 %s: 无法创建受限令牌: 错误码为 %lu
 %s: 无法创建 sys_control 文件: %s
 %s: 无法删除文件 "%s": %s
 %s: 无法从子进程得到退出码: 错误码 %lu
 %s: 无法打开目录 "%s": %s
 %s: 无法打开文件 "%s" 读取信息: %s
 %s: 无法打开文件 "%s": %s
 %s:无法打开进程令牌 (token): 错误码 %lu
 %s: 无法使用受限令牌再次执行: 错误码 %lu
 %s: 无法读取目录 "%s": %s
 %s: 无法读取文件 "%s": %s
 %s: 无法为命令 "%s"创建进程: 错误码 %lu
 %s: 无法写文件 "%s": %s
 %s: 无法写 sys_control 文件: %s
 %s: fsync 错误: %s
 %s: 内部错误 -- sizeof(ControlFileData) 太大 ... 修复 xlog.c
 %s:：选项%s的参数无效
 %s: 锁文件 "%s" 已经存在
是否有一个服务正在运行? 如果没有, 删除那个锁文件然后再试一次.
 %s:  多事务 ID (-m) 不能为 0
 %s: 多事务 偏移 (-O) 不能为-1
 %s: 没有指定数据目录
 %s:  最老的多事务 ID (-m) 不能为 0
 %s: sys_control 已经存在, 但有无效的CRC; 带有警告的继续运行
 %s: sys_control 已经存在, 但已破坏或无效版本; 忽略它
 %s: 命令行参数太多 (第一个是 "%s")
 %s：事务ID (-c) 必须是0或者大于等于2
 %s: 事务 ID (-x) 不能为 0
 %s: 事务ID epoch(-e) 不能为 -1
 64位整型 大关系的每段块数:                     %u
 每一个 WAL 段字节数:                  %u
 Catalog 版本:                         %u
 当前的 sys_control 值:

 数据页检验和版本:        %u
 数据库块大小:                         %u
 数据库系统标识符:                     %s
 日期/时间类型存储:                    %s
 重置后的第一个日志段:        %s
 正在传递Float4类型的参数:                    %s
 正在传递Float8类型的参数:                    %s
 猜测的 sys_control 值:

 如果你确定数据目录路径是正确的, 运行
  touch %s
然后再试一次.
 最新检查点的 NextMultiOffset:          %u
 最新检查点的 NextMultiXactId:         %u
 最新检查点的 NextOID:                 %u
 最新检查点的NextXID:          %u:%u
 最新检查点的 TimeLineID:              %u
 最新检查点的full_page_writes: %s
 最新检查点的newestCommitTsXid:%u
 最新检查点的oldestActiveXID:      %u
 最新检查点的oldestCommitTsXid:%u
 最新检查点的oldestMulti所在的数据库: %u
 最新检查点的oldestMultiXid:   %u
 最新检查点的oldestXID所在的数据库: %u
 最新检查点的oldestXID:             %u
 在索引中最多可用的列数:                   %u
 最大的数据校准:                     %u
 标示符的最大长度:                     %u
 一个TOAST区块的最大空间:                   %u
 下一个偏移NextMultiOffset:           %u
 下一个MultiXactId值NextMultiXactId:         %u
 NextOID:                             %u
 NextXID 末端:                        %u
 NextXID:                              %u
 最老的MultiXid对应的DB:     %u
 最老的MultiXid值OldestMultiXid:          %u
 OldestXID's DB:                       %u
 OldestXID:                            %u
 选项:
 一个大对象区块的大小:     %u
 数据库服务器没有彻底关闭.
重置事务日志有可能会引起丢失数据.
如果你仍想继续, 用 -f 强制重置.
 事务日志重置
 输入 "%s --help" 获取更多的信息.
 使用方法:
  %s [选项]... 数据目录

 WAL块大小:                         %u
 您现在作为Kingbase超级用户运行%s.
 由引用 由值 浮点数 newestCommitTsXid：          %u
 关闭 oldestCommitTsXid：          %u
 开启 sys_control 版本:                      %u
 