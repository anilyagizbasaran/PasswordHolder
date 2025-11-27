# PasswordHolder MSSQL Şeması

Bu döküman `PasswordHolderBackend` tarafından kullanılan tablo yapısını özetler ve MSSQL üzerinde aynı yapıyı oluşturmanız için örnek bir script sağlar.

## Tablo Özeti

- `departments`: Departman adları ve açıklamaları.
- `users`: Kullanıcı bilgileri ve opsiyonel departman ilişkisi.
- `holder`: Şifre kartları; kartın sahibi veya ilgili departman, yönetim kontrolü ve silinme durumu alanlarını içerir.
- `holder_assignments`: Kart ile kullanıcılar arasındaki çoktan çoğa ilişkiyi tutar.

## MSSQL Script

```sql
-- Departmanlar
IF OBJECT_ID('dbo.departments', 'U') IS NOT NULL DROP TABLE dbo.departments;
CREATE TABLE dbo.departments (
    id            INT             IDENTITY(1,1) PRIMARY KEY,
    name          NVARCHAR(150)   NOT NULL UNIQUE,
    description   NVARCHAR(500)   NULL
);

-- Kullanıcılar
IF OBJECT_ID('dbo.users', 'U') IS NOT NULL DROP TABLE dbo.users;
CREATE TABLE dbo.users (
    id             INT            IDENTITY(1,1) PRIMARY KEY,
    name           NVARCHAR(150)  NOT NULL,
    email          VARCHAR(320)   NOT NULL UNIQUE,
    password       VARCHAR(255)   NOT NULL,
    department_id  INT            NULL
        REFERENCES dbo.departments(id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

-- Şifre kartları
IF OBJECT_ID('dbo.holder', 'U') IS NOT NULL DROP TABLE dbo.holder;
CREATE TABLE dbo.holder (
    id              INT            IDENTITY(1,1) PRIMARY KEY,
    holder_title    NVARCHAR(200)  NOT NULL,
    holder_email    NVARCHAR(320)  NULL,
    holder_password NVARCHAR(400)  NOT NULL,
    login_url       NVARCHAR(500)  NULL,
    control         INT            NOT NULL DEFAULT 0,
    user_id         INT            NULL
        REFERENCES dbo.users(id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    department_id   INT            NULL
        REFERENCES dbo.departments(id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    is_deleted      BIT            NOT NULL DEFAULT 0,
    created_at      DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at      DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME()
);

-- Kart-kullanıcı eşlemesi
IF OBJECT_ID('dbo.holder_assignments', 'U') IS NOT NULL DROP TABLE dbo.holder_assignments;
CREATE TABLE dbo.holder_assignments (
    holder_id   INT NOT NULL
        REFERENCES dbo.holder(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    user_id     INT NOT NULL
        REFERENCES dbo.users(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    PRIMARY KEY (holder_id, user_id)
);

-- Performans için indeksler
CREATE INDEX IX_users_department_id ON dbo.users(department_id);
CREATE INDEX IX_holder_department_id ON dbo.holder(department_id);
CREATE INDEX IX_holder_assignments_user ON dbo.holder_assignments(user_id);
```

