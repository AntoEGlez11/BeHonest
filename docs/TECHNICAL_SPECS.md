# 🛠️ Technical Specifications: beHonest v1.0 (2026)

## 1. Stack Tecnológico
* **Frontend:** Angular 20 (Zoneless, Signals, Control Flow avanzado).
* **Backend:** Supabase / PostgreSQL con extensión PostGIS (Geografía).
* **Validación:** Edge Functions para procesamiento de Score (Secret Logic).
* **Mapas:** Leaflet + OpenStreetMap (Protocolo de ahorro de datos).

## 2. Arquitectura de Datos (Resumen)
Para mantener la integridad, el sistema se divide en:
1.  **Entidades de Identidad:** Perfiles y Karma.
2.  **Entidades Espaciales:** Negocios con coordenadas `geography`.
3.  **Entidades de Verificación:** Logs de GPS, Fotos y Scores ponderados.

## 3. Lógica de Validación (Proof of Visit)
* **Paso 1:** Captura de GPS mediante `navigator.geolocation` con precisión < 10m.
* **Paso 2:** Validación de marca de tiempo (Timestamp) para evitar inyecciones de datos viejos.
* **Paso 3:** Análisis de metadatos de imagen para confirmar presencia real.