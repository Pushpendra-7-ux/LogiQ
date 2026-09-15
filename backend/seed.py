from datetime import datetime, timedelta, date
from database import SessionLocal, create_tables
from models.user import User, TransporterProfile
from models.tender import Tender, Material, TenderParticipant
from models.auction import Auction
from utils.security import hash_password

def seed_database():
    create_tables()
    db = SessionLocal()

    # Check if admin already exists
    admin = db.query(User).filter(User.email == "admin@logiq.com").first()
    if admin:
        print("Database already seeded.")
        db.close()
        return

    print("Seeding database with demo users and active tender...")

    # 1. Admin
    admin_user = User(
        name="Admin User",
        email="admin@logiq.com",
        phone="9999999999",
        password_hash=hash_password("admin123"),
        role="admin",
        status="approved"
    )
    db.add(admin_user)

    # 2. User (Tender Maker)
    tender_maker = User(
        name="Rahul Sharma",
        email="user@logiq.com",
        phone="9876543210",
        password_hash=hash_password("user123"),
        role="user",
        status="approved"
    )
    db.add(tender_maker)
    db.commit()
    db.refresh(tender_maker)

    # 3. 10 Transporters
    transporters_data = [
        ("ABC Transport", "transport1@logiq.com", "22AAAAA0000A1Z5", "TN-00001"),
        ("XYZ Logistics", "transport2@logiq.com", "22BBBBB0000B1Z5", "TN-00002"),
        ("PQR Transport", "transport3@logiq.com", "22CCCCC0000C1Z5", "TN-00003"),
        ("FastMove Logistics", "transport4@logiq.com", "22DDDDD0000D1Z5", "TN-00004"),
        ("QuickHaul Transport", "transport5@logiq.com", "22EEEEE0000E1Z5", "TN-00005"),
        ("SpeedLine Cargo", "transport6@logiq.com", "22FFFFF0000F1Z5", "TN-00006"),
        ("SafeMove Transport", "transport7@logiq.com", "22GGGGG0000G1Z5", "TN-00007"),
        ("RoadKing Logistics", "transport8@logiq.com", "22HHHHH0000H1Z5", "TN-00008"),
        ("TruckStar Transport", "transport9@logiq.com", "22IIIII0000I1Z5", "TN-00009"),
        ("CargoExpress", "transport10@logiq.com", "22JJJJJ0000J1Z5", "TN-00010"),
    ]

    created_transporters = []
    for comp_name, email, gst, tid in transporters_data:
        t_user = User(
            name=comp_name,
            email=email,
            phone="9812345678",
            password_hash=hash_password("transport123"),
            role="transporter",
            status="approved"
        )
        db.add(t_user)
        db.commit()
        db.refresh(t_user)

        profile = TransporterProfile(
            user_id=t_user.id,
            company_name=comp_name,
            company_email=email,
            whatsapp_phone="9812345678",
            gst_number=gst,
            transport_id=tid
        )
        db.add(profile)
        created_transporters.append(t_user)
    
    db.commit()

    # 4. Demo Tender: Steel Transport Gwalior -> Raipur
    now = datetime.utcnow()
    demo_tender = Tender(
        creator_id=tender_maker.id,
        title="Steel Transport",
        pickup_location="Gwalior",
        drop_location="Raipur",
        delivery_start=date.today() + timedelta(days=3),
        delivery_end=date.today() + timedelta(days=5),
        tender_closing_date=now + timedelta(days=2),
        bidding_start_time=now,
        soft_end_time=now + timedelta(minutes=30),
        hard_stop_time=now + timedelta(hours=1),
        price_difference=25.0,
        status="STAGE_1_LIVE"
    )
    db.add(demo_tender)
    db.commit()
    db.refresh(demo_tender)

    # Add Material
    material = Material(
        tender_id=demo_tender.id,
        hsn_code="7208",
        description="Hot Rolled Steel Sheets",
        quantity=25.0,
        unit="MT",
        remarks="Handle with industrial safety straps"
    )
    db.add(material)

    # Add all 10 transporters as invited participants
    for t in created_transporters:
        participant = TenderParticipant(
            tender_id=demo_tender.id,
            transporter_id=t.id,
            status="stage1"
        )
        db.add(participant)

    # Create Stage 1 Auction in LIVE state
    auction = Auction(
        tender_id=demo_tender.id,
        stage=1,
        status="LIVE",
        start_time=now,
        soft_end_time=now + timedelta(minutes=30),
        hard_stop_time=now + timedelta(hours=1),
        extension_minutes=5
    )
    db.add(auction)
    db.commit()

    print("✓ Seeding complete!")
    print(f"  Admin: admin@logiq.com / admin123")
    print(f"  User: user@logiq.com / user123")
    print(f"  Transporters (10): transport1@logiq.com through transport10@logiq.com / transport123")
    print(f"  Demo Tender ID: {demo_tender.id} (Status: STAGE_1_LIVE)")
    db.close()

if __name__ == "__main__":
    seed_database()
