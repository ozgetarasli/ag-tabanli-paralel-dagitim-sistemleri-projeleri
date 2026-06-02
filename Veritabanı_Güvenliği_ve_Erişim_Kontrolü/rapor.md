# BLM4522 – Ağ Tabanlı Paralel Dağıtım Sistemleri  
## Proje 3: Veritabanı Güvenliği ve Erişim Kontrolü

**Öğrenci Adı:** Özge Taraşlı  
**Öğrenci No:** 21290755  
**Platform:** Microsoft SQL Server (SSMS)  
**Veritabanı:** Northwind  
**Git:** [Git Repo Linkiniz]  
**Video:** [Video Linkiniz]

---

## İçindekiler

1. [Giriş ve Amaç](#1-giriş-ve-amaç)  
2. [Kullanılan Ortam](#2-kullanılan-ortam)  
3. [Mevcut Güvenlik Durumunun İncelenmesi](#3-mevcut-güvenlik-durumunun-i̇ncelenmesi)  
4. [Erişim Yönetimi](#4-erişim-yönetimi)  
   - 4.1 Login ve Kullanıcı Oluşturma  
   - 4.2 Rol Oluşturma ve Yetki Atama  
   - 4.3 Yetki Testi  
5. [Veri Şifreleme – TDE](#5-veri-şifreleme--tde)  
   - 5.1 Master Key Oluşturma  
   - 5.2 Sertifika Oluşturma  
   - 5.3 Database Encryption Key  
   - 5.4 TDE'yi Aktif Etme  
   - 5.5 Şifreleme Durumunu Doğrulama  
   - 5.6 Sertifikayı Yedekleme  
6. [SQL Injection Testleri](#6-sql-injection-testleri)  
   - 6.1 Savunmasız Sorgu Örneği  
   - 6.2 Normal Kullanım  
   - 6.3 Injection Saldırısı Simülasyonu  
   - 6.4 Korumalı Sorgu ile Karşılaştırma  
7. [Audit Log Kurulumu](#7-audit-log-kurulumu)  
   - 7.1 Server Audit Oluşturma  
   - 7.2 Database Audit Specification  
   - 7.3 Logların Okunması  
   - 7.4 Başarısız Giriş Denemesini Loglama  
8. [Sonuç ve Değerlendirme](#8-sonuç-ve-değerlendirme)

---

## 1. Giriş ve Amaç

Bu proje kapsamında Microsoft SQL Server üzerinde çalışan **Northwind** örnek veritabanı için kapsamlı bir güvenlik altyapısı tasarlanmış ve uygulanmıştır.

Veritabanı güvenliği; yetkisiz erişimin engellenmesi, verilerin şifrelenerek korunması, olası saldırılara karşı önlem alınması ve sistem aktivitelerinin kayıt altına alınması gibi birbirini tamamlayan katmanlardan oluşur. Bu proje bu katmanların tümünü kapsamaktadır.

Projenin temel hedefleri şunlardır:

- SQL Server Authentication kullanarak farklı yetki seviyelerinde kullanıcılar oluşturmak ve rol tabanlı erişim kontrolü uygulamak
- TDE (Transparent Data Encryption) ile veritabanı dosyalarını disk üzerinde şifrelemek
- SQL Injection saldırılarını simüle ederek savunmasız ve korumalı sorgu yazımı arasındaki farkı göstermek
- SQL Server Audit özelliği ile kullanıcı aktivitelerini kayıt altına almak ve başarısız giriş denemelerini izlemek

---

## 2. Kullanılan Ortam

| Bileşen | Detay |
|---|---|
| İşletim Sistemi | Windows 11 |
| Veritabanı Yönetim Sistemi | Microsoft SQL Server 2022 |
| Yönetim Arayüzü | SQL Server Management Studio (SSMS) |
| Veritabanı | Northwind (örnek veritabanı) |
| Audit Log Yolu | `C:\Backups\AuditLogs\` |
| Sertifika Yedek Yolu | `C:\Backups\` |

---

## 3. Mevcut Güvenlik Durumunun İncelenmesi

Güvenlik yapılandırmasına başlamadan önce sistemdeki mevcut login'ler ve veritabanı kullanıcıları incelenmiştir. Bu adım, hangi hesapların zaten var olduğunu görmek ve çakışma riskini önlemek açısından önemlidir.

```sql
USE Northwind;

-- Mevcut login'leri listele
-- type = S: SQL Server Authentication, U: Windows User, G: Windows Group
SELECT name, type_desc, is_disabled, create_date
FROM sys.server_principals
WHERE type IN ('S','U','G')
ORDER BY type_desc, name;

-- Mevcut database user'larını listele
SELECT name, type_desc, create_date
FROM sys.database_principals
WHERE type IN ('S','U','G')
ORDER BY type_desc;
```

> Bu sorgular; sistemde tanımlı tüm login'leri, bunların tipini (SQL mi, Windows mı), devre dışı olup olmadıklarını ve oluşturulma tarihlerini listeler.

![Mevcut login ve database user listesi](görseller/image1.png)

*Şekil 1: Sistemdeki mevcut login ve database user'ların listelenmesi*

---

## 4. Erişim Yönetimi

Erişim yönetimi, veritabanı güvenliğinin temel taşıdır. **En az yetki prensibi (Principle of Least Privilege)** gereği her kullanıcıya yalnızca işini yapabilmesi için gerekli olan minimum yetki verilmelidir. Bu bölümde üç farklı yetki seviyesinde kullanıcı oluşturulmuş ve rol tabanlı yetkilendirme uygulanmıştır.

### 4.1 Login ve Kullanıcı Oluşturma

SQL Server'da erişim iki katmanlıdır:
- **Login:** Sunucuya bağlanma yetkisi (master veritabanında tanımlanır)
- **User:** Belirli bir veritabanındaki erişim yetkisi (o veritabanında tanımlanır)

Bir login olmadan user, bir user olmadan veritabanına erişim mümkün değildir.

```sql
USE master;

-- 1. Salt okunur kullanıcı — sadece raporlama yapacak
-- CHECK_POLICY: Windows parola politikasını uygular
-- CHECK_EXPIRATION: Parola süresini zorlamaz
CREATE LOGIN ReadOnlyLogin 
    WITH PASSWORD = 'Readonly123!',
    CHECK_POLICY = ON,
    CHECK_EXPIRATION = OFF;

-- 2. Veri giriş kullanıcısı — sipariş ve müşteri verisi girebilecek
CREATE LOGIN DataEntryLogin 
    WITH PASSWORD = 'DataEntry123!',
    CHECK_POLICY = ON,
    CHECK_EXPIRATION = OFF;

-- 3. Veritabanı yöneticisi — tam yetkili
CREATE LOGIN DBManagerLogin 
    WITH PASSWORD = 'DBManager123!',
    CHECK_POLICY = ON,
    CHECK_EXPIRATION = OFF;
```

```sql
-- Her login için Northwind veritabanında karşılık gelen user oluştur
USE Northwind;

CREATE USER ReadOnlyUser  FOR LOGIN ReadOnlyLogin;
CREATE USER DataEntryUser FOR LOGIN DataEntryLogin;
CREATE USER DBManagerUser FOR LOGIN DBManagerLogin;
```

![Oluşturulan login'lerin SSMS Security altında görünmesi](görseller/image2.png)

*Şekil 2: Oluşturulan login'lerin ve Northwind user'larının doğrulanması*

### 4.2 Rol Oluşturma ve Yetki Atama

Yetkileri kullanıcılara tek tek vermek yerine **rol** oluşturup o role yetki atamak çok daha yönetilebilir bir yapı sağlar. Yeni bir kullanıcı eklendiğinde sadece ilgili role üye yapmak yeterli olur.

```sql
USE Northwind;

-- Raporlama rolü: sadece okuma yetkisi
CREATE ROLE ReportingRole;
GRANT SELECT ON Customers       TO ReportingRole;
GRANT SELECT ON Orders          TO ReportingRole;
GRANT SELECT ON Products        TO ReportingRole;
GRANT SELECT ON [Order Details] TO ReportingRole;
ALTER ROLE ReportingRole ADD MEMBER ReadOnlyUser;

-- Veri giriş rolü: okuma + yazma (silme yetkisi yok)
CREATE ROLE DataEntryRole;
GRANT SELECT, INSERT, UPDATE ON Orders          TO DataEntryRole;
GRANT SELECT, INSERT, UPDATE ON [Order Details] TO DataEntryRole;
GRANT SELECT ON Customers TO DataEntryRole;
GRANT SELECT ON Products  TO DataEntryRole;
ALTER ROLE DataEntryRole ADD MEMBER DataEntryUser;

-- Yönetici: db_owner rolüne ekle (tam yetki)
ALTER ROLE db_owner ADD MEMBER DBManagerUser;
```


Atanan yetkileri sorgu ile doğrulayalım:

```sql
SELECT 
    dp.name           AS UserName,
    o.name            AS ObjectName,
    p.permission_name AS Permission,
    p.state_desc      AS State
FROM sys.database_permissions p
JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
JOIN sys.objects o ON p.major_id = o.object_id
WHERE dp.name IN ('ReadOnlyUser','DataEntryUser','ReportingRole','DataEntryRole')
ORDER BY dp.name, o.name;
```

![Atanan yetkilerin sorgu ile doğrulanması](görseller/image3.png)

*Şekil 3: Kullanıcı ve rol bazlı yetki tablosu*

### 4.3 Yetki Testi

`EXECUTE AS USER` komutu, mevcut oturumu kapatmadan başka bir kullanıcı kimliğiyle sorgu çalıştırmamızı sağlar. `REVERT` ile orijinal kimliğe dönülür. Bu, yetki konfigürasyonunu test etmenin en pratik yoludur.

```sql
USE Northwind;

-- ReadOnlyUser kimliğine geç
EXECUTE AS USER = 'ReadOnlyUser';

    -- Bu çalışmalı: SELECT yetkisi var
    SELECT TOP 5 CustomerID, CompanyName FROM Customers;

    -- Bu HATA vermeli: INSERT yetkisi yok
    INSERT INTO Customers(CustomerID, CompanyName)
    VALUES ('XXXXX', 'Test Company');

REVERT;  -- Kendi kullanıcına dön
```

![SELECT başarılı INSERT hata veriyor](görseller/image4.png)

*Şekil 5: ReadOnlyUser ile SELECT başarılı, INSERT için "The INSERT permission was denied" hatası*

```sql
-- DataEntryUser kimliğine geç
EXECUTE AS USER = 'DataEntryUser';

    -- Bu çalışmalı: SELECT yetkisi var
    SELECT TOP 3 OrderID, CustomerID FROM Orders;

    -- Bu HATA vermeli: DELETE yetkisi yok
    DELETE FROM Orders WHERE OrderID = 10248;

REVERT;
```

![SELECT başarılı DELETE hata veriyor](görseller/image5.png)

*Şekil 5: DataEntryUser ile SELECT başarılı, DELETE için yetki hatası*

---

## 5. Veri Şifreleme – TDE

**TDE (Transparent Data Encryption)**, veritabanı dosyalarını (`.mdf`, `.ldf`) disk üzerinde şifreler. "Transparent" (şeffaf) olmasının nedeni, uygulamada hiçbir değişiklik gerektirmemesidir — veriler SQL Server tarafından otomatik olarak şifrelenip çözülür.

TDE özellikle fiziksel disk hırsızlığına karşı koruma sağlar. Şifreleme anahtarı olmadan disk kopyalansa bile veriler okunamaz.

**Şifreleme zinciri:**
```
Master Key → Sertifika → Database Encryption Key → Veritabanı Dosyaları
```

### 5.1 Master Key Oluşturma

Master Key, SQL Server'daki tüm şifreleme işlemlerinin temelidir. `master` veritabanında tutulur ve diğer sertifikaların şifrelenmesinde kullanılır.

```sql
USE master;

CREATE MASTER KEY 
    ENCRYPTION BY PASSWORD = 'MasterKey123!Strong';

-- Master Key'in oluşturulduğunu doğrula
SELECT name, is_master_key_encrypted_by_server
FROM sys.databases
WHERE name = 'master';
```

![Master Key oluşturma başarı mesajı](görseller/image6.png)

*Şekil 6: Master Key'in başarıyla oluşturulduğunu gösteren sorgu sonucu*

### 5.2 Sertifika Oluşturma

Sertifika, veritabanı şifreleme anahtarını korumak için kullanılır. TDE zincirindeki ikinci halkadır.

```sql
USE master;

CREATE CERTIFICATE NorthwindTDECert
    WITH SUBJECT = 'Northwind TDE Certificate',
    EXPIRY_DATE  = '2030-12-31';

-- Sertifikayı doğrula
SELECT name, subject, expiry_date, start_date
FROM sys.certificates
WHERE name = 'NorthwindTDECert';
```

![Sertifika bilgileri](görseller/image7.png)

*Şekil 7: Oluşturulan TDE sertifikasının bilgileri*

### 5.3 Database Encryption Key Oluşturma

Database Encryption Key (DEK), doğrudan veritabanı dosyalarını şifreleyen anahtardır. Yukarıda oluşturduğumuz sertifika tarafından korunur.

```sql
USE Northwind;

CREATE DATABASE ENCRYPTION KEY
    WITH ALGORITHM = AES_256
    ENCRYPTION BY SERVER CERTIFICATE NorthwindTDECert;
```

![DEK oluşturma mesajı](görseller/image8.png)

*Şekil 8: Database Encryption Key oluşturma başarı/uyarı mesajı*

### 5.4 TDE'yi Aktif Etme

```sql
USE master;

ALTER DATABASE Northwind
    SET ENCRYPTION ON;
```

### 5.5 Şifreleme Durumunu Doğrulama

```sql
SELECT 
    db.name,
    db.is_encrypted,
    dek.encryption_state,
    CASE dek.encryption_state
        WHEN 0 THEN 'Şifreleme yok'
        WHEN 1 THEN 'Şifrelenmemiş'
        WHEN 2 THEN 'Şifreleme devam ediyor'
        WHEN 3 THEN 'Şifrelenmiş'
        WHEN 4 THEN 'Key değişimi devam ediyor'
        WHEN 5 THEN 'Şifre çözme devam ediyor'
    END AS EncryptionStatus,
    dek.percent_complete,
    dek.key_algorithm,
    dek.key_length
FROM sys.databases db
JOIN sys.dm_database_encryption_keys dek 
    ON db.database_id = dek.database_id
WHERE db.name = 'Northwind';
```

![TDE şifreleme durumu](görseller/image9.png)

*Şekil 9: Northwind veritabanının is_encrypted = 1 ve EncryptionStatus = Şifrelenmiş olarak göründüğü ekran*

### 5.6 Sertifikayı Yedekleme

> ⚠️ **Kritik Uyarı:** TDE aktifken sertifika ve private key yedeklenmezse, SQL Server yeniden kurulduğunda veya sertifika silindiğinde **veritabanı açılamaz hale gelir**. Bu yedek, veritabanı yedeğinden daha kritiktir.

```sql
BACKUP CERTIFICATE NorthwindTDECert
    TO FILE = 'C:\Backups\NorthwindTDECert.cer'
    WITH PRIVATE KEY (
        FILE     = 'C:\Backups\NorthwindTDECert.pvk',
        ENCRYPTION BY PASSWORD = 'CertBackup123!'
    );
```

![Sertifika yedek dosyaları](görseller/image10.png)

*Şekil 10: C:\Backups\ klasöründe .cer ve .pvk dosyalarının oluşturulmuş hâli*

---

## 6. SQL Injection Testleri

**SQL Injection**, kullanıcıdan alınan girdinin doğrudan SQL sorgusuna eklenmesiyle oluşur. Saldırgan, girdi alanına SQL kodu yazarak sorgunun mantığını değiştirebilir; yetkisiz verilere erişebilir, veri silebilir veya tablolar düşürebilir.

Bu bölümde aynı işlevi gören iki stored procedure yazılmıştır:
- `GetCustomerUnsafe`: String birleştirme kullanan, savunmasız versiyon
- `GetCustomerSafe`: Parametreli sorgu kullanan, korumalı versiyon

### 6.1 Savunmasız Stored Procedure

```sql
USE Northwind;

-- Dinamik SQL ile string birleştirme — SAVUNMASIZ
CREATE PROCEDURE GetCustomerUnsafe
    @CustomerID NVARCHAR(50)
AS
BEGIN
    DECLARE @SQL NVARCHAR(500);
    -- Kullanıcı girdisi doğrudan SQL metnine yapıştırılıyor
    SET @SQL = 'SELECT CustomerID, CompanyName, Country 
                FROM Customers 
                WHERE CustomerID = ''' + @CustomerID + '''';
    EXEC(@SQL);
END;
```

![Savunmasız Stored Procedure](görseller/image11.png)

*Şekil 11: Savunmasız Stored Procedure* 

### 6.2 Normal Kullanım

```sql
-- Normal kullanım — beklendiği gibi sadece ALFKI müşterisi gelir
EXEC GetCustomerUnsafe @CustomerID = 'ALFKI';
```

![Normal kullanım sonucu](görseller/image12.png)

*Şekil 12: Normal parametre ile çağrıldığında sadece ALFKI müşterisinin geldiği sonuç*

### 6.3 Injection Saldırısı Simülasyonu

```sql
-- INJECTION: ' OR '1'='1 gönderilince sorgu şu hale gelir:
-- WHERE CustomerID = '' OR '1'='1'
-- '1'='1' her zaman TRUE olduğu için TÜM TABLO dökülür
EXEC GetCustomerUnsafe @CustomerID = "' OR '1'='1";
```

> Yukarıdaki injection, veritabanındaki tüm müşteri kayıtlarını döker. Gerçek bir senaryoda bu; şifreler, kredi kartı bilgileri, kişisel veriler gibi hassas bilgilerin sızdırılması anlamına gelir.



![Injection ile tüm tablo dökülüyor](görseller/image13.png)

*Şekil 13: OR '1'='1 injection'ı ile tüm Customers tablosunun döküldüğü sonuç — injection başarılı*

### 6.4 Korumalı Stored Procedure ile Karşılaştırma

```sql
-- Parametreli sorgu — GÜVENLİ
-- @CustomerID direkt WHERE koşuluna bağlanır, SQL metnine eklenmez
CREATE PROCEDURE GetCustomerSafe
    @CustomerID NCHAR(5)  -- veri tipi ve uzunluk kısıtlaması da ek güvenlik sağlar
AS
BEGIN
    SELECT CustomerID, CompanyName, Country
    FROM Customers
    WHERE CustomerID = @CustomerID;
END;
```

```sql
-- Aynı injection denemesi — artık çalışmaz
-- SQL Server bunu string olarak değil parametre olarak işler
EXEC GetCustomerSafe @CustomerID = "' OR '1'='1";
```

![Güvenli procedure injection'a karşı direniyor](görseller/image14.png)

*Şekil 14: Parametreli procedure'e injection denemesi — boş sonuç, injection başarısız*

**Karşılaştırma özeti:**

| Özellik | GetCustomerUnsafe | GetCustomerSafe |
|---|---|---|
| Sorgu yapısı | Dinamik string birleştirme | Parametreli sorgu |
| Injection riski | Var | Yok |
| Parametre tipi | NVARCHAR(50) — geniş | NCHAR(5) — kısıtlı |
| Önerilen | ❌ Hayır | ✅ Evet |

---

## 7. Audit Log Kurulumu

**SQL Server Audit**, veritabanındaki tüm aktiviteleri (kim, ne zaman, hangi nesneye, hangi işlemi yaptı) kayıt altına alır. Compliance (uyumluluk) gereksinimleri, güvenlik ihlali tespiti ve adli inceleme için kritik öneme sahiptir.

Audit mimarisi iki katmandan oluşur:
- **Server Audit:** Log dosyasının nereye yazılacağını tanımlar
- **Audit Specification:** Hangi olayların loglanacağını tanımlar

### 7.1 Server Audit Oluşturma


```sql
USE master;

CREATE SERVER AUDIT NorthwindSecurityAudit
    TO FILE (
        FILEPATH        = 'C:\Backups\AuditLogs\',
        MAXSIZE         = 10 MB,
        MAX_ROLLOVER_FILES = 5,       -- en fazla 5 dosya tut, eskiyi sil
        RESERVE_DISK_SPACE = OFF
    )
    WITH (
        QUEUE_DELAY = 1000,           -- 1 saniye gecikmeli yazma (performans için)
        ON_FAILURE  = CONTINUE        -- log yazılamazsa sistem çalışmaya devam etsin
    );

-- Audit'i başlat
ALTER SERVER AUDIT NorthwindSecurityAudit WITH (STATE = ON);
```

![Server Audit SSMS'de görünüyor](görseller/image15.png)

*Şekil 15: NorthwindSecurityAudit'in listelendiği ekran*

### 7.2 Database Audit Specification Oluşturma

Hangi tablolarda, hangi işlemlerin loglanacağı burada tanımlanır. `BY PUBLIC` ifadesi tüm kullanıcıların bu nesnelere erişiminin loglanacağı anlamına gelir.

```sql
USE Northwind;

CREATE DATABASE AUDIT SPECIFICATION NorthwindDBAuditSpec
    FOR SERVER AUDIT NorthwindSecurityAudit
    ADD (SELECT ON Customers              BY PUBLIC),
    ADD (INSERT ON Customers              BY PUBLIC),
    ADD (UPDATE ON Customers              BY PUBLIC),
    ADD (DELETE ON Customers              BY PUBLIC),
    ADD (SELECT ON Orders                 BY PUBLIC),
    ADD (INSERT ON Orders                 BY PUBLIC),
    ADD (DELETE ON Orders                 BY PUBLIC),
    ADD (EXECUTE ON dbo.GetCustomerUnsafe BY PUBLIC),
    ADD (EXECUTE ON dbo.GetCustomerSafe   BY PUBLIC)
    WITH (STATE = ON);
```

![Database Audit Specification başarı mesajı](görseller/image16.png)

*Şekil 16: Database Audit Specification'ın başarıyla oluşturulduğunu gösteren mesaj*

### 7.3 Logların Okunması

Önce loglanacak bazı işlemler gerçekleştirelim:

```sql
USE Northwind;

-- Farklı kullanıcılar adına işlemler yap — bunlar loglanacak
SELECT TOP 5 * FROM Customers;
SELECT TOP 5 * FROM Orders;

EXECUTE AS USER = 'ReadOnlyUser';
    SELECT TOP 3 CustomerID, CompanyName FROM Customers;
    SELECT TOP 3 OrderID FROM Orders;
REVERT;

EXECUTE AS USER = 'DataEntryUser';
    SELECT TOP 3 OrderID FROM Orders;
REVERT;
```

Şimdi logları sorgula:

```sql
-- Audit log dosyasını oku
SELECT TOP 20
    event_time,
    action_id,
    succeeded,
    server_principal_name,
    database_name,
    object_name,
    statement
FROM sys.fn_get_audit_file(
    'C:\Backups\AuditLogs\*.sqlaudit',
    DEFAULT, DEFAULT
)
ORDER BY event_time DESC;
```

> `action_id` sütunundaki değerler: `SL` = SELECT, `IN` = INSERT, `UP` = UPDATE, `DL` = DELETE, `EX` = EXECUTE

![Audit log tablosu](görseller/image17.png)

*Şekil 17: Audit log çıktısı — kim, ne zaman, hangi tabloya hangi işlemi yaptı*

### 7.4 Başarısız Giriş Denemesini Loglama

Başarısız login girişimlerini yakalamak için Server Audit Specification oluşturalım:

```sql
USE master;

CREATE SERVER AUDIT SPECIFICATION NorthwindServerAuditSpec
    FOR SERVER AUDIT NorthwindSecurityAudit
    ADD (FAILED_LOGIN_GROUP)   -- tüm başarısız giriş denemelerini yakala
    WITH (STATE = ON);
```

Şimdi başarısız bir giriş dene:
SSMS'de **yeni bağlantı aç** → `ReadOnlyLogin` kullanıcı adı ile yanlış şifre girerek bağlanmayı deneriz.

![Bağlanma ekranı](görseller/image18.png)

*Şekil 18: Başarısız giriş denemesi*

![Başarısız giriş denemesi](görseller/image19.png)

*Şekil 19: Başarısız giriş denemesi*

```sql
-- Başarısız giriş denemelerini sorgula
-- LGIF = Login Failed
SELECT 
    event_time,
    action_id,
    server_principal_name,
    statement,
    succeeded
FROM sys.fn_get_audit_file(
    'C:\Backups\AuditLogs\*.sqlaudit',
    DEFAULT, DEFAULT
)
WHERE action_id = 'LGIF'
ORDER BY event_time DESC;
```

![Başarısız giriş denemesi logda görünüyor](görseller/image20.png)

*Şekil 20: Başarısız giriş denemesinin audit logda kayıt altına alındığı ekran*

---

## 8. Sonuç ve Değerlendirme

Bu proje kapsamında Northwind veritabanı için dört katmanlı bir güvenlik altyapısı başarıyla kurulmuştur.

**Gerçekleştirilen Çalışmaların Özeti:**

| Bölüm | Yapılan İşlem | Sonuç |
|---|---|---|
| Erişim Yönetimi | 3 farklı yetki seviyesinde login/user oluşturuldu | Rol tabanlı erişim aktif |
| Yetki Testi | EXECUTE AS ile yetki sınırları test edildi | INSERT/DELETE yasakları doğrulandı |
| TDE | AES-256 ile veritabanı dosyaları şifrelendi | is_encrypted = 1 |
| Sertifika Yedekleme | .cer ve .pvk dosyaları yedeklendi | Felaketten kurtarma güvence altında |
| SQL Injection | Savunmasız ve korumalı procedure karşılaştırıldı | Parametreli sorgunun önemi gösterildi |
| Audit Log | Server Audit ve DB Audit Specification kuruldu | Tüm aktiviteler loglanıyor |
| Başarısız Login | FAILED_LOGIN_GROUP ile giriş denemeleri izleniyor | Log kaydı doğrulandı |


