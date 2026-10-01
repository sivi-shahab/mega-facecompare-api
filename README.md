# mega-facecompare-api

| Metadata | |
|---|---|
| Judul | README mega-facecompare-api (compreface-api) |
| Versi | 2.0.0 |
| Tanggal | 2026-10-01 |
| Owner | Tim Platform / DevOps |
| Status | Review |

| Versi | Tanggal | Penulis | Perubahan |
|---|---|---|---|
| 1.0.0 | 2026-09-29 | Claude Code | Versi awal (di monorepo `services/<service>/README.md`) |
| 2.0.0 | 2026-10-01 | Claude Code | Repo mandiri hasil split monorepo Mega-CompreFace |

**REST API publik (Spring Boot)** — image `mega/compreface-api`. Bagian dari CompreFace (fork Exadel CompreFace 1.2.0, Apache 2.0) yang dipecah
dari monorepo Mega-CompreFace menjadi 6 repo. Integrasi full-stack, monitoring, dokumentasi SDLC (SPEC,
ARCHITECTURE, RUNBOOK, SECURITY, TEST_PLAN) dan versi rilis bersama ada di
[mega-facecompare-deploy](https://scm.bankmegadev.com/cobs/data-management/application/mega-facecompare-deploy).

## Fungsi
REST API publik `/api/v1` (modul Maven `java/api` + `java/common`): kelola subject/example wajah, recognition, verification, detection. Memanggil core untuk deteksi & embedding, menyimpan embedding (dan gambar bila `SAVE_IMAGES_TO_DB=true`) ke Postgres, cache embedding di heap.

Source aplikasi: `java/pom.xml` (parent `frs-java`, modul `common` + `api`), `java/api/`, `java/common/` (vendored — lihat [java/common/README.md](java/common/README.md)). **Logika aplikasi upstream tidak diubah** di repo ini; perubahan hanya pada
build, konfigurasi, dan dokumentasi.

## Isi repo
| File | Isi |
|---|---|
| `Dockerfile` | Stage 1 Maven (`-pl api -am`, build arg `ND4J_CLASSIFIER`); stage 2 JRE 17, uid 1001 |
| `.dockerignore` | Context: `java/pom.xml`, `java/common`, `java/api`, `LICENSE`, `NOTICE` |
| `java/common/.checksum` | Checksum isi `java/common` — harus sama dengan repo `mega-facecompare-admin` |
| `scripts/build.sh` | Build `mega/compreface-api:<versi>` dari root repo (versi default: file `VERSION`); tulis `build/images.txt` |
| `scripts/push.sh` | Push ke registry (catat digest ke `build/digests.txt`) atau `--save <dir>` → tarball + `SHA256SUMS` untuk transfer air-gapped |
| `k8s/base/` | Manifest service ini saja (Deployment/StatefulSet, Service, ConfigMap, NetworkPolicy) |
| `k8s/overlays/{dev,prod}/` | Overlay per environment untuk service ini |
| `.gitlab-ci.yml` | validate → build → scan (Trivy) → push; registry & kredensial dari variabel CI |
| `.env.example` | Env var service ini (tanpa nilai rahasia) |

## Port & healthcheck
| Port | Healthcheck | Catatan |
|---|---|---|
| 8080 | `/api/v1/consistence/status` (fungsional, memanggil core) | `/api/v1/**` (header `x-api-key`) |
| 8081 | `/actuator/health/liveness`, `/actuator/health/readiness` | Actuator (di 8080 `/actuator` diblokir filter api-key) |

## Env var
Non-rahasia (ConfigMap `compreface-api`, default juga di-bake di `Dockerfile`/`.env.example`):

| Variabel | Default | Catatan |
|---|---|---|
| `POSTGRES_URL` | `jdbc:postgresql://compreface-postgres-db:5432/frs` | JDBC URL |
| `PYTHON_URL` | `http://compreface-core:3000` | URL core (ClusterIP) |
| `SPRING_PROFILES_ACTIVE` | `dev` |  |
| `API_JAVA_OPTS` | `-XX:MaxRAMPercentage=75.0` |  |
| `JAVA_TOOL_OPTIONS` | `-Duser.timezone=Asia/Jakarta` |  |
| `SAVE_IMAGES_TO_DB` | `true` |  |
| `MAX_FILE_SIZE` | `5MB` |  |
| `MAX_REQUEST_SIZE` | `10MB` |  |
| `CONNECTION_TIMEOUT` | `10000` | ms, ke core |
| `READ_TIMEOUT` | `60000` | ms, ke core |
| `MAX_ATTEMPTS` | `1` | retry ke core |
| `MANAGEMENT_SERVER_PORT` | `8081` |  |
| `MANAGEMENT_ENDPOINT_HEALTH_PROBES_ENABLED` | `true` |  |
| `LOGGING_LEVEL_COM_EXADEL` | `INFO` |  |
| `TZ` | `Asia/Jakarta` |  |

Rahasia (Secret Kubernetes — contoh struktur: [k8s/secret.example.yaml](k8s/secret.example.yaml)):

| Variabel | Sumber | Catatan |
|---|---|---|
| `POSTGRES_USER` | Secret `compreface-postgres-credentials` | **wajib** dari Secret / env, tidak pernah di image atau git |
| `POSTGRES_PASSWORD` | Secret `compreface-postgres-credentials` | **wajib** dari Secret / env, tidak pernah di image atau git |

Referensi lengkap seluruh service: `docs/CONFIGURATION.md` di repo deploy.

## Build
```bash
scripts/build.sh                       # → mega/compreface-api:$(cat VERSION)
REGISTRY=registry.example.internal scripts/build.sh && scripts/push.sh
scripts/push.sh --save /media/transfer # air-gapped: docker save + SHA256SUMS → docker load di sisi internal
# manual (build context = root repo, tanpa akses ke repo lain):
docker build -t mega/compreface-api:1.2.0 .
```
Tag `latest` ditolak. Versi image dinaikkan dengan mengubah `VERSION` + `CHANGELOG.md`; versi yang dirilis
bersama dicatat di `versions.env` repo deploy.

## Run (lokal, tanpa orkestrasi)
```bash
cp .env.example .env    # isi nilai yang ditandai WAJIB
docker run -d --name compreface-api --read-only --tmpfs /tmp:exec \
  --env-file .env --network <network-yang-berisi-db-core> mega/compreface-api:1.2.0
docker exec compreface-api curl -fsS http://127.0.0.1:8081/actuator/health/readiness
```
Untuk full-stack (5 service) gunakan `scripts/compose.sh` di repo deploy.

## Kubernetes
```bash
kubectl kustomize k8s/overlays/dev          # render
kubectl apply -k k8s/overlays/dev           # namespace compreface-dev harus sudah ada (dibuat repo deploy)
```
Namespace, NetworkPolicy default-deny + DNS egress, dan Secret dikelola di repo deploy. Repo deploy menyimpan
salinan `k8s/base/` repo ini di `k8s/services/compreface-api/` — setelah mengubah `k8s/base/`, jalankan
`scripts/sync-manifests.sh` di repo deploy.

## Kontrak ke service lain
Nama Service, port dan nama env var **tidak berubah** dibanding monorepo — perubahannya adalah breaking change
dan harus dikoordinasikan lewat repo deploy.

- **Dipanggil oleh**: `compreface-fe` (`/api/v1/**` → `compreface-api:8080`) dan klien REST (header `x-api-key`). Referensi API: dokumen upstream di repo deploy (`docs/upstream/Rest-API-description.md`).
- **Memanggil**: `compreface-core:3000` (`PYTHON_URL`: `/find_faces`, `/status`), `compreface-postgres-db:5432` (JDBC).
- **Skema DB** dimigrasi oleh `compreface-admin`; pada DB kosong api harus start setelah admin sehat.

## Catatan operasional
⚠️ `/tmp` harus **exec** (ND4J memuat library native OpenBLAS dari `/tmp`) — di compose `tmpfs: /tmp:exec`; emptyDir k8s sudah sesuai. `ND4J_CLASSIFIER=linux-x86_64-avx2 scripts/build.sh` untuk CPU modern (opsional).

## Lisensi
Apache License 2.0 — lihat [LICENSE](LICENSE) dan [NOTICE](NOTICE) (atribusi Exadel, Inc. dipertahankan).
