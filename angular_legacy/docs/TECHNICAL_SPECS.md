# 🛠️ Especificaciones Técnicas (v1.0)

## 1. Frontend (Angular 20)
* **Arquitectura Zoneless:** Eliminación de `zone.js` para alto rendimiento móvil.
* **Reactive Signals:** Gestión de estado granular para el Geofencing y carga de mapas.
* **PWA:** Instalación nativa con Service Workers para sincronización asíncrona de reseñas.

## 2. Flujo de Validación PoV (Secret Sauce)
1. **Captura Telemetría:** El `GeoService` captura lat/lng + precisión.
2. **Validación de Cerca:** El sistema bloquea el voto si la distancia al negocio es > 50m.
3. **Auditoría de Imagen:** Los metadatos de la foto deben coincidir con el Timestamp y la ubicación del Check-in.

## 3. Seguridad
* **Edge Functions:** Los pesos del algoritmo de confianza (Trust Weight) residen en el servidor, no en el cliente.
* **Bot-Slayer:** Detección de patrones de comportamiento sospechosos y emuladores de GPS.