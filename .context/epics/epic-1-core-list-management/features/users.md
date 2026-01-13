# JWT Authentication Implementation

## Overview

Add JWT-based authentication to the ListOnIt full-stack app (FastAPI backend + Flutter client).

---

## Backend (FastAPI)

### 1. Configuration

Add JWT settings to `config.py`:
- `jwt_secret_key` - Secret for signing tokens (generate with `openssl rand -hex 32`)
- `jwt_algorithm` - Algorithm (default: HS256)
- `access_token_expire_minutes` - Token expiry (default: 30)
- `refresh_token_expire_days` - Refresh token expiry (default: 7)

### 2. Auth Module

Create `auth/` directory with:

**`auth/security.py`**
- `hash_password(password)` - Hash passwords using passlib/bcrypt
- `verify_password(plain, hashed)` - Verify password against hash
- `create_access_token(data, expires_delta)` - Generate JWT access token
- `create_refresh_token(data)` - Generate longer-lived refresh token
- `decode_token(token)` - Decode and validate JWT

**`auth/dependencies.py`**
- `get_current_user(token)` - FastAPI dependency that:
  - Extracts Bearer token from Authorization header
  - Decodes and validates JWT
  - Returns User from database
  - Raises 401 if invalid/expired

### 3. Auth Endpoints

Create `api/v1/auth.py`:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/auth/register` | POST | Create new user account |
| `/api/v1/auth/login` | POST | Authenticate, return tokens |
| `/api/v1/auth/refresh` | POST | Exchange refresh token for new access token |
| `/api/v1/auth/me` | GET | Get current user profile |

### 4. Update User Model

Add fields to `User` model:
- `password_hash: str` - Hashed password
- `is_active: bool` - Account status
- `created_at: datetime`
- `updated_at: datetime`

### 5. Protect Routes

Replace mock user dependency with `get_current_user`:
```python
# Before
def get_current_user_id() -> str:
    return settings.mock_user_id

# After
async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
) -> User:
    # Validate token and return user
```

---

## Client (Flutter)

### 1. Auth Service

Create `lib/services/auth_service.dart`:
- `register(email, password, name)` - Create account
- `login(email, password)` - Authenticate user
- `logout()` - Clear stored tokens
- `refreshToken()` - Get new access token
- `isAuthenticated` - Check auth status

### 2. Token Storage

Use `flutter_secure_storage` package:
- Store access token securely
- Store refresh token securely
- Clear on logout

### 3. HTTP Interceptor

Add auth interceptor to API client:
- Attach `Authorization: Bearer <token>` header to requests
- Intercept 401 responses
- Attempt token refresh on 401
- Redirect to login if refresh fails

### 4. Auth State Management

Using chosen state management (Provider/Riverpod/Bloc):
- `AuthState` - Track authentication status
- `AuthNotifier` - Handle auth actions
- Expose `currentUser`, `isAuthenticated`, `isLoading`

### 5. Auth UI

Create screens:
- `LoginScreen` - Email/password login form
- `RegisterScreen` - Registration form with validation
- `SplashScreen` - Check auth state on app launch

### 6. Route Guards

Protect authenticated routes:
- Redirect to login if not authenticated
- Redirect to home if authenticated user visits login

---

## Implementation Order

1. Backend: Add JWT config and security utilities
2. Backend: Create auth endpoints (register, login, refresh)
3. Backend: Add `get_current_user` dependency
4. Backend: Protect existing routes with auth
5. Client: Add secure token storage
6. Client: Create auth service
7. Client: Add HTTP interceptor
8. Client: Build login/register screens
9. Client: Add route guards
10. Remove mock user fallback

---

## Database Seeding

### Admin User Seed

Create an initial admin user during first database setup.

**Seed Data:**
| Field | Value |
|-------|-------|
| email | `admin@listonit.app` |
| name | `Admin` |
| password | `password1` |
| is_admin | `true` |
| is_active | `true` |

### Implementation

**`scripts/seed.py`**
```python
from auth.security import hash_password
from models import User
from database import SessionLocal

def seed_admin():
    db = SessionLocal()
    try:
        existing = db.query(User).filter(User.email == "admin@listonit.app").first()
        if not existing:
            admin = User(
                email="admin@listonit.app",
                name="Admin",
                password_hash=hash_password("password1"),
                is_admin=True,
                is_active=True,
            )
            db.add(admin)
            db.commit()
            print("Admin user created")
        else:
            print("Admin user already exists")
    finally:
        db.close()

if __name__ == "__main__":
    seed_admin()
```

### Running the Seed

```bash
cd backend && uv run python scripts/seed.py
```

### User Model Update

Add `is_admin` field to User model:
```python
is_admin: Mapped[bool] = mapped_column(default=False)
```

### Notes

- Only seed in development/staging environments
- Change admin password immediately in production
- Consider using environment variables for seed credentials in CI/CD

---

## Security Considerations

- Use HTTPS in production
- Store JWT secret in environment variables
- Use short-lived access tokens (15-30 min)
- Implement refresh token rotation
- Add rate limiting to auth endpoints
- Validate email format and password strength
- Consider adding email verification

