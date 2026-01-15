#!/usr/bin/env python3
"""
Script to create users directly in the database.
Usage: python -m backend.scripts.create_user <username> <password> <name>
"""

import argparse
import sys
import os

# Add parent directory to path to enable imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from backend.models.user import User
from backend.auth.security import hash_password
from config import get_settings

settings = get_settings()


def create_user(username: str, password: str, name: str) -> bool:
    """Create a user in the database."""
    engine = create_engine(settings.database_url)
    Session = sessionmaker(bind=engine)
    session = Session()

    try:
        # Check if user exists
        existing = session.query(User).filter(User.username == username).first()
        if existing:
            print(f"Error: User with username '{username}' already exists")
            return False

        # Create user
        user = User(
            username=username,
            password_hash=hash_password(password),
            name=name
        )
        session.add(user)
        session.commit()
        print(f"User created successfully: {username} ({name})")
        return True
    except Exception as e:
        session.rollback()
        print(f"Error creating user: {e}")
        return False
    finally:
        session.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Create a user in the database")
    parser.add_argument("username", help="Username for login")
    parser.add_argument("password", help="User password")
    parser.add_argument("name", help="User full name")

    args = parser.parse_args()
    success = create_user(args.username, args.password, args.name)
    sys.exit(0 if success else 1)
