# PasswordHolder API

## Genel Bakış
PasswordHolder, bir Node.js/Express REST API servisidir. Servis; kullanıcı, departman ve şifre kartı (holder) kavramlarını destekler, MSSQL üzerinde tutulur ve JWT tabanlı kimlik doğrulama kullanır.

## Katmanlı Mimari
- `app.js`: Express uygulamasını başlatır, node .\app.js
- `routes/`: İstekleri ilgili controller fonksiyonlarına yönlendirir.
- `Controllers/`: HTTP seviyesindeki doğrulama ve yanıt formatlarını yönetir.
- `Service/`: İş kurallarını toplar, controller ile veri erişim katmanı arasındaki bağı gevşetir.
- `DataAccess/`: MSSQL bağlantısı (`DataAccess/db.js`) ve SQL sorgularını içerir.
- `Middleware/requireAuth.js`: Bearer token doğrulaması yaparak `req.user` değerini üretir.


## Ortam Değişkenleri (`.env`)
| Değişken          | Açıklama                             | Varsayılan           |
|-------------------|--------------------------------------|----------------------|
| `PORT`            | Express sunucusunun dinleyeceği port | `3000`               |
| `JWT_SECRET`      | Token imzalama anahtarı              | `development-secret` |
| `JWT_EXPIRES_IN`  | Token süresi (örn. `1h`, `7d`)       | `1h`                 |
| MSSQL bağlantısı  | `DataAccess/db.js` içinde sabit      | `localhost`/`sa`/`123` |

> MSSQL kullanıcı adı/şifresi ve sunucu bilgilerini güvenlik gereksinimlerinize göre güncelleyin.

## API Referansı

### Kullanıcılar (`/api/users`)
| Metot & Yol           | Açıklama | Not |
|-----------------------|----------|-----|
| `POST /login`         | Giriş yapar, JWT döner | Gövde: `{ email, password }` |
| `POST /logout`        | Bilgilendirici cevap | Token istemci tarafında silinir |
| `POST /`              | Yeni kullanıcı yaratır | `departmentId` doğrulanır |
| `GET /`               | Kullanıcıları listeler | Yalnızca admin + `requireAuth` |
| `GET /:email`         | E-posta ile kullanıcı döner | Parola maskelenmez, bu nedenle istemcide saklanmalıdır |
| `PUT /:id`            | Kullanıcı günceller | Departman kontrolü yapılır |
| `DELETE /:id`         | Kullanıcı siler | 404 durumları için mesaj |

### Şifre Kartları (`/api/passwordholder`)
| Metot & Yol      | Açıklama | Yetki |
|------------------|----------|-------|
| `GET /`          | Kullanıcıya veya departmanına atanan kartları döner | Admin ise tüm kartlar |
| `POST /`         | Yeni kart oluşturur | Admin değilse otomatik olarak kendisine atanır |
| `PUT /:id`       | Kartı günceller | Admin olmayanlar sadece kendilerine atanmış ve `control !== 1` kartlarda işlem yapabilir |
| `DELETE /:id`    | Kartı siler | Yetki kontrolleri `passwordholder_models` içinde yapılır |

Kart oluştururken:
- `departmentId` belirtilirse kart departman üyelerine otomatik atanır (sadece admin).
- Departman seçilmezse `userIds`/`userId` dizisi gerekir; yoksa istek yapan kullanıcı atanır.
- `loginUrl` isteğe bağlıdır, boş gönderilirse `null` kaydedilir.

### Departmanlar (`/api/departments`)
| Metot & Yol   | Açıklama | Not |
|---------------|----------|-----|
| `GET /`       | Tüm departmanları listeler | `requireAuth` zorunlu |
| `GET /:id`    | Tek departman döner | ID doğrulaması yapılır |
| `POST /`      | Yeni departman oluşturur | Yalnızca admin, `name` zorunlu |
| `PUT /:id`    | Departman günceller | Yalnızca admin |
| `DELETE /:id` | Departman siler | Yalnızca admin |

## Veritabanı Şeması (Özet)
- `users(id, name, email, password, department_id)`
- `departments(id, name, description)`
- `holder(id, holder_title, holder_email, holder_password, login_url, control, user_id, department_id)`
- `holder_assignments(holder_id, user_id)` — bir kartın birden fazla kullanıcıya atanmasını sağlar.

## Örnek İstek Akışı
1. `POST /api/users/login` → token al.
2. `Authorization` başlığı ile `GET /api/passwordholder` → kendine ve departmanına atanmış kartları çek.
3. Adminsen `POST /api/departments` ile yeni departman ekle, ardından `POST /api/passwordholder` isteğinde `departmentId` göndererek kartı departman üyelerine ata.

## İlerletilecek Noktalar
- Parola alanlarını hashlemek (şu an düz metin).
- Rate limiting ve audit log’lar eklemek.
- MSSQL bağlantı bilgilerinin `.env` haline getirilip güvenli yönetimi.
- Otomatik testler (unit/integration) ve CI yapılandırması.



