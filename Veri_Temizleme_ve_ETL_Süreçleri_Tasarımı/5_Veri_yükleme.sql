

-- Temizleme ve dönüşüm işlemlerinden geçirilen veriler 
--JOIN işlemi ile birleştirilerek analiz için uygun hale getirilmiş ve Clean_Orders adlı yeni bir tabloya yüklenmiştir.
-- Bu işlem ETL sürecinin Load aşamasını temsil etmektedir.

SELECT 
    o.OrderID,
    c.CompanyName,
    c.Country,
    o.OrderDate,
    YEAR(o.OrderDate) as OrderYear,
    o.Freight
INTO Clean_Orders
FROM Orders_Staging o
JOIN Customers_Staging c
ON o.CustomerID = c.CustomerID;

-- Yeni tablomuzun oluştuğunu görmek için hem sol taraftaki tablolardan bakabiliriz. 
-- ya da aşağıdaki sorguyu çalıştırabiliriz.

SELECT * FROM Clean_Orders;