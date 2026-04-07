-- TEST YEDEKLEME SENARYOLARI: Yedeklerin Doğruluğunu Test Etme
-- Felaket kurtarma senaryolarinin sadece kagitta kalmamasi ve efektifligi icin yedeklerin bozuk olup olmadigini test etmek asiri kritiktir.

-- Yontem 1: Yedeğin Mantıksal ve Fiziksel Bütünlüğünü Doğrulamak (Veritabanını geri yüklemeden çalışır)
-- SQL Server'in, yedeğin dosya bozulmaları (corruption) olmadan okunabilirliğini test etmesini sağlar.
RESTORE VERIFYONLY 
FROM DISK = 'C:\Backups\Northwind_Full.bak';
GO

-- Yontem 2: Yedek Dosyasının İçeriğindeki Dosya Yapısını Listelemek (Faydalıdır)
-- İçerisindeki mdf (data) ve ldf (log) dosyalarının mantıksal isimlerini ve boyutlarını gösterir.
RESTORE FILELISTONLY 
FROM DISK = 'C:\Backups\Northwind_Full.bak';
GO

-- Yontem 3: Yedek Dosyasının Başlık (Header) Bilgilerini Okumak
-- Hangi makineden alındığı, boyutu, türü vb. meta verileri test etmek amaçlı incelenebilir.
RESTORE HEADERONLY 
FROM DISK = 'C:\Backups\Northwind_Full.bak';
GO

-- Yontem 4: 'Side-by-side Restore' ile Yedeklerin Asıl Yapıyı Bozmadan Test Edilmesi (EN GÜVENİLİR YÖNTEM)
-- Gerçekten yedeği üretim ortamına dokunmadan farklı isimle (Test Veritabanı olarak) çıkarır. 
USE master;
GO

-- Orijinal Northwind log ve data dosyalarının üzerine yazmamak için hedefleri 'MOVE' parametresi ile yönlendiriyoruz.
RESTORE DATABASE Northwind_TestRestore 
FROM DISK = 'C:\Backups\Northwind_Full.bak'
WITH 
    MOVE 'Northwind' TO 'C:\Backups\Northwind_Test_Data.mdf',        -- Gercek mantiksal data ismini Filelistonly ile kontrol edin.
    MOVE 'Northwind_log' TO 'C:\Backups\Northwind_Test_Log.ldf',     -- Gercek mantiksal log ismini kontrol edin.
    RECOVERY;
GO

-- Bu işlem başarılı olduysa, 'Northwind_TestRestore' veritabanına bağlanıp ilgili tablolar test edilebilir.

-- Test bittikten sonra alanı temizlemek için test veritabanını kaldırabilirsiniz:
/*
USE master;
GO
DROP DATABASE Northwind_TestRestore;
GO
*/
