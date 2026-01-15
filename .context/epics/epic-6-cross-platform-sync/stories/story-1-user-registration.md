# Story 6.1: User Registration

## Description
Admins can create user accounts directly on the database server.

## Acceptance Criteria
- [ ] Database schema supports user accounts (username, password_hash, name)
- [ ] Update User model: rename email field to username
- [ ] Admin script to create users directly in database
- [ ] Password hashing utility for script
- [ ] No signup API endpoint needed

## Technical Implementation

### Database Schema

User model with username, password_hash, and name fields. **NOTE:** The existing User model needs to be updated to change the `email` field to `username` (as the login mechanism uses username instead of email).

### Admin User Creation Script

```python
#!/usr/bin/env python3
"""
Script to create users directly in the database.
Usage: python create_user.py <username> <password> <name>
"""

import argparse
import sys
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from backend.models.shopping_list import Base, User
from backend.services.password import hash_password

def create_user(username: str, password: str, name: str, database_url: str):
    engine = create_engine(database_url)
    Session = sessionmaker(bind=engine)
    session = Session()

    try:
        # Check if user exists
        existing = session.query(User).filter(User.username == username).first()
        if existing:
            print(f"Error: User with username {username} already exists")
            return False

        # Create user
        user = User(
            username=username,
            password_hash=hash_password(password),
            name=name
        )
        session.add(user)
        session.commit()
        print(f"User created successfully: {username}")
        return True
    except Exception as e:
        session.rollback()
        print(f"Error creating user: {e}")
        return False
    finally:
        session.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Create a user in the database")
    parser.add_argument("username", help="Username")
    parser.add_argument("password", help="User password")
    parser.add_argument("name", help="User full name")
    parser.add_argument("--database-url", default="sqlite:///./test.db",
                       help="Database URL (default: sqlite:///./test.db)")

    args = parser.parse_args()
    success = create_user(args.username, args.password, args.name, args.database_url)
    sys.exit(0 if success else 1)
```

### Password Hashing Utility

Password hashing should be implemented in `backend/services/password.py`:

```python
import hashlib
import secrets

def hash_password(password: str) -> str:
    """Hash password with salt using PBKDF2"""
    salt = secrets.token_hex(32)
    pwd_hash = hashlib.pbkdf2_hmac('sha256', password.encode(), salt.encode(), 100000)
    return f"{salt}${pwd_hash.hex()}"

def verify_password(password: str, password_hash: str) -> bool:
    """Verify password against hash"""
    try:
        salt, pwd_hash = password_hash.split('$')
        new_hash = hashlib.pbkdf2_hmac('sha256', password.encode(), salt.encode(), 100000)
        return new_hash.hex() == pwd_hash
    except (ValueError, AttributeError):
        return False
```

## Dependencies
- None (foundational)

## Estimated Effort
2 story points
