��    P      �  k         �  X   �  
   "     -  +   F  7   r      �  A   �        4   .     c  ,   s  ,   �  )   �  )   �  )   !	  )   K	  )   u	  )   �	  )   �	  )   �	  )   
  ,   G
  )   t
  )   �
  ,   �
  )   �
  )     )   I  ,   s  )   �  )   �  ,   �  )   !  )   K  )   u  )   �  )   �  )   �  )     )   G  )   q  )   �  )   �  )   �  )     )   C  ,   m  ,   �  0   �  )   �  )   "  &   L     s  )   {     �     �     �     �     �     �  )     )   0  )   Z  )   �     �     �     �  	   �     �     �     �  *   �  *     )   H     r     �  )   �  )   �     �  �  �  I   �  	   �       3     1   M       .   �     �  .   �       .   &  <   U  1   �  0   �  +   �     !  /   @  /   p  1   �  1   �  '     8   ,  1   e  9   �  3   �  '     &   -  /   T  *   �  %   �  )   �  4   �  /   4  '   d  '   �  '   �  '   �  5     &   :  3   a  +   �  2   �     �  1     .   B  &   q      �  3   �  1   �  %     1   E  '   w     �     �  	   �     �  	   �     �     �            !   -  !   O  #   q     �     �     �     �  !   �     �     �  .   �  ,     (   F     o  !   �  )   �  !   �     �     3                     M   C   !   	   +   :       P      8          "   K   N   /   7       0   =   1      O              -           9      <      H      D   5   J   F   ,   .       G         B               L   ;   E   2   ?   $            
       A   %      *               (                               '          I                  6             4           #          >       @   &   )    
If no data directory (DATADIR) is specified, the environment variable PGDATA
is used.

 
Options:
   %s [OPTION] [DATADIR]
   -?, --help     show this help, then exit
   -V, --version  output version information, then exit
  [-D] DATADIR    data directory
 %s displays control information of a Kingbase database cluster.

 %s: no data directory specified
 %s: too many command-line arguments (first is "%s")
 64-bit integers Backup end location:                  %X/%X
 Backup start location:                %X/%X
 Blocks per segment of large relation: %u
 Bytes per WAL segment:                %u
 Catalog version number:               %u
 Data page checksum version:           %u
 Database block size:                  %u
 Database cluster state:               %s
 Database system identifier:           %s
 Date/time type storage:               %s
 End-of-backup record required:        %s
 Fake LSN counter for unlogged rels:   %X/%X
 Float4 argument passing:              %s
 Float8 argument passing:              %s
 Latest checkpoint location:           %X/%X
 Latest checkpoint's NextMultiOffset:  %u
 Latest checkpoint's NextMultiXactId:  %u
 Latest checkpoint's NextOID:          %u
 Latest checkpoint's NextXID:          %u:%u
 Latest checkpoint's PrevTimeLineID:   %u
 Latest checkpoint's REDO WAL file:    %s
 Latest checkpoint's REDO location:    %X/%X
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
 Min recovery ending loc's timeline:   %u
 Minimum recovery ending location:     %X/%X
 Prior checkpoint location:            %X/%X
 Report bugs to <kingbase-bugs@kingbase.com.cn>.
 Size of a large-object chunk:         %u
 Time of latest checkpoint:            %s
 Try "%s --help" for more information.
 Usage:
 WAL block size:                       %u
 by reference by value floating-point numbers in archive recovery in crash recovery in production max_connections setting:              %d
 max_locks_per_xact setting:           %d
 max_prepared_xacts setting:           %d
 max_worker_processes setting:         %d
 no off on shut down shut down in recovery shutting down starting up sys_control last modified:             %s
 sys_control version number:            %u
 track_commit_timestamp setting:       %s
 unrecognized status code unrecognized wal_level wal_level setting:                    %s
 wal_log_hints setting:                %s
 yes Project-Id-Version: sys_controldata (Kingbase V008R003C002B0290)
Report-Msgid-Bugs-To: kingbase-bugs@kingbase.com.cn
POT-Creation-Date: 2016-04-18 04:45+0000
PO-Revision-Date: 2016-05-19 20:40+0800
Last-Translator: Yuwei Peng <ywpeng@whu.edu.cn>
Language-Team: Chinese (Simplified) <ywpeng@whu.edu.cn>
Language: zh_CN
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: 8bit
X-Generator: Poedit 1.5.7
 
如果没有指定数据目录(DATADIR), 将使用
环境变量PGDATA.

 
选项:
   %s [选项][DATADIR]
   -?, --help     显示帮助信息，然后退出
  -V, --version 输出版本信息，然后退出
  [-D] DATADIR    数据目录
 %s 显示 Kingbase 数据库簇控制信息.

 %s: 没有指定数据目录
 %s: 命令行参数太多 (第一个是 "%s")
 64位整数 备份的最终位置:                  %X/%X
 开始进行备份的点位置:                       %X/%X
 大关系的每段块数:                     %u
 每一个 WAL 段字节数:                  %u
 Catalog 版本:                         %u
 数据页校验和版本:  %u
 数据库块大小:                         %u
 数据库簇状态:                         %s
 数据库系统标识符:                     %s
 日期/时间 类型存储:                   %s
 需要终止备份的记录:        %s
 不带日志的关系: %X/%X使用虚假的LSN计数器
 正在传递Flloat4类型的参数:           %s
 正在传递Flloat8类型的参数:                   %s
 最新检查点位置:                       %X/%X
 最新检查点的NextMultiOffsetD: %u
 最新检查点的NextMultiXactId: %u
 最新检查点的 NextOID:                 %u
 最新检查点的NextXID:          %u:%u
 最新检查点的PrevTimeLineID: %u
 最新检查点的重做日志文件: %s
 最新检查点的 REDO 位置:               %X/%X
 最新检查点的 TimeLineID:              %u
 最新检查点的full_page_writes: %s
 最新检查点的newestCommitTsXid:%u
 最新检查点的oldestActiveXID:  %u
 最新检查点的oldestCommitTsXid:%u
 最新检查点的oldestMulti所在的数据库：%u
 最新检查点的oldestMultiXid:  %u
 最新检查点的oldestXID所在的数据库：%u
 最新检查点的oldestXID:            %u
 在索引中可允许使用最大的列数:    %u
 最大数据校准:     %u
 标识符的最大长度:                     %u
 TOAST区块的最大长度:                %u
 最小恢复结束位置时间表: %u
 最小恢复结束位置: %X/%X
 优先检查点位置:                       %X/%X
 报告错误至 <kingbase-bugs@kingbase.com.cn>.
 大对象区块的大小:         %u
 最新检查点的时间:                     %s
 用 "%s --help" 显示更多的信息.
 使用方法:
 WAL的块大小:    %u
 由引用 由值 浮点数 正在归档恢复 在恢复中 在运行中 max_connections设置：   %d
 max_locks_per_xact设置：   %d
 max_prepared_xacts设置：   %d
 max_worker_processes设置：   %d
 否 关闭 开启 关闭 在恢复过程中关闭数据库 正在关闭 正在启动 sys_control 最后修改:                  %s
 sys_control 版本:                      %u
 track_commit_timestamp设置:        %s
 不被认可的状态码 参数wal_level的值无法识别 wal_level设置：                    %s
 wal_log_hints设置：        %s
 是 