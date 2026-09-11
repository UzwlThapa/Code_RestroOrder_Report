// ─── Types ──────────────────────────────────────────────────────────────────

export type ReportType = 'menu-engineering' | 'ird-sales' | 'cost-centre';

export interface FilterState {
  dateFrom: string;
  dateTo: string;
  branch: string;
  category: string;
  costCentres: string[]; // multi-select; empty = "All"
}

export type ColumnType = 'text' | 'number' | 'currency' | 'percent' | 'badge' | 'date';
export type TotalsMethod = 'sum' | 'avg' | 'none';
export type ColumnAlign = 'left' | 'right' | 'center';

export interface ReportColumn {
  key: string;
  label: string;
  type: ColumnType;
  sortable: boolean;
  align: ColumnAlign;
  totalsMethod: TotalsMethod;
  minWidth?: number;
}

export interface ReportConfig {
  id: ReportType;
  title: string;
  description: string;
  filters: ('branch' | 'category' | 'costCentre')[];
  columns: ReportColumn[];
}

export interface ReportGroup {
  id: string;
  label: string;
  reports: ReportType[];
}

// ─── Helpers ────────────────────────────────────────────────────────────────

export function formatRs(value: number | undefined | null): string {
  if (value === undefined || value === null || isNaN(value)) return '—';
  return 'Rs. ' + Math.round(value).toLocaleString('en-IN');
}

// ─── Filter Options ──────────────────────────────────────────────────────────

export const BRANCH_OPTIONS = [
  { value: 'all', label: 'All Branches' },
  { value: 'Thamel', label: 'Thamel' },
  { value: 'Patan', label: 'Patan' },
  { value: 'Baneshwor', label: 'Baneshwor' },
  { value: 'Lazimpat', label: 'Lazimpat' },
];

export const CATEGORY_OPTIONS = [
  { value: 'all', label: 'All Categories' },
  { value: 'Top', label: 'Top' },
  { value: 'Low', label: 'Low' },
  { value: 'Dead', label: 'Dead' },
];

export const COST_CENTRE_OPTIONS = [
  { value: 'Kitchen', label: 'Kitchen' },
  { value: 'Bar', label: 'Bar' },
  { value: 'Housekeeping', label: 'Housekeeping' },
  { value: 'Front Office', label: 'Front Office' },
];

// ─── Sidebar Report Groups ───────────────────────────────────────────────────

export const REPORT_GROUPS: ReportGroup[] = [
  {
    id: 'sales',
    label: 'Sales',
    reports: ['ird-sales'],
  },
  {
    id: 'menu',
    label: 'Menu',
    reports: ['menu-engineering'],
  },
  {
    id: 'purchasing',
    label: 'Purchasing',
    reports: ['cost-centre'],
  },
];

// ─── Report Configs ──────────────────────────────────────────────────────────

export const REPORT_CONFIGS: Record<ReportType, ReportConfig> = {
  'menu-engineering': {
    id: 'menu-engineering',
    title: 'Menu Engineering Report',
    description:
      'Analyse item performance by quantity sold, revenue contribution, food cost %, and menu category classification.',
    filters: ['branch', 'category'],
    columns: [
      { key: 'itemName',            label: 'Item Name',            type: 'text',     sortable: true,  align: 'left',   totalsMethod: 'none',  minWidth: 180 },
      { key: 'menuSection',         label: 'Menu Section',         type: 'text',     sortable: true,  align: 'left',   totalsMethod: 'none'  },
      { key: 'category',            label: 'Category',             type: 'badge',    sortable: true,  align: 'center', totalsMethod: 'none'  },
      { key: 'qtySold',             label: 'Qty Sold',             type: 'number',   sortable: true,  align: 'right',  totalsMethod: 'sum'   },
      { key: 'revenue',             label: 'Revenue (Rs.)',         type: 'currency', sortable: true,  align: 'right',  totalsMethod: 'sum'   },
      { key: 'avgSellingPrice',     label: 'Avg. Price (Rs.)',     type: 'currency', sortable: true,  align: 'right',  totalsMethod: 'avg'   },
      { key: 'foodCostPct',         label: 'Food Cost %',          type: 'percent',  sortable: true,  align: 'right',  totalsMethod: 'avg'   },
      { key: 'contributionMargin',  label: 'Contribution (Rs.)',   type: 'currency', sortable: true,  align: 'right',  totalsMethod: 'sum'   },
      { key: 'recommendation',      label: 'Recommendation',       type: 'text',     sortable: false, align: 'left',   totalsMethod: 'none'  },
    ],
  },

  'ird-sales': {
    id: 'ird-sales',
    title: 'IRD Sales Book',
    description:
      'Daily sales register as required for IRD reconciliation — bill-by-bill breakdown with tax, discount, and payment mode.',
    filters: ['branch'],
    columns: [
      { key: 'date',          label: 'Date',              type: 'text',     sortable: true,  align: 'left',   totalsMethod: 'none'  },
      { key: 'billNo',        label: 'Bill No.',          type: 'text',     sortable: true,  align: 'left',   totalsMethod: 'none'  },
      { key: 'branch',        label: 'Branch',            type: 'text',     sortable: true,  align: 'left',   totalsMethod: 'none'  },
      { key: 'tableNo',       label: 'Table',             type: 'text',     sortable: false, align: 'center', totalsMethod: 'none'  },
      { key: 'covers',        label: 'Covers',            type: 'number',   sortable: true,  align: 'right',  totalsMethod: 'sum'   },
      { key: 'grossAmount',   label: 'Gross (Rs.)',       type: 'currency', sortable: true,  align: 'right',  totalsMethod: 'sum'   },
      { key: 'discount',      label: 'Discount (Rs.)',    type: 'currency', sortable: true,  align: 'right',  totalsMethod: 'sum'   },
      { key: 'taxableAmount', label: 'Taxable (Rs.)',     type: 'currency', sortable: true,  align: 'right',  totalsMethod: 'sum'   },
      { key: 'vat',           label: 'VAT 13% (Rs.)',     type: 'currency', sortable: true,  align: 'right',  totalsMethod: 'sum'   },
      { key: 'netAmount',     label: 'Net Amount (Rs.)',  type: 'currency', sortable: true,  align: 'right',  totalsMethod: 'sum'   },
      { key: 'paymentMode',   label: 'Payment Mode',      type: 'text',     sortable: true,  align: 'left',   totalsMethod: 'none'  },
      { key: 'status',        label: 'Status',            type: 'badge',    sortable: true,  align: 'center', totalsMethod: 'none'  },
    ],
  },

  'cost-centre': {
    id: 'cost-centre',
    title: 'Cost Centre Purchase Report',
    description:
      'Itemised purchase orders by cost centre — track spend against budget and supplier invoices.',
    filters: ['branch', 'costCentre'],
    columns: [
      { key: 'date',          label: 'Date',              type: 'text',     sortable: true,  align: 'left',   totalsMethod: 'none'  },
      { key: 'invoiceNo',     label: 'Invoice No.',       type: 'text',     sortable: true,  align: 'left',   totalsMethod: 'none'  },
      { key: 'supplier',      label: 'Supplier',          type: 'text',     sortable: true,  align: 'left',   totalsMethod: 'none',  minWidth: 160 },
      { key: 'description',   label: 'Item / Description',type: 'text',     sortable: false, align: 'left',   totalsMethod: 'none',  minWidth: 180 },
      { key: 'costCentre',    label: 'Cost Centre',       type: 'text',     sortable: true,  align: 'left',   totalsMethod: 'none'  },
      { key: 'branch',        label: 'Branch',            type: 'text',     sortable: true,  align: 'left',   totalsMethod: 'none'  },
      { key: 'qty',           label: 'Qty',               type: 'number',   sortable: true,  align: 'right',  totalsMethod: 'sum'   },
      { key: 'unitRate',      label: 'Unit Rate (Rs.)',   type: 'currency', sortable: true,  align: 'right',  totalsMethod: 'avg'   },
      { key: 'totalAmount',   label: 'Total (Rs.)',       type: 'currency', sortable: true,  align: 'right',  totalsMethod: 'sum'   },
      { key: 'status',        label: 'Status',            type: 'badge',    sortable: true,  align: 'center', totalsMethod: 'none'  },
    ],
  },
};

// ─── Mock Data: Menu Engineering ─────────────────────────────────────────────

export const MENU_ENGINEERING_DATA: Record<string, unknown>[] = [
  { id: 'me-001', itemName: 'Buff Momo (Steamed, 8 pcs)', menuSection: 'Starters', category: 'Top',  qtySold: 412, revenue: 1648000, avgSellingPrice: 4000,  foodCostPct: 28.4, contributionMargin: 1180640, recommendation: 'Retain — flagship item, upsell combo' },
  { id: 'me-002', itemName: 'Chicken Chowmein',           menuSection: 'Noodles',  category: 'Top',  qtySold: 389, revenue: 1167000, avgSellingPrice: 3000,  foodCostPct: 31.2, contributionMargin:  803076, recommendation: 'Retain — high volume driver' },
  { id: 'me-003', itemName: 'Dal Bhat Thali (Full)',       menuSection: 'Mains',    category: 'Top',  qtySold: 358, revenue: 1790000, avgSellingPrice: 5000,  foodCostPct: 34.5, contributionMargin: 1172450, recommendation: 'Retain — high margin, promote lunch' },
  { id: 'me-004', itemName: 'Veg Thukpa',                 menuSection: 'Soups',    category: 'Top',  qtySold: 274, revenue:  822000, avgSellingPrice: 3000,  foodCostPct: 26.8, contributionMargin:  601836, recommendation: 'Retain — low cost, strong margin' },
  { id: 'me-005', itemName: 'Sekuwa Platter (Mixed)',      menuSection: 'Grills',   category: 'Top',  qtySold: 201, revenue: 1407000, avgSellingPrice: 7000,  foodCostPct: 38.1, contributionMargin:  869733, recommendation: 'Retain — premium positioning' },
  { id: 'me-006', itemName: 'Chicken Choila',             menuSection: 'Starters', category: 'Low',  qtySold: 118, revenue:  531000, avgSellingPrice: 4500,  foodCostPct: 41.3, contributionMargin:  311793, recommendation: 'Reposition — reduce portion cost' },
  { id: 'me-007', itemName: 'Paneer Tikka',               menuSection: 'Grills',   category: 'Low',  qtySold: 97,  revenue:  533500, avgSellingPrice: 5500,  foodCostPct: 44.2, contributionMargin:  297973, recommendation: 'Reposition — improve food cost' },
  { id: 'me-008', itemName: 'Fish Curry (Rohu)',           menuSection: 'Mains',    category: 'Low',  qtySold: 84,  revenue:  630000, avgSellingPrice: 7500,  foodCostPct: 47.8, contributionMargin:  328860, recommendation: 'Review pricing — cost pressure' },
  { id: 'me-009', itemName: 'Mushroom Soup',              menuSection: 'Soups',    category: 'Low',  qtySold: 63,  revenue:  157500, avgSellingPrice: 2500,  foodCostPct: 29.4, contributionMargin:  111195, recommendation: 'Promote — low visibility on menu' },
  { id: 'me-010', itemName: 'Prawn Butter Garlic',        menuSection: 'Starters', category: 'Dead', qtySold: 18,  revenue:  234000, avgSellingPrice: 13000, foodCostPct: 52.6, contributionMargin:  110916, recommendation: 'Remove or reprice — low demand, high cost' },
  { id: 'me-011', itemName: 'Club Sandwich',              menuSection: 'Snacks',   category: 'Dead', qtySold: 12,  revenue:   54000, avgSellingPrice: 4500,  foodCostPct: 48.0, contributionMargin:   28080, recommendation: 'Remove — poor sales, average margin' },
  { id: 'me-012', itemName: 'Pasta Arrabiata',            menuSection: 'Mains',    category: 'Dead', qtySold: 9,   revenue:   58500, avgSellingPrice: 6500,  foodCostPct: 50.5, contributionMargin:   28957, recommendation: 'Remove — not aligned with brand identity' },
];

// ─── Mock Data: IRD Sales Book ────────────────────────────────────────────────

export const IRD_SALES_DATA: Record<string, unknown>[] = [
  { id: 'ird-001', date: '01/09/2026', billNo: 'BL-2026-3401', branch: 'Thamel',    tableNo: 'T-04', covers: 4, grossAmount: 28000,  discount: 0,    taxableAmount: 28000,  vat: 3640,  netAmount: 31640,  paymentMode: 'Cash',       status: 'Reconciled' },
  { id: 'ird-002', date: '01/09/2026', billNo: 'BL-2026-3402', branch: 'Thamel',    tableNo: 'T-07', covers: 2, grossAmount: 14500,  discount: 500,  taxableAmount: 14000,  vat: 1820,  netAmount: 15820,  paymentMode: 'Card',       status: 'Reconciled' },
  { id: 'ird-003', date: '02/09/2026', billNo: 'BL-2026-3403', branch: 'Patan',     tableNo: 'T-02', covers: 6, grossAmount: 42000,  discount: 2000, taxableAmount: 40000,  vat: 5200,  netAmount: 45200,  paymentMode: 'QR Pay',     status: 'Reconciled' },
  { id: 'ird-004', date: '02/09/2026', billNo: 'BL-2026-3404', branch: 'Baneshwor', tableNo: 'T-11', covers: 3, grossAmount: 21500,  discount: 0,    taxableAmount: 21500,  vat: 2795,  netAmount: 24295,  paymentMode: 'Cash',       status: 'Reconciled' },
  { id: 'ird-005', date: '03/09/2026', billNo: 'BL-2026-3405', branch: 'Thamel',    tableNo: 'T-05', covers: 5, grossAmount: 35500,  discount: 1500, taxableAmount: 34000,  vat: 4420,  netAmount: 38420,  paymentMode: 'Card',       status: 'Reconciled' },
  { id: 'ird-006', date: '04/09/2026', billNo: 'BL-2026-3406', branch: 'Lazimpat',  tableNo: 'T-01', covers: 8, grossAmount: 67000,  discount: 5000, taxableAmount: 62000,  vat: 8060,  netAmount: 70060,  paymentMode: 'Card',       status: 'Reconciled' },
  { id: 'ird-007', date: '04/09/2026', billNo: 'BL-2026-3407', branch: 'Patan',     tableNo: 'T-08', covers: 2, grossAmount: 12000,  discount: 0,    taxableAmount: 12000,  vat: 1560,  netAmount: 13560,  paymentMode: 'QR Pay',     status: 'Pending'    },
  { id: 'ird-008', date: '05/09/2026', billNo: 'BL-2026-3408', branch: 'Thamel',    tableNo: 'T-09', covers: 4, grossAmount: 31000,  discount: 0,    taxableAmount: 31000,  vat: 4030,  netAmount: 35030,  paymentMode: 'Cash',       status: 'Reconciled' },
  { id: 'ird-009', date: '06/09/2026', billNo: 'BL-2026-3409', branch: 'Baneshwor', tableNo: 'T-03', covers: 1, grossAmount: 8500,   discount: 0,    taxableAmount: 8500,   vat: 1105,  netAmount: 9605,   paymentMode: 'Cash',       status: 'Voided'     },
  { id: 'ird-010', date: '07/09/2026', billNo: 'BL-2026-3410', branch: 'Lazimpat',  tableNo: 'T-06', covers: 3, grossAmount: 24500,  discount: 1000, taxableAmount: 23500,  vat: 3055,  netAmount: 26555,  paymentMode: 'QR Pay',     status: 'Reconciled' },
  { id: 'ird-011', date: '08/09/2026', billNo: 'BL-2026-3411', branch: 'Thamel',    tableNo: 'T-10', covers: 7, grossAmount: 58000,  discount: 3000, taxableAmount: 55000,  vat: 7150,  netAmount: 62150,  paymentMode: 'Card',       status: 'Reconciled' },
  { id: 'ird-012', date: '09/09/2026', billNo: 'BL-2026-3412', branch: 'Patan',     tableNo: 'T-04', covers: 2, grossAmount: 16000,  discount: 0,    taxableAmount: 16000,  vat: 2080,  netAmount: 18080,  paymentMode: 'Cash',       status: 'Pending'    },
];

// ─── Mock Data: Cost Centre Purchases ────────────────────────────────────────

export const COST_CENTRE_DATA: Record<string, unknown>[] = [
  { id: 'cc-001', date: '01/09/2026', invoiceNo: 'INV-2026-881', supplier: 'Annapurna Traders',    description: 'Chicken (Broiler, 20kg)',           costCentre: 'Kitchen',      branch: 'Thamel',    qty: 20,  unitRate: 450,  totalAmount: 9000,  status: 'Approved'    },
  { id: 'cc-002', date: '01/09/2026', invoiceNo: 'INV-2026-882', supplier: 'Nepal Beverages Ltd.',  description: 'Beer — Everest 650ml (Case x24)',   costCentre: 'Bar',          branch: 'Thamel',    qty: 5,   unitRate: 2400, totalAmount: 12000, status: 'Approved'    },
  { id: 'cc-003', date: '02/09/2026', invoiceNo: 'INV-2026-883', supplier: 'Himalayan Dairy',       description: 'Paneer (10kg block)',               costCentre: 'Kitchen',      branch: 'Patan',     qty: 10,  unitRate: 380,  totalAmount: 3800,  status: 'Approved'    },
  { id: 'cc-004', date: '02/09/2026', invoiceNo: 'INV-2026-884', supplier: 'Sunrise Cleaning Co.',  description: 'Floor Cleaner (5L x 6)',            costCentre: 'Housekeeping', branch: 'Baneshwor', qty: 6,   unitRate: 750,  totalAmount: 4500,  status: 'Approved'    },
  { id: 'cc-005', date: '03/09/2026', invoiceNo: 'INV-2026-885', supplier: 'Annapurna Traders',    description: 'Mutton (Bone-in, 15kg)',            costCentre: 'Kitchen',      branch: 'Thamel',    qty: 15,  unitRate: 920,  totalAmount: 13800, status: 'Approved'    },
  { id: 'cc-006', date: '04/09/2026', invoiceNo: 'INV-2026-886', supplier: 'Kathmandu Spirits',    description: 'Old Durbar Whisky 750ml (Case x12)',costCentre: 'Bar',          branch: 'Lazimpat',  qty: 4,   unitRate: 7200, totalAmount: 28800, status: 'Under Review'},
  { id: 'cc-007', date: '05/09/2026', invoiceNo: 'INV-2026-887', supplier: 'Fresh Veggies Pvt.',   description: 'Mixed Vegetables (Seasonal, 30kg)', costCentre: 'Kitchen',      branch: 'Patan',     qty: 30,  unitRate: 120,  totalAmount: 3600,  status: 'Approved'    },
  { id: 'cc-008', date: '05/09/2026', invoiceNo: 'INV-2026-888', supplier: 'Office Depot Nepal',   description: 'A4 Paper Ream (Box x10)',           costCentre: 'Front Office', branch: 'Thamel',    qty: 10,  unitRate: 650,  totalAmount: 6500,  status: 'Approved'    },
  { id: 'cc-009', date: '06/09/2026', invoiceNo: 'INV-2026-889', supplier: 'Himalayan Dairy',       description: 'Fresh Milk (50L, UHT)',             costCentre: 'Kitchen',      branch: 'Baneshwor', qty: 50,  unitRate: 95,   totalAmount: 4750,  status: 'Approved'    },
  { id: 'cc-010', date: '07/09/2026', invoiceNo: 'INV-2026-890', supplier: 'Nepal Beverages Ltd.',  description: 'Soft Drinks Assorted (Case x24)',   costCentre: 'Bar',          branch: 'Thamel',    qty: 8,   unitRate: 1200, totalAmount: 9600,  status: 'Approved'    },
  { id: 'cc-011', date: '08/09/2026', invoiceNo: 'INV-2026-891', supplier: 'Sunrise Cleaning Co.',  description: 'Toilet Paper Rolls (Pack x48)',     costCentre: 'Housekeeping', branch: 'Patan',     qty: 4,   unitRate: 1100, totalAmount: 4400,  status: 'Rejected'    },
  { id: 'cc-012', date: '09/09/2026', invoiceNo: 'INV-2026-892', supplier: 'Annapurna Traders',    description: 'Shrimp (Medium, 5kg frozen)',       costCentre: 'Kitchen',      branch: 'Lazimpat',  qty: 5,   unitRate: 1850, totalAmount: 9250,  status: 'Under Review'},
];
const REPORT_OPTIONS: any = null;

export { REPORT_OPTIONS };