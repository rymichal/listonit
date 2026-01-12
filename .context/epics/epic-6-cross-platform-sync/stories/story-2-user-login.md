# Story 6.2: User Login

## Description
Users can sign into their accounts.

## Acceptance Criteria
- [ ] Email + password login
- [ ] "Remember me" option
- [ ] Forgot password flow
- [ ] Social login: Google, Apple Sign In
- [ ] Biometric unlock (after first login)

## Technical Implementation

### FastAPI Endpoints

```python
@router.post("/api/v1/auth/login")
async def login(
    credentials: LoginRequest,
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(User.email == credentials.email).first()
    if not user or not verify_password(credentials.password, user.password_hash):
        raise HTTPException(401, "Invalid credentials")

    if not user.email_verified:
        raise HTTPException(403, "Email not verified")

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

@router.post("/api/v1/auth/forgot-password")
async def forgot_password(
    data: ForgotPasswordRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(User.email == data.email).first()
    if not user:
        # Don't reveal if email exists
        return {"message": "If email exists, reset link sent"}

    reset_token = create_reset_token(user.id, expires_in=60)
    background_tasks.add_task(
        send_reset_email, user.email, reset_token
    )

    return {"message": "Reset link sent to email"}

@router.post("/api/v1/auth/reset-password")
async def reset_password(
    data: ResetPasswordRequest,
    db: Session = Depends(get_db)
):
    user_id = verify_reset_token(data.token)
    if not user_id:
        raise HTTPException(400, "Invalid or expired token")

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(404, "User not found")

    user.password_hash = hash_password(data.new_password)
    db.commit()

    return {"success": True}
```

### Flutter Implementation

```dart
class AuthService {
  Future<AuthResponse> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final auth = AuthResponse.fromJson(response.data);

      // Save tokens
      await _secureStorage.saveTokens(
        accessToken: auth.accessToken,
        refreshToken: auth.refreshToken,
      );

      // Save login if remember me
      if (rememberMe) {
        await _secureStorage.saveEmail(email);
      }

      // Setup biometric if available
      await _setupBiometric();

      return auth;
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  Future<void> _setupBiometric() async {
    try {
      final isAvailable = await LocalAuthentication().canCheckBiometrics;
      if (isAvailable) {
        await _secureStorage.enableBiometric(true);
      }
    } catch (e) {
      // Biometric not available
    }
  }

  Future<void> forgotPassword(String email) async {
    await _apiClient.post(
      '/api/v1/auth/forgot-password',
      data: {'email': email},
    );
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _apiClient.post(
      '/api/v1/auth/reset-password',
      data: {
        'token': token,
        'new_password': newPassword,
      },
    );
  }
}
```

## Dependencies
- Story 6.1 (User Registration)

## Estimated Effort
6 story points
