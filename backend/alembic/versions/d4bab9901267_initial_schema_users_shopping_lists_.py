"""Initial schema: users, shopping_lists, list_members, items

Revision ID: d4bab9901267
Revises: 
Create Date: 2026-01-16 12:34:00.323520

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd4bab9901267'
down_revision: Union[str, Sequence[str], None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_table(
        'users',
        sa.Column('id', sa.String(36), primary_key=True),
        sa.Column('username', sa.String(255), unique=True, index=True, nullable=False),
        sa.Column('name', sa.String(100), nullable=False),
        sa.Column('password_hash', sa.String(255), nullable=False),
        sa.Column('is_active', sa.Boolean(), default=True, nullable=False),
        sa.Column('is_admin', sa.Boolean(), default=False, nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
    )

    op.create_table(
        'shopping_lists',
        sa.Column('id', sa.String(36), primary_key=True),
        sa.Column('owner_id', sa.String(36), sa.ForeignKey('users.id'), index=True, nullable=False),
        sa.Column('name', sa.String(100), nullable=False),
        sa.Column('color', sa.String(7), default='#4CAF50', nullable=False),
        sa.Column('icon', sa.String(50), default='shopping_cart', nullable=False),
        sa.Column('is_archived', sa.Boolean(), default=False, nullable=False),
        sa.Column('sort_mode', sa.String(20), default='chronological', nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
    )

    op.create_table(
        'list_members',
        sa.Column('id', sa.String(36), primary_key=True),
        sa.Column('list_id', sa.String(36), sa.ForeignKey('shopping_lists.id'), index=True, nullable=False),
        sa.Column('user_id', sa.String(36), sa.ForeignKey('users.id'), index=True, nullable=False),
        sa.Column('role', sa.Enum('owner', 'editor', 'viewer', name='memberrole'), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
    )

    op.create_table(
        'items',
        sa.Column('id', sa.String(36), primary_key=True),
        sa.Column('list_id', sa.String(36), sa.ForeignKey('shopping_lists.id', ondelete='CASCADE'), index=True, nullable=False),
        sa.Column('name', sa.String(200), nullable=False),
        sa.Column('quantity', sa.Integer(), default=1, nullable=False),
        sa.Column('unit', sa.String(20), nullable=True),
        sa.Column('note', sa.Text(), nullable=True),
        sa.Column('is_checked', sa.Boolean(), default=False, nullable=False),
        sa.Column('checked_at', sa.DateTime(), nullable=True),
        sa.Column('checked_by', sa.String(36), sa.ForeignKey('users.id'), nullable=True),
        sa.Column('sort_index', sa.Integer(), default=0, nullable=False),
        sa.Column('created_by', sa.String(36), sa.ForeignKey('users.id'), index=True, nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_table('items')
    op.drop_table('list_members')
    op.drop_table('shopping_lists')
    op.drop_table('users')
    op.execute('DROP TYPE IF EXISTS memberrole')
