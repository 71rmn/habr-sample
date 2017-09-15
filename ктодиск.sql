if object_id('tempdb..#tmp') is NULL BEGIN
	SELECT * into #tmp from sys.dm_exec_sessions s
	PRINT 'ждем секунду для накопления сатистики при первом запуске'
	-- при последующих запусках не ждем, т.к. сравниваем с результатом предыдущего запуска
	WAITFOR DELAY '00:00:01';
END
if object_id('tempdb..#tmp1') is not null drop table #tmp1

declare @d datetime
declare @dd float
select @d = crdate from tempdb.dbo.sysobjects where id=object_id('tempdb..#tmp')

select * into #tmp1 from sys.dm_exec_sessions s
select @dd=datediff(ms,@d,getdate())
--select @dd AS [интервал времени, мс]

SELECT TOP 30 s.session_id, s.host_name, db_name(s.database_id) as db, s.login_name,s.login_time,s.program_name,
	s.cpu_time-isnull(t.cpu_time,0) as cpu_Diff, convert(numeric(16,2),(s.cpu_time-isnull(t.cpu_time,0))/@dd*1000) as cpu_sec,
	s.reads+s.writes-isnull(t.reads,0)-isnull(t.writes,0) as totIO_Diff, convert(numeric(16,2),(s.reads+s.writes-isnull(t.reads,0)-isnull(t.writes,0))/@dd*1000) as totIO_sec,
	s.reads-isnull(t.reads,0) as reads_Diff, convert(numeric(16,2),(s.reads-isnull(t.reads,0))/@dd*1000) as reads_sec,
	s.writes-isnull(t.writes,0) as writes_Diff, convert(numeric(16,2),(s.writes-isnull(t.writes,0))/@dd*1000) as writes_sec,
	s.logical_reads-isnull(t.logical_reads,0) as logical_reads_Diff, convert(numeric(16,2),(s.logical_reads-isnull(t.logical_reads,0))/@dd*1000) as logical_reads_sec,
	s.memory_usage, s.memory_usage-isnull(t.memory_usage,0) as [mem_D],
	s.nt_user_name,s.nt_domain
from #tmp1 s
LEFT join #tmp t on s.session_id=t.session_id
order BY
--cpu_Diff desc
totIO_Diff desc
--logical_reads_Diff desc

drop table #tmp
GO
select * into #tmp from #tmp1
drop table #tmp1
