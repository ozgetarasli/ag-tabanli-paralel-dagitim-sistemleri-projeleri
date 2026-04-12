-- FELAKETTEN KURTARMA SENARYOSU: Kaza ile Silinen Verilerin Geri Getirilmesi 
USE Northwind;
GO

-- 1. HAZIRLIK: Senaryo için test verisi içeren bir tablo oluşturuyoruz
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Table_RecoveryTest')
BEGIN
    CREATE TABLE Table_RecoveryTest (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Data NVARCHAR(100),
        CreatedAt DATETIME DEFAULT GETDATE()
    );
END
GO

-- Test verilerini ekleyelim
INSERT INTO Table_RecoveryTest (Data) 
VALUES 
('Onemli Musteri Verisi 1'),
('Onemli Siparis Verisi 2');
GO

-- 2. RUTIN YEDEK: Veriler eklendikten sonra (kazadan önceki bir zaman diliminde) tam bir yedek alıyoruz
BACKUP DATABASE Northwind 
TO DISK = 'C:\SQLBackups\Northwind_Full.bak' 
WITH INIT, NAME = 'Full Backup Before Disaster';
GO

-- (Zamanın geçmesini simüle etmek için biraz bekliyoruz)
WAITFOR DELAY '00:00:02';
GO



WAITFOR DELAY '00:00:02';
GO

-- 3. KAZA ANI: Bir veri yanlışlıkla silinir 
DELETE FROM Table_RecoveryTest
WHERE Data = 'Onemli Musteri Verisi 1';
GO

-- 4. KURTARMA SÜRECİ (Disaster Recovery Process)

-- a. Kuyruk Log Yedeği (Tail-Log Backup)
-- Mevcut logları kaybetmemek için NORECOVERY ile yedek alıyoruz.
USE master;
GO
BACKUP LOG Northwind 
TO DISK = 'C:\SQLBackups\Northwind_Tail_Log.trn' 
WITH NORECOVERY, INIT;
GO

-- b. Tam Yedeği (Full Backup) NORECOVERY modunda geri yüklüyoruz.
RESTORE DATABASE Northwind 
FROM DISK = 'C:\SQLBackups\Northwind_Full.bak' 
WITH NORECOVERY, REPLACE;
GO

-- c. Log yedeğini belirli bir zamana (STOPAT) kadar geri yükleyerek veriyi kurtarıyoruz.

RESTORE LOG Northwind 
FROM DISK = 'C:\SQLBackups\Northwind_Tail_Log.trn' 
WITH STOPAT = '2026-04-09 20:53:17', 
RECOVERY;
GO

-- 5. TEST: Verinin geri gelip gelmediğini kontrol edelim
USE Northwind;
SELECT * FROM Table_RecoveryTest;
GO
