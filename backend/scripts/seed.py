"""
Database seeding script for initial admin user.

Run with: cd backend && uv run python scripts/seed.py
"""

import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from auth.security import hash_password
from database import SessionLocal
from models import User


def seed_admin():
    """Create the initial admin user if it doesn't exist."""
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
            print("Admin user created successfully")
            print(f"  Email: admin@listonit.app")
            print(f"  Password: password1")
        else:
            print("Admin user already exists")
    finally:
        db.close()


if __name__ == "__main__":
    seed_admin()
