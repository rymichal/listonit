"""
Database seeding script for initial users.

Run with: cd backend && uv run python scripts/seed.py
"""

import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from auth.security import hash_password
from database import SessionLocal
from models import User


def seed_users():
    """Create initial users if they don't exist."""
    db = SessionLocal()
    try:
        users_to_create = [
            {
                "username": "ryan",
                "name": "Ryan Michal",
                "password": "asdfasdf",
                "is_admin": True,
            },
            {
                "username": "hanna",
                "name": "Hanna",
                "password": "asdfasdf",
                "is_admin": False,
            },
        ]

        for user_data in users_to_create:
            existing = db.query(User).filter(User.username == user_data["username"]).first()
            if not existing:
                user = User(
                    username=user_data["username"],
                    name=user_data["name"],
                    password_hash=hash_password(user_data["password"]),
                    is_admin=user_data["is_admin"],
                    is_active=True,
                )
                db.add(user)
                db.commit()
                print(f"User created: {user_data['username']}")
                print(f"  Name: {user_data['name']}")
                print(f"  Password: {user_data['password']}")
            else:
                print(f"User already exists: {user_data['username']}")
    finally:
        db.close()


if __name__ == "__main__":
    seed_users()
