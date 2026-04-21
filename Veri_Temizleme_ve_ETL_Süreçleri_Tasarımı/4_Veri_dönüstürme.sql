-- Veri dönüştürmede amacımız veriyi analiz edilebiir hale dönüştürmek.
-- Yeni Alan Oluştur
-- mevcut veriden yeni bir bilgi türetiyoruz. 
-- OrderYear oluşturulur çünkü yıl bilgisini her seferinde yeniden hesaplamak yerine doğrudan kullanarak sorguları daha basit, daha hızlı ve daha anlaşılır hale getirir.

ALTER TABLE Orders_Staging
ADD OrderYear INT;

UPDATE Orders_Staging
SET OrderYear = YEAR(OrderDate);

--Kontrol etmek için aşağıdaki sorguyu çalıştırırız.Gelen Tabloda yeni oluşturulan sütunları görürüz.


SELECT OrderDate, OrderYear
FROM Orders_Staging;


-- 2. Kategori oluştururuz.

-- burda da sayısal veriyi kategorize ediyoruz. Veriyi yorumlanabilir hale getiriyoruz.
--verilerimiz low high medium olarak grupladık.

SELECT OrderID,
       Freight,
       CASE 
           WHEN Freight < 50 THEN 'LOW'
           WHEN Freight BETWEEN 50 AND 100 THEN 'MEDIUM'
           ELSE 'HIGH'
       END as FreightCategory
FROM Orders_Staging;

--3. Join ile veri zenginleştirme
-- Farklı tablolardan veri birleştiriyoruz. Tek tablo yetmiyor başka tablodan bilgi çekiyoruz


SELECT o.OrderID, c.CompanyName, o.OrderDate
FROM Orders_Staging o
JOIN Customers_Staging c
ON o.CustomerID = c.CustomerID;