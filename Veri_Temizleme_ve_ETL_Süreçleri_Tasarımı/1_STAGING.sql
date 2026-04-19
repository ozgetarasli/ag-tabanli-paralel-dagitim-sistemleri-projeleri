-- staging yani ara katman tabloları verinin orijinal halinin kopyasının tutulduğu geçici çalışma alanıdır.
-- orijinal veriyi bozmamak için kopya oluşturuyoruz



-- Staging müşteri tablosu
SELECT *
INTO Customers_Staging
FROM Customers;

-- Staging sipariş tablosu
SELECT *
INTO Orders_Staging
FROM Orders;


-- yandaki tablolar kısmından Customers_Staging ve Orders_Staging tablolarını görebiliriz.



-- Ya da aşağıdaki sorguları çalıştırarak görebiliriz.

SELECT * FROM Customers_Staging;
SELECT * FROM Orders_Staging;