# BLM 4522 AG TABANLI PARALEL DAĞITIM SİSTEMLERİ
## PROJE RAPORU: Veri Temizleme ve ETL Süreçleri Tasarımı

**Hazırlayan:** Özge Taraşlı  
**Öğrenci No:** 21290755  

---

## İçindekiler
1. [Giriş](#1-giriş)
   - 1.1 [Kullanılan Ortam](#11-kullanılan-ortam)
   - 1.2 [Veri Tabanı ve Senaryo](#12-veri-tabanı-ve-senaryo)
   - 1.3 [Amaç ve Planlama](#13-amaç-ve-planlama)
2. [ETL Süreçleri ve Uygulama](#2-etl-süreçleri-ve-uygulama)
   - 2.1 [Staging (Ara Katman) Oluşturma](#21-staging-ara-katman-oluşturma)
   - 2.2 [Veri Bozulma ve Kalite Testleri](#22-veri-bozulma-ve-kalite-testleri)
   - 2.3 [Veri Temizleme Stratejileri (Transform)](#23-veri-temizleme-stratejileri-transform)
3. [Sonuç](#3-sonuç)

---

## 1. Giriş
Bu proje, modern veri ambarı mimarilerinde kritik bir rol oynayan **ETL (Extract, Transform, Load)** süreçlerinin tasarımını ve uygulanmasını konu almaktadır. Veri temizleme süreçleri; kirli veya tutarsız verilerin analiz öncesinde ayıklanarak veri kalitesinin artırılmasını hedefler.

### 1.1 Kullanılan Ortam
- **Veritabanı Sistemi:** Microsoft SQL Server 2022
- **Yönetim Aracı:** SQL Server Management Studio (SSMS)
- **Örnek Veri Seti:** Northwind Database

### 1.2 Veri Tabanı ve Senaryo
Projede **Northwind** veritabanı üzerinden `Customers` ve `Orders` tabloları temel alınmıştır. Gerçek dünya senaryolarında üretim veritabanından alınan verilerin temizlenip analiz edilmek üzere bir veri ambarına aktarılması simüle edilmiştir.

### 1.3 Amaç ve Planlama
Projenin temel amacı, ham veriyi alıp belirli kurallara göre temizleyerek tutarlı bir hale getirmektir:
- **Extract (Çekme):** Orijinal tabloların kopyalarının (Staging) oluşturulması.
- **Transform (Dönüştürme):** Hatalı verilerin (NULL değerler, mükerrer kayıtlar, gereksiz boşluklar) tespiti ve düzeltilmesi.
- **Load (Yükleme):** Temizlenen verinin hedef tabloya aktarılması.

---

## 2. ETL Süreçleri ve Uygulama

### 2.1 Staging (Ara Katman) Oluşturma
Orijinal verilere zarar vermemek ve çalışma alanını ayırmak için staging tabloları oluşturulmuştur. `1_STAGING.sql` scripti ile `Customers` ve `Orders` tabloları ara katmana taşınmıştır.

```sql
-- Staging müşteri tablosu oluşturma
SELECT * INTO Customers_Staging FROM Customers;

-- Staging sipariş tablosu oluşturma
SELECT * INTO Orders_Staging FROM Orders;
```
Yandaki tablolar kısmından `Customers_Staging` ve `Orders_Staging` tablolarını görebiliriz.

proje5_images1.jpeg

Aşağıdaki sorguları çalıştırarak da tabloların içeriğini kontrol edebiliriz:

```sql
SELECT * FROM Customers_Staging;
SELECT * FROM Orders_Staging;
```

proje5_images2.jpeg

### 2.2 Veri Bozulma ve Kalite Testleri
Veri temizleme mantığını test edebilmek amacıyla, staging tablolarında kasıtlı olarak veri kalitesi hataları oluşturulmuştur (`2_Verileri_Bozma.sql`).

- **NULL Değerler:** `ALFKI` kodlu müşterinin şehir bilgisi silinmiştir.
```sql
UPDATE Customers_Staging
SET City = NULL
WHERE CustomerID = 'ALFKI';
```

- **Tutarsız Veri:** Ülke isimleri küçük harfe dönüştürülmüş veya farklı formatlarda yazılmıştır.
```sql
UPDATE Customers_Staging
SET Country = 'turkiye'
WHERE CustomerID = 'ANATR';
```

- **Boşluk Sorunları:** İsimlerin önüne ve arkasına gereksiz boşluklar eklenmiştir.
```sql
UPDATE Customers_Staging
SET CompanyName = '   ABC Company   '
WHERE CustomerID = 'ANTON';
```

- **Mükerrer Kayıtlar:** Belirli bir kayıt (`AROUT`) tabloya tekrar eklenerek mükerrer (duplicate) veri sorunu simüle edilmiştir.
```sql
INSERT INTO Customers_Staging
SELECT * FROM Customers_Staging
WHERE CustomerID = 'AROUT';
```

proje5_images3.jpeg

### 2.3 Veri Temizleme Stratejileri (Transform)
`3_Veri_temizleme.sql` scripti ile uygulanan temel temizleme adımları şunlardır:

**1. NULL Yönetimi:** Eksik şehir bilgilerinin "Unknown" olarak güncellenmesi.

1.1. NULL değerleri bulma: Yanlış verilerin tespiti ve doğru kayıtların hedeflendiğini doğrulamak için kullanılır.
```sql
SELECT *
FROM Customers_Staging
WHERE City IS NULL;
```
proje5_images4.jpeg

1.2. NULL değerleri düzeltme:
```sql
UPDATE Customers_Staging
SET City = 'Unknown'
WHERE City IS NULL;
```
proje5_images5.jpeg

1.3. Doğrulama: Adım 1.1'deki sorgu tekrar çalıştırıldığında NULL değerlerinin kalmadığı görülür. Bu, işlemin başarıyla tamamlandığını gösterir.
```sql
SELECT *
FROM Customers_Staging
WHERE City IS NULL;
```
proje5_images6.jpeg

**2. Duplicate Kontrolü:** Mükerrer kayıtların ayıklanarak tekilleştirilmesi.

2.1. Mükerrer kayıtları bulma:
```sql
SELECT CustomerID, COUNT(*) as sayi
FROM Customers_Staging
GROUP BY CustomerID
HAVING COUNT(*) > 1;
```
proje5_images7.jpeg

2.2. Mükerrer kayıtları silme:
```sql
WITH CTE AS (
    SELECT *,
    ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY CustomerID) as rn
    FROM Customers_Staging
)
DELETE FROM CTE WHERE rn > 1;
```
proje5_images8.jpeg

2.3. Doğrulama: Silindiğini teyit etmek için ilgili sorgu tekrar çalıştırılır.
```sql
SELECT CustomerID, COUNT(*) as sayi
FROM Customers_Staging
GROUP BY CustomerID
HAVING COUNT(*) > 1;
```
proje5_images9.jpeg

**3. TRIM İşlemi:** İsimlerdeki baş ve son boşlukların temizlenmesi (`LTRIM` ve `RTRIM`).

3.1. Boşlukları temizleme:
```sql
UPDATE Customers_Staging
SET CompanyName = LTRIM(RTRIM(CompanyName));
```
proje5_images10.jpeg

3.2. Doğrulama: Boş bir sonuç kümesi dönmesi, verilerin temizlendiğini gösterir.
```sql
SELECT CompanyName
FROM Customers_Staging
WHERE CompanyName LIKE ' %' OR CompanyName LIKE '% ';
```
proje5_images11.jpeg

**4. Standartlaştırma:** Ülke isimlerinin standart büyük harf formatına dönüştürülmesi.

4.1. Büyük/küçük harf tutarsızlıklarını düzeltme:
```sql
UPDATE Customers_Staging
SET Country = UPPER(Country);
```
proje5_images12.jpeg

4.2. Doğrulama: Tüm kayıtların büyük harf formatında olduğu kontrol edilir.
```sql
SELECT DISTINCT Country FROM Customers_Staging;
```
proje5_images13.jpeg

**5. Mantıksız Veri Kontrolü:** Gelecekteki sipariş tarihlerinin düzeltilmesi.

5.1. Mantıksız verileri bulma: Gelecek tarihli hatalı veriler kontrol edilir. Test için manuel olarak hatalı veri girişi yapılmıştır.
```sql
SELECT *
FROM Orders_Staging
WHERE OrderDate > GETDATE();
```
proje5_images14.jpeg

Hata Ekleme Simülasyonu:
```sql
UPDATE Orders_Staging
SET OrderDate = '2099-01-01'
WHERE OrderID = 10248;
```
proje5_images15.jpeg

Tekrar Kontrol:
```sql
SELECT *
FROM Orders_Staging
WHERE OrderDate > GETDATE();
```
proje5_images16.jpeg

5.2. Mantıksız verileri düzeltme:
```sql
UPDATE Orders_Staging
SET OrderDate = GETDATE()
WHERE OrderDate > GETDATE();
```
proje5_images17.jpeg

5.3. Doğrulama:
```sql
SELECT *
FROM Orders_Staging
WHERE OrderDate > GETDATE();
```

## 3. Sonuç
Bu aşamaya kadar ETL sürecinin **Extract** ve **Simülasyon (Bozma)** aşamaları ile birlikte **Transform (Temizleme)** işlemleri başarıyla tamamlanmış, ara katman tabloları analiz edilebilir ve tutarlı bir hale getirilmiştir. Hazırlanan rapor, projenin mevcut durumunu ve veri kalitesi iyileştirmelerini belgelemektedir.
