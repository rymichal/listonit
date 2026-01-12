# Story 6.1: User Registration

## Description
Users can create accounts.

## Acceptance Criteria
- [ ] Email + password registration
- [ ] Password requirements: 8+ chars, mixed case, number
- [ ] Email verification required
- [ ] Welcome email with tips
- [ ] Import local data after signup

## Technical Implementation

### FastAPI Endpoint

```python
@router.post("/api/v1/auth/register")
async def register(
    data: RegisterRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    # Validate email format
    if not is_valid_email(data.email):
        raise HTTPException(400, "Invalid email format")

    # Check if email exists
    if db.query(User).filter(User.email == data.email).first():
        raise HTTPException(400, "Email already registered")

    # Validate password
    if not is_strong_password(data.password):
        raise HTTPException(400, "Password must be 8+ chars with mixed case and numbers")

    # Create user
    user = User(
        email=data.email,
        password_hash=hash_password(data.password),
        name=data.name or data.email.split('@')[0]
    )
    db.add(user)
    db.commit()

    # Send verification email
    token = create_email_token(user.id, expires_in=24*60)
    background_tasks.add_task(
        send_verification_email, user.email, token
    )

    return {
        "user_id": str(user.id),
        "email": user.email,
        "message": "Verification email sent"
    }

@router.post("/api/v1/auth/verify-email")
async def verify_email(
    token: str,
    db: Session = Depends(get_db)
):
    user_id = verify_email_token(token)
    if not user_id:
        raise HTTPException(400, "Invalid or expired token")

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(404, "User not found")

    user.email_verified = True
    db.commit()

    return {"success": True}
```

### Flutter Implementation

```dart
class AuthService {
  final ApiClient _apiClient;

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/auth/register',
        data: {
          'email': email,
          'password': password,
          'name': name,
        },
      );

      return AuthResponse.fromJson(response.data);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  Future<bool> verifyEmail(String token) async {
    try {
      await _apiClient.post(
        '/api/v1/auth/verify-email',
        data: {'token': token},
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}
```

## Dependencies
- None (foundational)

## Estimated Effort
5 story points
