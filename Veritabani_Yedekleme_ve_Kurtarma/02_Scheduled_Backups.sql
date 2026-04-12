-- SQL Server Agent kullanılarak zamanlanmış görev (Job) oluşturma örneği.
--Bu script'in başarıyla çalışması için SQL Server Agent hizmetinin çalışıyor olması gerekmektedir.


USE msdb;
GO

-- 1. Yeni bir Job oluşturma
EXEC dbo.sp_add_job 
    @job_name = N'Northwind_Daily_Full_Backup',
    @enabled = 1,
    @description = N'Northwind veritabanı için günlük otomatik tam yedekleme görevi.';
GO

-- 2. Job için adım (step) ekleme
EXEC sp_add_jobstep 
    @job_name = N'Northwind_Daily_Full_Backup', 
    @step_name = N'Execute Full Backup', 
    @subsystem = N'TSQL', 
    @command = N'BACKUP DATABASE Northwind TO DISK = ''C:\Backups\Northwind_Daily.bak'' WITH INIT', 
    @retry_attempts = 3, 
    @retry_interval = 5;
GO

-- 3. Zamanlayıcı (Schedule) oluşturma (Örn: Her gece 02:00'da çalışacak şekilde)
EXEC sp_add_schedule 
    @schedule_name = N'Daily_2AM_Schedule', 
    @freq_type = 4,         -- Günlük (Daily)
    @freq_interval = 1,     -- Her gün (Every 1 day)
    @active_start_time = 020000; -- Saat 02:00:00
GO

-- 4. Zamanlayıcıyı az önce oluşturduğumuz Job'a bağlama
EXEC sp_attach_schedule 
    @job_name = N'Northwind_Daily_Full_Backup', 
    @schedule_name = N'Daily_2AM_Schedule';
GO

-- 5. Job'ı belirtilen hedefe (Local Server) bağlama/ekleme
EXEC sp_add_jobserver 
    @job_name = N'Northwind_Daily_Full_Backup';
GO
