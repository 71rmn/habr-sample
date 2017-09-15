SET NOCOUNT ON;
declare tmp table(session_id smallint primary key,login_time datetime,host_name nvarchar(256),program_name nvarchar(256),login_name nvarchar(256),nt_user_name nvarchar(256),cpu_time int,memory_usage int,reads bigint,writes bigint,logical_reads bigint,database_id smallint)

declare @d datetime;
select @d=GETDATE()

INSERT INTO tmp(session_id,login_time,host_name,program_name,login_name,nt_user_name,cpu_time,memory_usage,reads,writes,logical_reads,database_id)
SELECT session_id,login_time,host_name,program_name,login_name,nt_user_name,cpu_time,memory_usage,reads,writes,logical_reads,database_id
from sys.dm_exec_sessions s;

WAITFOR DELAY '00:00:01';

declare @dd float;
select @dd=datediff(ms,@d,getdate());

SELECT
	s.session_id, s.host_name, db_name(s.database_id) as db, s.login_name,s.login_time,s.program_name,
	s.cpu_time-isnull(t.cpu_time,0) as cpu_Diff,
	s.reads+s.writes-isnull(t.reads,0)-isnull(t.writes,0) as totIO_Diff,
	s.reads-isnull(t.reads,0) as reads_Diff,
	s.writes-isnull(t.writes,0) as writes_Diff,
	s.logical_reads-isnull(t.logical_reads,0) as logical_reads_Diff,
	s.memory_usage, s.memory_usage-isnull(t.memory_usage,0) as [mem_Diff],
	s.nt_user_name,s.nt_domain
from sys.dm_exec_sessions s
left join tmp t on s.session_id=t.session_id
