-- FELAKETTEN KURTARMA SENARYOSU: Kaza ile Silinen Verilerin Geri Getirilmesi (Point-in-Time Restore)

USE Northwind;
GO

-- 1. HAZIRLIK: Senaryo için test verisi içeren bir tablo oluşturalım
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Table_RecoveryTest')
BEGIN
    CREATE TABLE Table_RecoveryTest (
        ID INT IDENTITY(1,1), 
        Data NVARCHAR(50), 
        InsertTime DATETIME DEFAULT GETDATE()
    );
END
GO
-- Test verilerini ekleyelim
INSERT INTO Table_RecoveryTest (Data) VALUES ('Onemli Müsteri Verisi 1'), ('Onemli Siparis Verisi 2');
GO

-- 2. RUTIN YEDEK: Veriler eklendikten sonra (kazadan önceki bir zaman diliminde) tam bir yedek alalım
BACKUP DATABASE Northwind TO DISK = 'C:\Backups\Northwind_Base_Recovery.bak' WITH INIT;
GO

-- (Zamanın geçmesini simüle etmek için biraz bekliyoruz)
WAITFOR DELAY '00:00:02';
GO

-- ZAMAN KAYDI (MÜDAHALE NOKTASI): Verilerin silinmeden hemen ÖNCEKİ anını öğrenelim ve NOT ALALIM
SELECT GETDATE() AS [Kaza_Oncesi_Zaman_Not_Edin]; 
-- ***********************************************
-- DİKKAT: ÜSTTEKİ SORGUDAN DÖNEN SAATİ KOPYALAYIN.
-- ***********************************************

WAITFOR DELAY '00:00:02';
GO

-- 3. KAZA ANI: Veriler yanlışlıkla silinir (Örneğin WHERE olmadan yazılan hatalı bir komut)
DELETE FROM Table_RecoveryTest; 
GO
-- Veriler gitti!

-- 4. KURTARMA SÜRECİ (Disaster Recovery Process)

-- a. İlk iş, mevcut logları kaybetmemek için bir "Tail Log Backup" alınır.
-- DB NORECOVERY moduna alınır ve kullanıma kapatılarak kurtarma sürecine sokulur.
USE master;
GO
BACKUP LOG Northwind TO DISK = 'C:\Backups\Northwind_Tail_Log.trn' WITH NORECOVERY, INIT;
GO

-- b. Temel olarak alınan en son Tam Yedeği (Full Backup) RECOVERY olmadan geri yükleriz.
RESTORE DATABASE Northwind FROM DISK = 'C:\Backups\Northwind_Base_Recovery.bak' WITH NORECOVERY, REPLACE;
GO

-- c. Tail Log Yedeğini, verilerin silinmeden (kaza) hemen ÖNCESİNDEKİ bir zamana kadar okuyarak uygularız.
-- BÖYLECE VERİLER GERİ GELMİŞ OLUR.
-- DİKKAT: STOPAT parametresine yukaridaki "[Kaza_Oncesi_Zaman_Not_Edin]" sonucunu yazın.

-- LÜTFEN AŞAĞIDAKİ YORUM SATIRLARINI KALDIRIP İLGİLİ TARİH/SAAT BİLGİSİNİ DÜZENLEYEREK ÇALIŞTIRIN:
/*
RESTORE LOG Northwind 
FROM DISK = 'C:\Backups\Northwind_Tail_Log.trn' 
WITH STOPAT = '202X-XX-XX HH:MM:SS.mmm', RECOVERY;
GO
*/

-- 5. TEST: Geri yükleme bittikten sonra verilerin gelip gelmediğini kontrol edelim:
-- USE Northwind;
-- SELECT * FROM Table_RecoveryTest;
-- GO
