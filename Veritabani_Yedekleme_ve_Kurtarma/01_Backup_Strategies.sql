-- 1. Tam Yedekleme (Full Backup)
BACKUP DATABASE Northwind 
TO DISK = 'C:\Backups\Northwind_Full.bak'
WITH FORMAT, 
MEDIANAME = 'NorthwindBackups', 
NAME = 'Full Backup of Northwind';
GO

-- 2. Fark Yedeklemesi (Differential Backup)

BACKUP DATABASE Northwind 
TO DISK = 'C:\Backups\Northwind_Diff.bak'
WITH DIFFERENTIAL,
NAME = 'Differential Backup of Northwind';
GO

-- 3. İşlem Günlüğü Yedeklemesi (Transaction Log Backup / Artık Yedekleme)

-- Önce veritabanının kurtarma modelini Full yapalım 
ALTER DATABASE Northwind SET RECOVERY FULL;
GO

-- İşlem Günlüğü yedeğini almak:
BACKUP LOG Northwind 
TO DISK = 'C:\Backups\Northwind_Log.trn'
WITH NAME = 'Transaction Log Backup of Northwind';
GO
