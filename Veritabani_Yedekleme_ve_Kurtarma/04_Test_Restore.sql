-- TEST YEDEKLEME SENARYOLARI: Yedeklerin Doğruluğunu Test Etme

-- Yontem 1: Yedeğin Mantıksal ve Fiziksel Bütünlüğünü Doğrulamak (Veritabanını geri yüklemeden çalışır)

RESTORE VERIFYONLY 
FROM DISK = 'C:\SQLBackups\Northwind_Full.bak';
GO




-- Yontem 2: 'Side-by-side Restore' ile Yedeklerin Asıl Yapıyı Bozmadan Test Edilmesi 

USE master;
GO

RESTORE DATABASE Northwind_TestRestore 
FROM DISK = 'C:\SQLBackups\Northwind_Full.bak'
WITH 
    MOVE 'Northwind' TO 'C:\SQLBackups\Northwind_Test_Data.mdf',        
    MOVE 'Northwind_log' TO 'C:\SQLBackups\Northwind_Test_Log.ldf',     
    RECOVERY;
GO
