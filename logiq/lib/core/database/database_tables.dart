class DatabaseTables {
  DatabaseTables._();

  static const users = 'users';
  static const transporters = 'transporters';
  static const tenders = 'tenders';
  static const materials = 'materials';
  static const tenderParticipants = 'tender_participants';
  static const auctions = 'auctions';
  static const bids = 'bids';
  static const auctionParticipants = 'auction_participants';
  static const auctionResults = 'auction_results';

  static const List<String> createStatements = [
    '''
    CREATE TABLE $users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      company_name TEXT DEFAULT '',
      email TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      role TEXT NOT NULL,
      phone TEXT DEFAULT '',
      status TEXT NOT NULL DEFAULT 'pending',
      rejection_reason TEXT DEFAULT '',
      is_approved INTEGER DEFAULT 1,
      created_at TEXT NOT NULL
    )''',
    '''
    CREATE TABLE $transporters (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      company_name TEXT NOT NULL,
      gstin TEXT DEFAULT '',
      vahan_transport_id TEXT DEFAULT '',
      is_approved INTEGER DEFAULT 1
    )''',
    '''
    CREATE TABLE $tenders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      created_by INTEGER NOT NULL,
      delivery_from TEXT NOT NULL,
      delivery_to TEXT NOT NULL,
      delivery_start TEXT NOT NULL,
      delivery_end TEXT NOT NULL,
      closing_date TEXT NOT NULL,
      bidding_start TEXT NOT NULL,
      soft_end TEXT NOT NULL,
      hard_stop TEXT NOT NULL,
      price_difference REAL NOT NULL DEFAULT 25.0,
      ceiling_bid REAL NOT NULL DEFAULT 75000.0,
      min_decrement REAL NOT NULL DEFAULT 500.0,
      remarks TEXT DEFAULT '',
      vehicle_type TEXT DEFAULT 'Truck',
      publish_at TEXT,
      status TEXT NOT NULL DEFAULT 'draft',
      created_at TEXT NOT NULL
    )''',
    '''
    CREATE TABLE $materials (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      tender_id INTEGER NOT NULL,
      hsn_code TEXT DEFAULT '',
      description TEXT NOT NULL,
      quantity REAL NOT NULL,
      unit TEXT NOT NULL,
      remarks TEXT DEFAULT ''
    )''',
    '''
    CREATE TABLE $tenderParticipants (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      tender_id INTEGER NOT NULL,
      transporter_id INTEGER NOT NULL
    )''',
    '''
    CREATE TABLE $auctions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      tender_id INTEGER NOT NULL,
      current_stage INTEGER NOT NULL DEFAULT 0,
      stage1_start TEXT NOT NULL,
      stage1_end TEXT NOT NULL,
      stage2_start TEXT NOT NULL,
      stage2_end TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'scheduled',
      winner_transporter_id INTEGER,
      final_price REAL
    )''',
    '''
    CREATE TABLE $bids (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      auction_id INTEGER NOT NULL,
      tender_id INTEGER NOT NULL,
      transporter_id INTEGER NOT NULL,
      amount REAL NOT NULL,
      stage INTEGER NOT NULL,
      submitted_at TEXT NOT NULL,
      is_valid INTEGER NOT NULL DEFAULT 1
    )''',
    '''
    CREATE TABLE $auctionParticipants (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      auction_id INTEGER NOT NULL,
      transporter_id INTEGER NOT NULL,
      qualified_stage2 INTEGER NOT NULL DEFAULT 0,
      stage1_rank INTEGER
    )''',
    '''
    CREATE TABLE $auctionResults (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      auction_id INTEGER NOT NULL,
      winner_transporter_id INTEGER NOT NULL,
      winner_name TEXT DEFAULT '',
      winning_bid REAL NOT NULL,
      completed_at TEXT NOT NULL
    )''',
  ];

  static const List<String> dropStatements = [
    'DROP TABLE IF EXISTS $auctionResults',
    'DROP TABLE IF EXISTS $auctionParticipants',
    'DROP TABLE IF EXISTS $bids',
    'DROP TABLE IF EXISTS $auctions',
    'DROP TABLE IF EXISTS $tenderParticipants',
    'DROP TABLE IF EXISTS $materials',
    'DROP TABLE IF EXISTS $tenders',
    'DROP TABLE IF EXISTS $transporters',
    'DROP TABLE IF EXISTS $users',
  ];
}
