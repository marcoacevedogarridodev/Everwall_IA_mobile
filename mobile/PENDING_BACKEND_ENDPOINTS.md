# Endpoints pendientes de crear en el backend

Este archivo lista los endpoints que el equipo mobile necesitó y que **no
existen todavía** en el backend real. Se nombraron siguiendo la misma
convención que el resto de tus rutas (`/api/pixels/<accion>/`, verbo/acción
en snake_case, sin `{id}` en el path — el id va en el body) para que sea
directo portarlos cuando implementes el backend.

Cuando crees uno de estos endpoints en Django, avísame el nombre final (si
cambia) y el formato exacto de la respuesta, y actualizo el único método
correspondiente en `lib/services/` — el resto de la app no se ve afectado.

---

## ⏳ `POST /api/pixels/toggle_like/`

**Estado:** no implementado en backend. El mobile ya está 100% cableado a
este contrato y funciona con optimistic update + rollback automático si la
llamada falla (para no romper nada mientras no exista).

**Usado por:** grid (ícono ❤️ en la celda), overlay de long-press, Pixel
Detail Screen — spec secciones 3.1, 3.2 y 9.1.

**Request:**
```json
POST /api/pixels/toggle_like/
Authorization: Bearer <access_token>
{
  "pixel_id": "123"
}
```

**Response esperada (200):**
```json
{
  "is_liked": true,
  "likes_count": 51
}
```

**Notas de implementación sugeridas (ajustables a tu criterio):**
- El servidor decide el nuevo estado (toggle real), no confía en lo que
  mande el cliente — evita condiciones de carrera con doble-tap.
- Debería ser idempotente-friendly: si el cliente reintenta por timeout de
  red, un segundo toggle no debería duplicar/perder el like (ej. usar
  `unique_together(user, pixel)` en el modelo de Like y devolver el estado
  real actual en vez de fallar).
- `likes_count` en la respuesta es la fuente de verdad — el mobile
  reconcilia su estado optimista con este valor apenas llega.

**Implementado en el mobile en:**
- `lib/services/pixel_service.dart` → `PixelService.toggleLike()`
- `lib/providers/pixel_provider.dart` → `PixelProvider.toggleLikeOptimistic()`
- `lib/screens/pixel/pixel_detail_screen.dart` → `_toggleLike()` (misma lógica, directo contra `PixelService`)
- `lib/providers/grid_provider.dart` → `GridProvider.applyOptimisticLike()` (mantiene el grid consistente)

---

## Formatos de respuesta a confirmar

Estos endpoints SÍ existen en tu lista de rutas reales, pero no tenía el
serializer exacto, así que el mobile asumió el formato más probable dado el
resto del contrato. Si difieren, es un ajuste acotado a un solo archivo cada
uno — avísame y lo dejo exacto:

| Endpoint | Archivo a ajustar si el formato difiere | Formato asumido |
|---|---|---|
| `POST /auth/login/`, `POST /auth/google/` | `lib/services/auth_service.dart` (`_parseAuthResponse`) | `{ access, refresh, user: {...} }` o `{ tokens: { access, refresh }, user: {...} }` |
| `GET /auth/me/` | `lib/models/user_model.dart` | `{ id, email, first_name, last_name, is_verified, avatar_url, pixels_count, likes_received, date_joined }` |
| `GET /pixels/grid_status/` | `lib/services/pixel_service.dart` (`getGridStatus`) | Query: `x_min,x_max,y_min,y_max` · Respuesta: lista (o `{results:[...]}`) de `{ id, x, y, image_url, owner_name, owner_message, likes_count, is_liked, comments_count, is_owner }` |
| `GET /pixels/recent_pixels/`, `GET /pixels/my_pixels/`, `GET /pixels/search_pixel/` | `lib/services/pixel_service.dart` | Misma forma de lista que `grid_status` |
| `GET /pixels/stats/` | `lib/services/pixel_service.dart` (`getStats`) | JSON libre (se muestra tal cual, sin modelo tipado aún) |
| `POST /pixels/initiate_purchase/` | `lib/models/payment_model.dart` (`PurchaseSessionModel`) | `{ session_id, x, y, currency, price? }` |
| `POST /pixels/create_payment_intent/` | `lib/models/payment_model.dart` (`PaymentIntentModel`) | `{ client_secret, payment_intent_id?, amount, currency }` |
| `POST /pixels/confirm_purchase/` | `lib/services/payment_service.dart` (`confirmPurchase`) | El píxel creado, directo o en `{ pixel: {...} }` |
| `POST /pixels/edit_pixel_content/` | `lib/services/pixel_service.dart` (`editPixelContent`) | Multipart `{ pixel_id, owner_name, owner_message, images? }` → responde el píxel actualizado |

---

*(Los próximos endpoints que falten — comentarios del Sprint 7, mensajería
del Sprint 6, etc. — se van agregando acá a medida que aparecen.)*
