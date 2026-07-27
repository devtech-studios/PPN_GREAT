# คู่มือ MySQL MCP และการสำรอง/กู้คืนฐานข้อมูล PPN

อัปเดตล่าสุด: 18 กรกฎาคม 2026

## 1. สถานะจริงของโปรเจกต์

Laravel ใน `ppn-api` ใช้ค่าต่อไปนี้จาก `.env`:

- Driver: `mysql`
- Host: `127.0.0.1`
- Port: `3306`
- Database: `ppn_staging`
- Database server ที่ตรวจพบจริง: MariaDB `10.4.32` จาก XAMPP
- Laravel: `12.x`
- จำนวนตารางขณะสำรอง: 35 ตาราง

MariaDB รองรับ MySQL protocol จึงใช้งานผ่าน Laravel `mysql` driver ได้ แต่ต้องตรวจ compatibility ก่อนนำคำสั่งหรือ option ที่มีเฉพาะ MySQL 8 มาใช้

ห้ามนำค่า `DB_PASSWORD`, JWT token หรือข้อมูลจากไฟล์ SQL dump ไปใส่ใน Git, prompt, log หรือ MCP resource

## 2. Backup ที่จัดทำแล้ว

ไฟล์สำรอง:

```text
storage/backups/mysql/ppn_staging_before_mcp_full_backup_2026-07-18_133524.sql
```

ข้อมูลตรวจสอบ:

- ขนาด: 70,866 bytes
- ตารางใน dump: 35
- SHA-256: `95017AEECF41B27B559FAF78E084BE515F4E88F3E8834FF285DEA2A35D65C851`
- Manifest: `storage/backups/mysql/ppn_staging_before_mcp_full_backup_2026-07-18_133524_manifest.md`
- Checksum file: `storage/backups/mysql/ppn_staging_before_mcp_full_backup_2026-07-18_133524.sql.sha256`

ตรวจ checksum ด้วย PowerShell:

```powershell
Get-FileHash `
  -Algorithm SHA256 `
  -LiteralPath 'D:\07_Projects\Work\PNN\ppn-api\storage\backups\mysql\ppn_staging_before_mcp_full_backup_2026-07-18_133524.sql'
```

ค่าที่ได้ต้องตรงกับ SHA-256 ข้างต้นทุกตัวอักษร หากไม่ตรง ห้ามนำไฟล์ไป restore

## 3. คำสั่งสำรองฐานข้อมูลรอบถัดไป

ใช้ `--result-file` แทน PowerShell redirection (`>`) เพื่อหลีกเลี่ยงปัญหา encoding บน Windows:

```powershell
$stamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$backup = "D:\07_Projects\Work\PNN\ppn-api\storage\backups\mysql\ppn_staging_full_backup_$stamp.sql"

& 'C:\xampp\mysql\bin\mysqldump.exe' `
  --host=127.0.0.1 `
  --port=3306 `
  --user='<BACKUP_USER>' `
  --single-transaction `
  --quick `
  --routines `
  --triggers `
  --events `
  --hex-blob `
  --default-character-set=utf8mb4 `
  --skip-lock-tables `
  --databases ppn_staging `
  --result-file="$backup"

if ($LASTEXITCODE -ne 0) { throw 'Database backup failed' }
Get-FileHash -Algorithm SHA256 -LiteralPath $backup
```

ไม่ควรส่ง password ผ่าน argument บน production เพราะอาจปรากฏใน process list ให้ใช้ option file ที่จำกัดสิทธิ์หรือระบบ secret manager แทน

## 4. ขั้นตอนกู้คืนอย่างปลอดภัย

ไฟล์ที่จัดทำมี `CREATE DATABASE` และ `USE ppn_staging` จึงเป็น exact-restore backup ห้ามทดลอง restore ทับฐานปัจจุบันโดยไม่ได้รับอนุมัติ

ลำดับที่แนะนำ:

1. หยุด Laravel API, queue worker และ E2E ที่เขียนข้อมูล
2. สำรองฐานปัจจุบันอีกรอบ
3. ตรวจ SHA-256 ของไฟล์ที่จะใช้
4. ยืนยันชื่อฐานเป้าหมาย
5. ใช้ MariaDB/MySQL client import
6. ตรวจ migration, table count และ API smoke หลัง restore

คำสั่ง restore ฐานเดิม:

```powershell
& 'C:\xampp\mysql\bin\mysql.exe' `
  --host=127.0.0.1 `
  --port=3306 `
  --user='<RESTORE_USER>' `
  --execute="source D:/07_Projects/Work/PNN/ppn-api/storage/backups/mysql/ppn_staging_before_mcp_full_backup_2026-07-18_133524.sql"
```

หลัง restore:

```powershell
cd D:\07_Projects\Work\PNN\ppn-api
C:\xampp\php\php.exe artisan migrate:status
C:\xampp\php\php.exe artisan test
```

การ restore ยังไม่ได้ถูกรันในรอบนี้ เพื่อไม่เขียนทับหรือสร้างฐานข้อมูลโดยไม่ได้รับอนุมัติ

## 5. รูปแบบ MCP ที่เหมาะกับ PPN

สถาปัตยกรรมแนะนำ:

```text
Codex / MCP Host
        |
        | stdio (local)
        v
PPN MySQL MCP Server
        |
        | account แบบ read-only
        v
MariaDB 10.4 / ppn_staging
```

เริ่มจาก local `stdio` MCP server เพราะจำกัดการเข้าถึงให้อยู่กับ MCP host บนเครื่องเดียว และไม่ต้องเปิด database/MCP port ออกสู่เครือข่าย

### Tools ระยะที่ 1: read-only

- `db_health`: ตรวจการเชื่อมต่อและ version โดยไม่คืน secret
- `list_tables`: แสดงเฉพาะตารางใน `ppn_staging`
- `describe_table`: คืน column/index/foreign key ของตารางที่อยู่ใน allowlist
- `select_query`: อนุญาตเฉพาะ `SELECT`, `SHOW`, `DESCRIBE`, `EXPLAIN`
- `table_row_counts`: คืนจำนวน record เพื่อวิเคราะห์ test data
- `list_backups`: แสดงชื่อ เวลา ขนาด และ checksum ของ backup
- `verify_backup_checksum`: ตรวจ checksum โดยไม่เปิดเผยเนื้อหาข้อมูล

ข้อบังคับสำหรับ `select_query`:

- block multi-statement และ semicolon ต่อคำสั่ง
- block `INSERT`, `UPDATE`, `DELETE`, `DROP`, `ALTER`, `TRUNCATE`, `CREATE`, `GRANT`
- block `INTO OUTFILE`, `LOAD_FILE`, `SLEEP`, `BENCHMARK`
- บังคับ `LIMIT` สูงสุด เช่น 200 rows
- ตั้ง query timeout
- redact password, token, secret และข้อมูลส่วนบุคคลที่ไม่จำเป็น
- บันทึก audit log: เวลา, tool, ตาราง, จำนวนแถว และผู้เรียก โดยไม่บันทึก secret

### Tools ระยะที่ 2: mutation

ยังไม่ควรเปิดในรอบแรก หากจำเป็นต้องมี mutation ให้สร้าง tool เฉพาะงาน เช่น `create_test_customer` แทน arbitrary SQL และต้องมี:

- explicit approval
- transaction
- validation
- idempotency key
- audit log
- rollback/cleanup strategy
- backup ที่ตรวจ checksum แล้วก่อนงานเสี่ยง

## 6. Database account สำหรับ MCP

ห้ามใช้ `root` กับ MCP ให้ DBA สร้าง user แยกและใช้ password แบบสุ่มที่แข็งแรง ตัวอย่างสำหรับพิจารณา:

```sql
CREATE USER 'ppn_mcp_reader'@'127.0.0.1' IDENTIFIED BY '<STRONG_RANDOM_PASSWORD>';
GRANT SELECT, SHOW VIEW ON ppn_staging.* TO 'ppn_mcp_reader'@'127.0.0.1';
FLUSH PRIVILEGES;
```

สำหรับ backup automation ให้ใช้ user แยกจาก MCP reader และให้เฉพาะ privilege ที่เครื่องมือ dump ต้องใช้ เช่น `SELECT`, `SHOW VIEW`, `TRIGGER`, `EVENT` โดยตรวจตาม MariaDB version จริง

ยังไม่ได้รัน SQL สร้าง user ข้างต้น เพราะต้องกำหนด password และอนุมัติสิทธิ์ก่อน

## 7. MCP client configuration template

หลังสร้างและตรวจ MCP server ของโปรเจกต์แล้ว ให้ MCP client เรียกด้วย absolute path:

```json
{
  "mcpServers": {
    "ppn-mysql-readonly": {
      "command": "node",
      "args": [
        "D:/07_Projects/Work/PNN/ppn-api/mcp/mysql-server/dist/index.js"
      ]
    }
  }
}
```

ให้ MCP server โหลด credentials จาก `.env`/secret store ที่ถูก ignore โดย Git ไม่ใส่ password ตรงใน JSON configuration

ก่อนติดตั้ง community MCP package ต้องตรวจ source, dependency, maintainer, release history และคำสั่ง startup ทุกตัว เพราะ local MCP server ทำงานด้วยสิทธิ์เดียวกับ MCP client

## 8. Acceptance checklist ก่อนเปิดใช้ MCP

- [ ] backup ล่าสุด exit code 0 และ checksum ตรง
- [ ] ทดสอบ restore บนฐานแยกสำเร็จ
- [ ] MCP ใช้ database user เฉพาะ ไม่ใช้ root
- [ ] ระยะแรกเป็น read-only
- [ ] จำกัด schema/table allowlist
- [ ] จำกัด row count และ query timeout
- [ ] redact secrets/PII
- [ ] มี audit log
- [ ] MCP ใช้ local stdio หรือ transport ที่มี authentication
- [ ] mutation tools ต้อง approval และ rollback ได้
- [ ] รัน Laravel/API/Playwright regression หลังเปลี่ยน integration

## 9. แหล่งข้อมูลหลัก

- [MCP: Understanding server concepts](https://modelcontextprotocol.io/docs/learn/server-concepts)
- [MCP: Build an MCP server](https://modelcontextprotocol.io/docs/develop/build-server)
- [MCP Security Best Practices](https://modelcontextprotocol.io/docs/tutorials/security/security_best_practices)
- [MariaDB: mariadb-dump](https://mariadb.com/docs/server/clients-and-utilities/backup-restore-and-import-clients/mariadb-dump)
- [MariaDB: Backup and Restore Overview](https://mariadb.com/docs/server/server-usage/backup-and-restore/backup-and-restore-overview)
- [MySQL: mysqldump](https://dev.mysql.com/doc/refman/8.4/en/mysqldump.html)
- [MySQL: Reloading SQL-format backups](https://dev.mysql.com/doc/refman/8.4/en/reloading-sql-format-dumps.html)
