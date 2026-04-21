-- Veri Temizleme hatalı verilerin düzeltilmesi sürecidir.
--Staging tablosundaki verileri
-- Null ise dolduruyoruz
-- duplicate ise siliyoruz
-- boşluk ise temizliyoruz
-- format hatası ise düzeltiyoruz
-- mantıksız veri ise düzeltiyoruz

-- Bu işlemleri analiz yapabilmek ve hatalı sonuçları önlemek için yapıyoruz.

-- 1.1 Null değerleri bul. yanlış veriler var mı doğru şeyi mi düzeltiyoruz görmek için.
SELECT *
FROM Customers_Staging
WHERE City IS NULL;

--1.2 Null değerleri düzelt

UPDATE Customers_Staging
SET City = 'Unknown'
WHERE City IS NULL;

--1.3 Tekrar 1.1'i çalıştırdığımızda bu sefer null değerlerini olmadığını/boş döndüğünü görürüz. bu da düzelttiğimiz anlamına gelir.

SELECT *
FROM Customers_Staging
WHERE City IS NULL;


--2.1 Duplicate kayıtları bul

SELECT CustomerID, COUNT(*) as sayi
FROM Customers_Staging
GROUP BY CustomerID
HAVING COUNT(*) > 1;

-- 2.2 Duplicate kayıtları sil

WITH CTE AS (
    SELECT *,
    ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY CustomerID) as rn
    FROM Customers_Staging
)
DELETE FROM CTE WHERE rn > 1;

-- 2.3 Tekrar 2.1'i çalıştır. silindiğini görmek için.

SELECT CustomerID, COUNT(*) as sayi
FROM Customers_Staging
GROUP BY CustomerID
HAVING COUNT(*) > 1;


--3.1 Boşlukları temizle

UPDATE Customers_Staging
SET CompanyName = LTRIM(RTRIM(CompanyName));

-- 3.2 Boşlukların temizlendiğini göstermek için aşağıdaki sorguyu çalıştırabiliriz.Boş bir değer dönmesi bize temizlendiğini gösterir.
SELECT CompanyName
FROM Customers_Staging
WHERE CompanyName LIKE ' %' OR CompanyName LIKE '% ';

--4.1 Büyük/küçük harf tutarsızlıklarını düzelt. Hepsini büyük harfe çeviriyoruz.

UPDATE Customers_Staging
SET Country = UPPER(Country);

-- 4.2 Düzeltildiğini görmek için aşağıdaki sorguyu çalıştırabiliriz. Hepsinin büyük harf döndüğünü görürüz.

SELECT DISTINCT Country FROM Customers_Staging;

--5.1 Mantıksız verileri düzelt. Önce mantıksız verileri buluyoruz. Eğer yoksa (bizim veritabanımızda yoktu) kendimiz bir sonraki sql komutunu çalıştırıp hata ekleriz.


SELECT *
FROM Orders_Staging
WHERE OrderDate > GETDATE();


-- Hata ekleme

UPDATE Orders_Staging
SET OrderDate = '2099-01-01'
WHERE OrderID = 10248;

-- Tekrar kontrol

SELECT *
FROM Orders_Staging
WHERE OrderDate > GETDATE();


-- 5.2 Mantıksız verileri düzeltme

UPDATE Orders_Staging
SET OrderDate = GETDATE()
WHERE OrderDate > GETDATE();

-- 5.3 Tekrar kontrol

SELECT *
FROM Orders_Staging
WHERE OrderDate > GETDATE();