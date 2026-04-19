-- Kaç tane veri eksikti biz kaç tanesini düzelttik.

--Daha öncesinde Null değerleri unkonown olarak değiştirmiştik. Aşağıdkai sorgu ile de kaç tane NULL vardı = kaç tane düzeltme yaptık omnu ölçüyoruz.

SELECT COUNT(*) as EksikSehir
FROM Customers_Staging
WHERE City = 'Unknown';

--2. Duplicate sonrası durum:

SELECT COUNT(*) FROM Customers_Staging;

--Temizleme işlemi sonrasında veri setindeki toplam kayıt sayısının 91 olduğu gözlemlenmiştir. Duplicate temizleme işleminin veri sayısını azalttığı anlaşılmaktadır.

--3.Ülke dağılımı
--Her ülke için kaç müşteri olduğunu sayar
-- Önce: turkey,TURKEY,Turkey gibi değerler vardı yaptığımız işlemler sonrası hepsi TURKEY oldu ve sayım doğru bir şekilde yapıldı.

SELECT Country, COUNT(*) as sayi
FROM Customers_Staging
GROUP BY Country;

--4.Freight dağılımı
-- Freight değerlerinin dağılımını görmek için kullanılır. Bu sayede düşük, orta ve yüksek maliyetli siparişlerin oranları belirlenmiştir.
-- Freight değerleri 50'den küçükse LOW, 50-100 arasındaysa MEDIUM, 100'den büyükse HIGH olarak kategorize edilmiştir.
SELECT 
    CASE 
        WHEN Freight < 50 THEN 'LOW'
        WHEN Freight BETWEEN 50 AND 100 THEN 'MEDIUM'
        ELSE 'HIGH'
    END as kategori,
    COUNT(*) as sayi
FROM Orders_Staging
GROUP BY 
    CASE 
        WHEN Freight < 50 THEN 'LOW'
        WHEN Freight BETWEEN 50 AND 100 THEN 'MEDIUM'
        ELSE 'HIGH'
    END;

