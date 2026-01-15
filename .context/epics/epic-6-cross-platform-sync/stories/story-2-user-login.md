# Story 6.2: User Login

## Description
Users can sign into their accounts.

## Acceptance Criteria
- [ ] Username + password login
- [ ] Token-based authentication (JWT)

## Technical Implementation

### FastAPI Endpoints

```python
@router.post("/api/v1/auth/login")
async def login(
    credentials: LoginRequest,
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(User.username == credentials.username).first()
    if not user or not verify_password(credentials.password, user.password_hash):
        raise HTTPException(401, "Invalid credentials")

    # Create tokens
    access_token = create_access_token(user.id)
    refresh_token = create_refresh_token(user.id)

    return {
        "user": UserResponse.from_orm(user),
        "access_token": access_token,
        "refresh_token": refresh_token,
        "expires_in": ACCESS_TOKEN_EXPIRE_MINUTES * 60
    }

@router.post("/api/v1/auth/refresh")
async def refresh_token(
    data: RefreshRequest,
    db: Session = Depends(get_db)
):
    user_id = verify_refresh_token(data.refresh_token)
    if not user_id:
        raise HTTPException(401, "Invalid refresh token")

    access_token = create_access_token(user_id)

    return {
        "access_token": access_token,
        "expires_in": ACCESS_TOKEN_EXPIRE_MINUTES * 60
    }
```

### Flutter Implementation

```dart
class AuthService {
  Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      final auth = AuthResponse.fromJson(response.data);

      // Save tokens
      await _secureStorage.saveTokens(
        accessToken: auth.accessToken,
        refreshToken: auth.refreshToken,
      );

      return auth;
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  Future<AuthResponse> refreshAccessToken(String refreshToken) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final auth = AuthResponse.fromJson(response.data);

      // Save new access token
      await _secureStorage.updateAccessToken(auth.accessToken);

      return auth;
    } catch (e) {
      throw AuthException(e.toString());
    }
  }
}
```

## Dependencies
- Story 6.1 (User Registration)

## Estimated Effort
3 story points
