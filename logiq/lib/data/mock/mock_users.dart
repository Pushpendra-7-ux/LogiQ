import '../../core/constants/demo_constants.dart';
import '../../models/user.dart';

/// Seed users for the local SQLite database.
class MockUsers {
  MockUsers._();

  static final DateTime _now = DateTime.now();

  static final AppUser admin = AppUser(
    name: 'Anil Verma',
    companyName: 'LogiQ Administration',
    email: DemoConstants.demoAdminEmail,
    password: DemoConstants.demoPassword,
    role: AppUser.roleAdmin,
    phone: '9000000001',
    status: AppUser.statusApproved,
    createdAt: _now,
  );

  static final AppUser adminDemo = AppUser(
    name: 'Admin Officer',
    companyName: 'LogiQ Enterprise Portal',
    email: DemoConstants.adminDemoEmail,
    password: DemoConstants.adminDemoPassword,
    role: AppUser.roleAdmin,
    phone: '9000000099',
    status: AppUser.statusApproved,
    createdAt: _now,
  );

  static final AppUser user = AppUser(
    name: 'Rahul Sharma',
    companyName: 'Tata Steel Enterprises',
    email: DemoConstants.demoUserEmail,
    password: DemoConstants.demoPassword,
    role: AppUser.roleUser,
    phone: '9876543210',
    status: AppUser.statusApproved,
    createdAt: _now,
  );

  static final AppUser userDemo = AppUser(
    name: 'Vikram Mehta',
    companyName: '',
    email: DemoConstants.userDemoEmail,
    password: DemoConstants.userDemoPassword,
    role: AppUser.roleUser,
    phone: '9876543219',
    status: AppUser.statusApproved,
    createdAt: _now,
  );

  static final AppUser shipperDemo = AppUser(
    name: 'Vikram Mehta',
    companyName: 'Reliance Freight Hub',
    email: DemoConstants.shipperDemoEmail,
    password: DemoConstants.shipperDemoPassword,
    role: AppUser.roleUser,
    phone: '9876543219',
    status: AppUser.statusApproved,
    createdAt: _now,
  );

  static final AppUser transporterDemo = AppUser(
    name: 'Sardar Transport',
    companyName: 'Sardar Road Lines Pvt Ltd',
    email: DemoConstants.transporterDemoEmail,
    password: DemoConstants.transporterDemoPassword,
    role: AppUser.roleTransporter,
    phone: '9812345679',
    status: AppUser.statusApproved,
    createdAt: _now,
  );

  static List<AppUser> transporters() => [
        for (var i = 0; i < 7; i++)
          AppUser(
            name: ['Agarwal Fast Freight', 'BlueDart Surface Cargo', 'Safexpress Industrial',
                  'VRL Logistics Special', 'Delhivery Heavy Freight',
                  'TCI Freight Express', 'Gati KWE Bulk Line'][i],
            companyName: ['Agarwal Fast Freight Pvt Ltd', 'BlueDart Surface Cargo Co', 'Safexpress Industrial Ltd',
                  'VRL Logistics Special Div', 'Delhivery Heavy Freight Services',
                  'TCI Freight Express Fleet', 'Gati KWE Bulk Line'][i],
            email: 'transporter${i + 1}@logiq.com',
            password: DemoConstants.demoPassword,
            role: AppUser.roleTransporter,
            phone: '9812${(345670 + i).toString()}',
            status: AppUser.statusApproved,
            createdAt: _now,
          ),
      ];

  static final pendingUser = AppUser(
    name: 'Priya Nair',
    companyName: 'Nair Logistics Corp',
    email: 'priya@logiq.com',
    password: DemoConstants.demoPassword,
    role: AppUser.roleUser,
    phone: '9800000011',
    status: AppUser.statusPending,
    createdAt: _now,
  );

  static final pendingTransporter = AppUser(
    name: 'Vardhman Carriers',
    companyName: 'Vardhman Carriers Fleet',
    email: 'transporter8@logiq.com',
    password: DemoConstants.demoPassword,
    role: AppUser.roleTransporter,
    phone: '9800000012',
    status: AppUser.statusPending,
    createdAt: _now,
  );

  static final rejectedUser = AppUser(
    name: 'Suresh Singhania',
    companyName: 'Singhania Metal Freight',
    email: 'rejected.shipper@logiq.demo',
    password: DemoConstants.demoPassword,
    role: AppUser.roleUser,
    phone: '9800000099',
    status: AppUser.statusRejected,
    rejectionReason: 'Invalid GST identification number and unverified business address.',
    createdAt: _now,
  );

  static final rejectedTransporter = AppUser(
    name: 'Kailash Roadways',
    companyName: 'Kailash Roadways Fleet',
    email: 'rejected.transporter@logiq.demo',
    password: DemoConstants.demoPassword,
    role: AppUser.roleTransporter,
    phone: '9800000098',
    status: AppUser.statusRejected,
    rejectionReason: 'Vehicle fitness certificates expired and missing national permit.',
    createdAt: _now,
  );
}
