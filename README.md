# 🚀 Deploy Nexus Repository OSS with Docker Compose

Script ini digunakan untuk melakukan instalasi dan konfigurasi otomatis **Nexus Repository OSS** menggunakan Docker Compose. Termasuk di dalamnya setup blobstore, Docker registry, serta konfigurasi keamanan awal.

---

## 📦 Fitur

- Otomatis membuat volume untuk penyimpanan
- Menjalankan Nexus dengan Docker Compose
- Menunggu Nexus hingga siap digunakan
- Membuat blobstore untuk registry `dev` dan `test`
- Membuat dua Docker hosted registry (`5000` dan `5001`)
- Mengaktifkan realm Docker authentication
- Mengaktifkan akses Anonymous

---

## ⚙️ Instalasi

> Jalankan sebagai **root**

```bash
cd $HOME
rm -rf deploy-nexus
git clone https://github.com/aldojr/deploy-nexus.git
cd deploy-nexus
chmod +x deploy.sh
./deploy.sh
```

Tunggu hingga muncul:
🚀 All Configuration running well !

---

## 🌐 Akses Web UI

Buka browser dan akses:
http://<your-server-ip>:8081


Login dengan:

- **Username**: `admin`
- **Password**: `admin123`

---

## 🔐 Konfigurasi Setelah Login

Masuk ke menu:

Administration > Security > Users > anonymous


Lalu ubah:

- Tambahkan **nx-admin** ke daftar **Roles granted**
- Hapus **nx-anonymous** dari daftar **Roles granted**

---

## 📝 Catatan

- Port Docker Registry:
  - `http://<ip>:5000` untuk `docker-registry-dev`
  - `http://<ip>:5001` untuk `docker-registry-test`
- Default volume path: `/var/lib/docker/volumes/`

---

## 🧑‍💻 Author

**Reynaldo**  
https://github.com/aldojr


