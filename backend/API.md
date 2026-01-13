# Listonit API Documentation

Base URL: `http://localhost:8000/api/v1`

## Lists Endpoints

### Create List

Creates a new shopping list for the current user.

- **URL:** `/lists`
- **Method:** `POST`
- **Auth:** Required (currently uses mock user)

**Request Body:**
```json
{
  "name": "Groceries",
  "color": "#4CAF50",
  "icon": "shopping_cart"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| name | string | Yes | List name (1-100 characters) |
| color | string | No | Hex color code (default: `#4CAF50`) |
| icon | string | No | Icon name (default: `shopping_cart`) |

**Response:** `201 Created`
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "owner_id": "00000000-0000-0000-0000-000000000001",
  "name": "Groceries",
  "color": "#4CAF50",
  "icon": "shopping_cart",
  "is_archived": false,
  "created_at": "2026-01-12T18:30:00.000000",
  "updated_at": "2026-01-12T18:30:00.000000"
}
```

**Example:**
```bash
curl -X POST http://localhost:8000/api/v1/lists \
  -H "Content-Type: application/json" \
  -d '{"name": "Groceries", "color": "#4CAF50", "icon": "shopping_cart"}'
```

---

### Get All Lists

Returns all shopping lists for the current user.

- **URL:** `/lists`
- **Method:** `GET`
- **Auth:** Required (currently uses mock user)

**Response:** `200 OK`
```json
[
  {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "owner_id": "00000000-0000-0000-0000-000000000001",
    "name": "Groceries",
    "color": "#4CAF50",
    "icon": "shopping_cart",
    "is_archived": false,
    "created_at": "2026-01-12T18:30:00.000000",
    "updated_at": "2026-01-12T18:30:00.000000"
  },
  {
    "id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
    "owner_id": "00000000-0000-0000-0000-000000000001",
    "name": "Hardware Store",
    "color": "#FF9800",
    "icon": "build",
    "is_archived": false,
    "created_at": "2026-01-12T17:00:00.000000",
    "updated_at": "2026-01-12T17:00:00.000000"
  }
]
```

**Example:**
```bash
curl http://localhost:8000/api/v1/lists
```

---

### Get Single List

Returns a specific shopping list by ID.

- **URL:** `/lists/{list_id}`
- **Method:** `GET`
- **Auth:** Required (currently uses mock user)

**URL Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| list_id | string (UUID) | The list's unique identifier |

**Response:** `200 OK`
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "owner_id": "00000000-0000-0000-0000-000000000001",
  "name": "Groceries",
  "color": "#4CAF50",
  "icon": "shopping_cart",
  "is_archived": false,
  "created_at": "2026-01-12T18:30:00.000000",
  "updated_at": "2026-01-12T18:30:00.000000"
}
```

**Error Responses:**
- `404 Not Found` - List does not exist
- `403 Forbidden` - User doesn't have access to this list

**Example:**
```bash
curl http://localhost:8000/api/v1/lists/a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

---

### Update List

Updates a shopping list's properties.

- **URL:** `/lists/{list_id}`
- **Method:** `PATCH`
- **Auth:** Required (currently uses mock user)

**URL Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| list_id | string (UUID) | The list's unique identifier |

**Request Body:**
```json
{
  "name": "Weekly Groceries",
  "color": "#2196F3",
  "icon": "local_grocery_store",
  "is_archived": false
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| name | string | No | List name (1-100 characters) |
| color | string | No | Hex color code |
| icon | string | No | Icon name |
| is_archived | boolean | No | Archive status |

**Response:** `200 OK`
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "owner_id": "00000000-0000-0000-0000-000000000001",
  "name": "Weekly Groceries",
  "color": "#2196F3",
  "icon": "local_grocery_store",
  "is_archived": false,
  "created_at": "2026-01-12T18:30:00.000000",
  "updated_at": "2026-01-12T19:00:00.000000"
}
```

**Error Responses:**
- `404 Not Found` - List does not exist
- `403 Forbidden` - User doesn't have permission to edit

**Example:**
```bash
curl -X PATCH http://localhost:8000/api/v1/lists/a1b2c3d4-e5f6-7890-abcd-ef1234567890 \
  -H "Content-Type: application/json" \
  -d '{"name": "Weekly Groceries", "color": "#2196F3"}'
```

---

### Delete List

Permanently deletes a shopping list.

- **URL:** `/lists/{list_id}`
- **Method:** `DELETE`
- **Auth:** Required (currently uses mock user)

**URL Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| list_id | string (UUID) | The list's unique identifier |

**Response:** `204 No Content`

**Error Responses:**
- `404 Not Found` - List does not exist
- `403 Forbidden` - Only the owner can delete a list

**Example:**
```bash
curl -X DELETE http://localhost:8000/api/v1/lists/a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

---

## Available Icons

```
shopping_cart, shopping_bag, store, local_grocery_store, restaurant,
fastfood, local_cafe, local_bar, cake, icecream, home, cleaning_services,
pets, child_care, checkroom, medical_services, fitness_center, spa,
build, card_giftcard
```

## Available Colors

```
#4CAF50 (Green)     #2196F3 (Blue)      #F44336 (Red)
#FF9800 (Orange)    #9C27B0 (Purple)    #00BCD4 (Cyan)
#E91E63 (Pink)      #795548 (Brown)     #607D8B (Blue Grey)
#FFEB3B (Yellow)    #3F51B5 (Indigo)    #009688 (Teal)
```

## Health Check

- **URL:** `/` (root, not under /api/v1)
- **Method:** `GET`

**Response:** `200 OK`
```json
{
  "status": "healthy",
  "app": "Listonit API"
}
```
