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

## ⏳ WebSocket de mensajería (tiempo real)

**Estado:** no confirmado. No vi protocolo de WebSocket en tu lista de
rutas (que son todas REST). El chat **funciona igual sin esto** — está
armado 100% sobre REST (`GET/POST /pixels/share_pixel/`); el WebSocket es
un "plus" para que los mensajes lleguen sin refrescar. Si no existe o
falla la conexión, la app no se rompe, solo no hay tiempo real (falla en
silencio y reintenta).

**Usado por:** Chat List / Chat Detail — spec sección 6.

**Contrato propuesto:**
```
Conexión:  wss://tu-dominio.com/ws  (Socket.IO)
Auth:      handshake con { auth: { token: <access_token> } }

Cliente -> Servidor:
  join_pixel_chat   { pixel_id }
  leave_pixel_chat  { pixel_id }

Servidor -> Cliente:
  new_message       { id, pixel_id, sender_id, sender_name, message, is_private, created_at }
```

**Implementado en el mobile en:**
- `lib/services/websocket_service.dart` (usa `socket_io_client`)
- `lib/providers/chat_provider.dart` → `configure()`, `openChat()`, `closeChat()`

---

## ⏳ Editar perfil

**Estado:** no confirmado — no había ruta de "actualizar perfil" en tu
lista (solo `GET /auth/me/`). En vez de inventar una ruta nueva, propongo
extender el método sobre esa misma ruta (patrón común en DRF con
`RetrieveUpdateAPIView`):

```
PATCH /api/auth/me/
Body:     { "first_name": "...", "last_name": "..." }
Response: el usuario actualizado, mismo formato que GET /auth/me/
```

Si prefieres una ruta separada (ej. `POST /auth/update-profile/`), es un
cambio de una línea en `lib/services/auth_service.dart` (`updateProfile`).

**Implementado en el mobile en:**
- `lib/services/auth_service.dart` → `updateProfile()`
- `lib/providers/auth_provider.dart` → `updateProfile()`
- `lib/screens/settings/profile_edit_screen.dart`

**Pendiente aparte:** subida de foto de perfil (botón "Cambiar foto" en
Profile Edit) — no hay endpoint para eso tampoco, el botón hoy solo
muestra un aviso. Cuando definas cómo subir el avatar (multipart en el
mismo PATCH, o endpoint separado), lo conecto.

---

## ⏳ Registro de dispositivo para push (FCM)

**Estado:** no confirmado — necesario para notificaciones push (spec
12.1). Además, esto requiere que configures Firebase de tu lado (ver
`lib/services/notification_service.dart` para los pasos exactos:
`flutter create .`, crear proyecto en Firebase Console, `flutterfire configure`).

```
POST /api/auth/register_device/
Body: { "fcm_token": "<token>", "platform": "ios" | "android" }
Auth: requerido (Bearer token)
```

**Implementado en el mobile en:**
- `lib/services/notification_service.dart` → `_registerDeviceToken()`
  (falla en silencio si el endpoint no existe todavía — no rompe nada)

---

## ⏳ Comentarios públicos

**Estado:** no confirmado — mismo caso que el like, no vi endpoint de
comentarios en tu lista de rutas reales.

```
GET  /api/pixels/pixel_comments/?pixel_id=<id>
Response: [ { id, pixel_id, author_id, author_name, message, created_at }, ... ]

POST /api/pixels/pixel_comments/
Body: { "pixel_id": "<id>", "message": "<texto>" }
Response: el comentario creado, mismo formato que el GET
Auth: requerido (Bearer token)
```

**Usado por:** `PixelCommentsWidget` en Pixel Detail Screen (listado +
input para agregar). Si el endpoint no existe todavía, esta sección
muestra un error no intrusivo con botón "Reintentar" sin romper el resto
de la pantalla (imagen, stats, acciones siguen funcionando igual).

**Implementado en el mobile en:**
- `lib/models/comment_model.dart`
- `lib/services/pixel_service.dart` → `getComments()`, `addComment()`
- `lib/widgets/pixel/pixel_comments_widget.dart`

**Nota de diseño:** "Responder privadamente" en cada comentario abre el
chat 1:1 sobre ese píxel (Sprint 6) — como el sistema de mensajería solo
tiene un hilo por píxel (no uno por par de usuarios), es una aproximación
razonable en vez de una conversación aislada por comentario. Si tu backend
maneja hilos por usuario, avísame y ajustamos.

---

## Uso asumido de `GET/POST /pixels/share_pixel/` para el chat

Este SÍ existe en tu lista, pero solo hay un endpoint para todo el sistema
de mensajería (no uno separado para "lista de chats" vs "mensajes de una
conversación"). Asumí:

```
GET  /api/pixels/share_pixel/                -> lista de conversaciones (Chat List)
GET  /api/pixels/share_pixel/?pixel_id=<id>  -> mensajes de esa conversación (Chat Detail)
POST /api/pixels/share_pixel/                -> enviar mensaje
     Body: { "pixel_id": "<id>", "message": "<texto>", "is_private": <bool> }
```

**Archivo a ajustar si el formato real difiere:** `lib/services/pixel_service.dart`
(`getChatList`, `getMessages`, `sendMessage`) y `lib/models/message_model.dart`
(`ChatSummaryModel.fromJson`, `MessageModel.fromJson`).

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
| `GET/POST /pixels/share_pixel/` | `lib/services/pixel_service.dart` (`getChatList`, `getMessages`, `sendMessage`) + `lib/models/message_model.dart` | Ver sección dedicada arriba |

---

*(Los próximos endpoints que falten — comentarios del Sprint 7, mensajería
del Sprint 6, etc. — se van agregando acá a medida que aparecen.)*
