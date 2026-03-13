# Contributing to Clickdev PlugPlay

Terima kasih sudah mau berkontribusi! 🎉

## 🐛 Melaporkan Bug

Buka **Issues** di GitHub dan isi:
- Versi Godot yang dipakai
- Langkah untuk reproduce bug
- Error message (jika ada)

## ➕ Menambah Condition Baru

Edit `addons/clickdev_plugplay/codegen/ClickdevCodeGen.gd`, di fungsi `get_condition_catalogue()`:

```gdscript
"nama_condition":
    { "label": "Label yang muncul di UI",
      "category": "general",          # sesuaikan dengan kategori yang ada
      "params": ["param1", "param2"], # nama parameter yang diisi user
      "code":  "gdscript_{param1} == {param2}" },
```

Gunakan `{param_name}` sebagai placeholder — akan diganti dengan nilai yang diisi user.

## ➕ Menambah Action Baru

Edit fungsi `get_action_catalogue()` dengan format yang sama seperti di atas.

## ➕ Menambah Kategori Baru

Edit `get_condition_categories()` atau `get_action_categories()`:

```gdscript
{ "id": "nama_kategori", "label": "🔥  Nama Kategori" },
```

Lalu tambahkan `"category": "nama_kategori"` ke semua item yang masuk kategori itu.

## 📋 Pull Request Guidelines

- Satu PR untuk satu fitur atau bug fix
- Test di Godot 4.x sebelum submit
- Tulis deskripsi yang jelas di PR
- Ikuti code style yang sudah ada (GDScript static typing)

## 📄 Lisensi

Dengan berkontribusi, kamu setuju bahwa kode kontribusimu dilisensikan di bawah **MIT License**.
