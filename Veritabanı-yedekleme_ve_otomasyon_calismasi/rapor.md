# BLM4522 – Ağ Tabanlı Paralel Dağıtım Sistemleri  
## Proje 7: Veritabanı Yedekleme ve Otomasyon Çalışması
 
**Öğrenci Adı:** [Özge Taraşlı]  
**Öğrenci No:** [21290755]  
**Platform:** Microsoft SQL Server (SSMS)  
**Veritabanı:** Northwind  
**Video:** []
 
---
 
## İçindekiler
 
1. [Giriş ve Amaç](#1-giriş-ve-amaç)  
2. [Kullanılan Ortam](#2-kullanılan-ortam)  
3. [Yedekleme Stratejisi Tasarımı](#3-yedekleme-stratejisi-tasarımı)  
4. [Ortam Hazırlığı ve Recovery Model Ayarı](#4-ortam-hazırlığı-ve-recovery-model-ayarı)  
5. [Yedekleme Klasörlerinin Oluşturulması](#5-yedekleme-klasörlerinin-oluşturulması)  
6. [Manuel Yedekleme Testleri](#6-manuel-yedekleme-testleri)  
   - 6.1 Full Backup  
   - 6.2 Differential Backup  
   - 6.3 Transaction Log Backup  
7. [SQL Server Agent ile Otomasyon](#7-sql-server-agent-ile-otomasyon)  
   - 7.1 Agent Durumu Kontrolü  
   - 7.2 Full Backup Job  
   - 7.3 Differential Backup Job  
   - 7.4 Log Backup Job  
   - 7.5 Job'ların Manuel Tetiklenmesi ve Test  
8. [T-SQL Raporlama Sorguları](#8-t-sql-raporlama-sorguları)  
9. [Otomatik Uyarı Sistemi – Database Mail](#9-otomatik-uyarı-sistemi--database-mail)  
   - 9.1 Database Mail Kurulumu  
   - 9.2 Operator Tanımlama  
   - 9.3 Alert Tanımlama  
   - 9.4 Başarısız Backup Simülasyonu  
10. [Sonuç ve Değerlendirme](#10-sonuç-ve-değerlendirme)
---
 
## 1. Giriş ve Amaç
 
Bu proje kapsamında Microsoft SQL Server üzerinde çalışan **Northwind** örnek veritabanı için kapsamlı bir yedekleme ve otomasyon altyapısı tasarlanmış ve uygulanmıştır.
 
Projenin temel hedefleri şunlardır:
 
- Tam (Full), Fark (Differential) ve İşlem Günlüğü (Transaction Log) yedekleme stratejilerini oluşturmak
- SQL Server Agent ile yedekleme işlemlerini belirli zaman aralıklarında otomatik hale getirmek
- T-SQL sorguları ve `msdb` sistem veritabanı üzerinden yedekleme geçmişini raporlamak.Yani backup geçmiş bilgilerini, T-SQL sorguları yazarak msdb içinden çekmek
- Başarısız yedekleme senaryolarında yöneticiye otomatik e-posta bildirimi gönderecek bir uyarı mekanizması kurmak
Veritabanı yönetiminde yedekleme ve felaketten kurtarma süreçleri, iş sürekliliği açısından kritik öneme sahiptir. Bu proje, söz konusu süreçlerin hem manuel hem de otomatik boyutlarını kapsamaktadır.
 
---
 
## 2. Kullanılan Ortam
 
| Bileşen | Detay |
|---|---|
| İşletim Sistemi | Windows 11 |
| Veritabanı Yönetim Sistemi | Microsoft SQL Server 2022 |
| Yönetim Arayüzü | SQL Server Management Studio (SSMS) |
| Veritabanı | Northwind (örnek veritabanı) |
| Yedek Depolama Yolu | `C:\Backups\Northwind\` |
| Bildirim Sistemi | Database Mail (SMTP) |

Aşağıdaki sorgu ile veritabanımızın doğru ve var olduğunu doğruladık; aynı zamanda hangi recovery model'de olduğunu kontrol ettik. Yedekleme işlemleri için veritabanının FULL recovery model'de çalışması gerekmektedir.

```sql
SELECT 
    name,
    state_desc,
    recovery_model_desc
FROM sys.databases
WHERE name = 'Northwind';
```
Eğer recovery_model_desc değeri SIMPLE ise aşağıdaki komut ile FULL olarak değiştirilebilir. Bizim ortamımızda veritabanı zaten FULL model'de olduğu için bu adım uygulanmamıştır.

```sql
USE master;
ALTER DATABASE Northwind SET RECOVERY FULL;

-- Doğrula
SELECT name, recovery_model_desc 
FROM sys.databases 
WHERE name = 'Northwind';
```
![Northwind veritabanı durum ve recovery model sorgusu](görseller/image1.png)

*Şekil 1: Northwind veritabanı durum ve recovery model sorgusu*