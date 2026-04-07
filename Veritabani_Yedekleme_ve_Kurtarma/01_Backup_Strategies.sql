-- 1. Tam Yedekleme (Full Backup)
-- Veritabanının tamamının bir yedeğini oluşturur.
BACKUP DATABASE Northwind 
TO DISK = 'C:\Backups\Northwind_Full.bak'
WITH FORMAT, 
MEDIANAME = 'NorthwindBackups', 
NAME = 'Full Backup of Northwind';
GO

-- 2. Fark Yedeklemesi (Differential Backup)
-- Son Tam Yedeklemeden (Full Backup) bu yana değişen tüm verileri yedekler.
-- Tam yedeğe göre boyutu daha küçüktür ve işlemi daha hızlıdır.
BACKUP DATABASE Northwind 
TO DISK = 'C:\Backups\Northwind_Diff.bak'
WITH DIFFERENTIAL,
NAME = 'Differential Backup of Northwind';
GO

-- 3. İşlem Günlüğü Yedeklemesi (Transaction Log Backup / Artık Yedekleme)
-- Belirli bir zamana (Point-in-Time) dönüş yapabilmek için son log yedeğinden itibaren yapılan işlemleri yedekler.
-- SADECE veritabanı tam kurtarma modelindeyse (Full Recovery Model) çalışır.

-- Önce veritabanının kurtarma modelini Full yapalım (Eğer değilse)
ALTER DATABASE Northwind SET RECOVERY FULL;
GO

-- İşlem Günlüğü yedeğini almak:
BACKUP LOG Northwind 
TO DISK = 'C:\Backups\Northwind_Log.trn'
WITH NAME = 'Transaction Log Backup of Northwind';
GO
