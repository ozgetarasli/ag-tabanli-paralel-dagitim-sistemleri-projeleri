-- Verileri Bilerek Bozarız. Kullandığımız veritabanında bozuk veri eklemek için.


-- NULL değer oluştur
UPDATE Customers_Staging
SET City = NULL
WHERE CustomerID = 'ALFKI';

-- tutarsız veri
UPDATE Customers_Staging
SET Country = 'turkiye'
WHERE CustomerID = 'ANATR';

-- boşluk problemi
UPDATE Customers_Staging
SET CompanyName = '   ABC Company   '
WHERE CustomerID = 'ANTON';

-- duplicate veri
INSERT INTO Customers_Staging
SELECT * FROM Customers_Staging
WHERE CustomerID = 'AROUT';

-- Verilerin bozulup bozulmadığını kontrol etmek için aşağıdaki sorguları çalıştırabiliriz.
SELECT * FROM Customers_Staging WHERE City IS NULL;
SELECT * FROM Customers_Staging WHERE Country = 'turkiye';
SELECT * FROM Customers_Staging WHERE CompanyName LIKE '   %';
SELECT * FROM Customers_Staging WHERE CustomerID = 'AROUT';
