#!/usr/bin/env python3
"""Seed users via docker exec. Run from project root."""

import subprocess
import sys

# Get password hash from backend container
result = subprocess.run(
    ["docker", "exec", "listonit-backend", "python", "-c",
     "from auth.security import hash_password; print(hash_password('asdfasdf'))"],
    capture_output=True, text=True
)

if result.returncode != 0:
    print(f"Error generating hash: {result.stderr}")
    sys.exit(1)

password_hash = result.stdout.strip().replace("$", "\\$")

# Insert users
sql = f"""
INSERT INTO users (id, username, name, password_hash, is_active, is_admin, created_at, updated_at)
VALUES
  (gen_random_uuid(), 'ryan', 'Ryan Michal', '{password_hash}', true, true, NOW(), NOW()),
  (gen_random_uuid(), 'hanna', 'Hanna', '{password_hash}', true, false, NOW(), NOW())
ON CONFLICT (username) DO NOTHING;
"""

result = subprocess.run(
    ["docker", "exec", "listonit-postgres", "psql", "-U", "listonit", "-d", "listonit", "-c", sql],
    capture_output=True, text=True
)

if result.returncode != 0:
    print(f"Error seeding users: {result.stderr}")
    sys.exit(1)

print("Users seeded:")
print("  ryan / asdfasdf (admin)")
print("  hanna / asdfasdf")
