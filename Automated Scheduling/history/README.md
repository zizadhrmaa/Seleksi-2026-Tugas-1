# Riwayat Automated Scheduling

Folder ini menyimpan bukti ringkas hasil pipeline.

- `pipeline_runs.csv` berisi seluruh batch scheduling yang dipertahankan sebagai bukti.
- `latest_two_batches.csv` berisi dua batch terbaru untuk menunjukkan perbedaan timestamp ekstraksi.

Timestamp menggunakan ISO 8601 UTC:

```text
YYYY-MM-DDTHH:MM:SS.mmmZ
```

Contoh:

```text
2026-07-23T10:31:55.961Z
```

Kolom `data_directory` dan `log_file` memakai path relatif agar file dapat dibaca pada repository tanpa bergantung pada drive atau username komputer lokal.
