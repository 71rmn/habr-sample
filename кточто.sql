DECLARE @sql_handle varbinary(64)
DECLARE @plan_handle varbinary(64)
DECLARE @sid INT
Declare @statement_start_offset int, @statement_end_offset INT
, @connection_id UNIQUEIDENTIFIER
, @session_id SMALLINT

-- для инфы по конкретному юзеру
--SELECT @sid=182

-- получаем переменные состояния для дальнейшей обработки
IF @sid IS NOT NULL
	SELECT @sql_handle=der.sql_handle, @plan_handle=der.plan_handle, @statement_start_offset=der.statement_start_offset, @statement_end_offset=der.statement_end_offset
	,@connection_id = der.connection_id, @session_id = der.session_id
	FROM sys.dm_exec_requests der WHERE der.session_id=@sid

-- получаем список всех текущих запросов
SELECT LEFT((SELECT [text] FROM sys.dm_exec_sql_text(der.sql_handle)),150) AS txt
--,(select top 1 1 from sys.dm_exec_query_profiles where session_id=der.session_id) as HasLiveStat
,der.blocking_session_id as blocker, DB_NAME(der.database_id) AS База, s.login_name, *
from sys.dm_exec_requests der
left join sys.dm_exec_sessions s ON s.session_id = der.session_id
WHERE der.session_id<>@@SPID AND der.session_id>50

--SELECT * FROM sys.dm_exec_connections WHERE connection_id = @connection_id
--SELECT * FROM sys.dm_exec_connections WHERE session_id=@session_id

--печатаем текст выполняемого запроса
DECLARE @txt VARCHAR(max)
IF @sql_handle IS NOT NULL
SELECT @txt=[text] FROM sys.dm_exec_sql_text(@sql_handle)
PRINT @txt
-- выводим план выполняемого батча/процы
IF @plan_handle IS NOT NULL
select * from sys.dm_exec_query_plan(@plan_handle)
-- и план выполняемого запроса в рамках батча/процы
IF @plan_handle IS NOT NULL
SELECT dbid, objectid, number, encrypted, CAST(query_plan AS XML) AS planxml
from sys.dm_exec_text_query_plan(@plan_handle, @statement_start_offset, @statement_end_offset)
-- статистика по плану
IF @sql_handle IS NOT NULL
SELECT * FROM sys.dm_exec_query_stats QS WHERE QS.sql_handle=@sql_handle

-- блокировки
--if @session_id is not null begin
--	select * from sys.dm_tran_locks l where l.request_session_id=@session_id
--	--select * from sys.dm_tran_locks l where l.request_session_id=@session_id and request_mode like '%X%'
--end

/* -- поиск плана запроса
SELECT * FROM sys.dm_exec_query_stats deqs
CROSS APPLY sys.dm_exec_sql_text(deqs.sql_handle) t
WHERE t.[text] LIKE '%powertypecode=26%'
-- текст запроса по хэндлу
DECLARE @txt VARCHAR(max)
SELECT @txt=[text] FROM sys.dm_exec_sql_text(0x020000005D591432984FD071E7E26B7531BD190E511ACB43)
PRINT @txt
-- план запроса по хэндлу
select * from sys.dm_exec_query_plan(0x060027000621490AB8C16410000000000000000000000000)
-- статистика по хэндлу плана
SELECT * FROM sys.dm_exec_query_stats QS WHERE QS.sql_handle=0x02000000F4F196284111F9B7112D1F12C08806E8751EA4D5
*/
/* сессии по времени последнего запроса
select * from sys.dm_exec_sessions s where s.session_id>50 order by s.last_request_start_time desc
*/