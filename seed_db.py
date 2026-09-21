import os
import hashlib

from database import engine, User, Session
from sqlmodel import select

def seed_admin():
    admin_email = os.getenv("SEED_ADMIN_EMAIL")
    admin_password = os.getenv("SEED_ADMIN_PASSWORD")
    if not admin_email or not admin_password:
        raise RuntimeError("Set SEED_ADMIN_EMAIL and SEED_ADMIN_PASSWORD before seeding an admin")
    if len(admin_password) < 12:
        raise ValueError("SEED_ADMIN_PASSWORD must contain at least 12 characters")

    with Session(engine) as session:
        statement = select(User).where(User.email == admin_email)
        existing_admin = session.exec(statement).first()
        
        if not existing_admin:
            admin = User(
                email=admin_email,
                password=hashlib.sha256(admin_password.encode()).hexdigest(),
                name="System Admin",
                role="Admin"
            )
            session.add(admin)
            session.commit()
            print(f"Admin user created: {admin_email}")
        else:
            print("Admin user already exists.")

if __name__ == "__main__":
    seed_admin()
