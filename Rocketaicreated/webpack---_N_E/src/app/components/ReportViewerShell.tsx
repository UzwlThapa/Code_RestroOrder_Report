'use client';

import React, { useState, useCallback, useMemo } from 'react';
import * as XLSX from 'xlsx';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import ReportFilterBar from './ReportFilterBar';
import ReportTable from './ReportTable';
import ReportPagination from './ReportPagination';
import ReportEmptyState from './ReportEmptyState';
import ReportLoadingSkeleton from './ReportLoadingSkeleton';
import { REPORT_CONFIGS, REPORT_GROUPS, MENU_ENGINEERING_DATA, IRD_SALES_DATA, COST_CENTRE_DATA, type ReportType, type FilterState, type ReportColumn,  } from '../data/reportData';
import { FileSpreadsheet, FileText, Loader2, BarChart2, ShoppingCart, BookOpen, Menu, X, Search, Star } from 'lucide-react';

const ROWS_PER_PAGE = 10;

const REPORT_ICONS: Record<ReportType, React.ReactNode> = {
  'ird-sales': <BookOpen size={15} />,
  'menu-engineering': <BarChart2 size={15} />,
  'cost-centre': <ShoppingCart size={15} />,
};

export default function ReportViewerShell() {
  const [activeReport, setActiveReport] = useState<ReportType>('ird-sales');
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [sidebarSearch, setSidebarSearch] = useState('');
  const [bookmarkedReports, setBookmarkedReports] = useState<Set<ReportType>>(new Set());
  const [filters, setFilters] = useState<FilterState>({
    dateFrom: '2026-09-01',
    dateTo: '2026-09-10',
    branch: 'all',
    category: 'all',
    costCentres: [],
  });
  const [sortColumn, setSortColumn] = useState<string>('date');
  const [sortDirection, setSortDirection] = useState<'asc' | 'desc'>('asc');
  const [currentPage, setCurrentPage] = useState(1);
  const [isLoading, setIsLoading] = useState(false);
  const [exportingExcel, setExportingExcel] = useState(false);
  const [exportingPdf, setExportingPdf] = useState(false);

  const config = REPORT_CONFIGS[activeReport];

  const rawData =
    activeReport === 'menu-engineering'
      ? MENU_ENGINEERING_DATA
      : activeReport === 'ird-sales'
      ? IRD_SALES_DATA
      : COST_CENTRE_DATA;

  // Apply filters client-side (replace with server fetch in production)
  const filteredData = rawData.filter((row: Record<string, unknown>) => {
    if (filters.category !== 'all' && 'category' in row) {
      if ((row.category as string).toLowerCase() !== filters.category.toLowerCase()) return false;
    }
    if (filters.branch !== 'all' && 'branch' in row) {
      if ((row.branch as string) !== filters.branch) return false;
    }
    if (filters.costCentres.length > 0 && 'costCentre' in row) {
      if (!filters.costCentres.includes(row.costCentre as string)) return false;
    }
    return true;
  });

  const sortedData = [...filteredData].sort((a, b) => {
    const aVal = (a as Record<string, unknown>)[sortColumn];
    const bVal = (b as Record<string, unknown>)[sortColumn];
    if (aVal === undefined || bVal === undefined) return 0;
    if (typeof aVal === 'number' && typeof bVal === 'number') {
      return sortDirection === 'asc' ? aVal - bVal : bVal - aVal;
    }
    const aStr = String(aVal).toLowerCase();
    const bStr = String(bVal).toLowerCase();
    return sortDirection === 'asc' ? aStr.localeCompare(bStr) : bStr.localeCompare(aStr);
  });

  const totalPages = Math.ceil(sortedData.length / ROWS_PER_PAGE);
  const pagedData = sortedData.slice(
    (currentPage - 1) * ROWS_PER_PAGE,
    currentPage * ROWS_PER_PAGE
  );

  const handleReportChange = useCallback((report: ReportType) => {
    setIsLoading(true);
    setActiveReport(report);
    setSortColumn('date');
    setSortDirection('asc');
    setCurrentPage(1);
    setFilters((prev) => ({ ...prev, category: 'all', costCentres: [], branch: 'all' }));
    setSidebarOpen(false);
    setTimeout(() => setIsLoading(false), 500);
  }, []);

  const handleFilterChange = useCallback((key: keyof FilterState, value: string | string[]) => {
    setIsLoading(true);
    setCurrentPage(1);
    setFilters((prev) => ({ ...prev, [key]: value }));
    setTimeout(() => setIsLoading(false), 350);
  }, []);

  const handleSort = useCallback(
    (column: string) => {
      if (sortColumn === column) {
        setSortDirection((d) => (d === 'asc' ? 'desc' : 'asc'));
      } else {
        setSortColumn(column);
        setSortDirection('desc');
      }
    },
    [sortColumn]
  );

  const handleExportExcel = useCallback(() => {
    setExportingExcel(true);

    try {
      const columns = config.columns;

      // ── Build header row ──────────────────────────────────────────
      const headerRow = ['#', ...columns.map((c) => c.label)];

      // ── Build data rows ───────────────────────────────────────────
      const dataRows = sortedData.map((row, idx) => {
        const cells: (string | number)[] = [idx + 1];
        columns.forEach((col: ReportColumn) => {
          const val = row[col.key];
          if (col.type === 'currency' || col.type === 'number') {
            cells.push(typeof val === 'number' ? val : 0);
          } else if (col.type === 'percent') {
            cells.push(typeof val === 'number' ? val : 0);
          } else {
            cells.push(val !== undefined && val !== null ? String(val) : '');
          }
        });
        return cells;
      });

      // ── Build totals row ──────────────────────────────────────────
      const totalsRow: (string | number)[] = [''];
      columns.forEach((col: ReportColumn) => {
        if (col.key === 'itemName' || col.key === 'date' || col.key === 'description') {
          totalsRow.push('TOTAL');
        } else if (col.totalsMethod === 'sum' && (col.type === 'currency' || col.type === 'number')) {
          const sum = sortedData.reduce((acc, r) => acc + ((r[col.key] as number) || 0), 0);
          totalsRow.push(sum);
        } else if (col.totalsMethod === 'avg' && (col.type === 'percent' || col.type === 'currency')) {
          const avg =
            sortedData.reduce((acc, r) => acc + ((r[col.key] as number) || 0), 0) /
            (sortedData.length || 1);
          totalsRow.push(avg);
        } else {
          totalsRow.push('');
        }
      });

      // ── Assemble worksheet ────────────────────────────────────────
      const wsData = [headerRow, ...dataRows, totalsRow];
      const ws = XLSX.utils.aoa_to_sheet(wsData);

      // Column widths
      ws['!cols'] = [{ wch: 5 }, ...columns.map((c) => ({ wch: Math.max(c.label.length + 4, 14) }))];

      // ── Style header row (bold) ───────────────────────────────────
      const headerRange = XLSX.utils.decode_range(ws['!ref'] || 'A1');
      for (let C = headerRange.s.c; C <= headerRange.e.c; C++) {
        const cellAddr = XLSX.utils.encode_cell({ r: 0, c: C });
        if (ws[cellAddr]) {
          ws[cellAddr].s = { font: { bold: true }, fill: { fgColor: { rgb: 'E8EDF3' } } };
        }
      }

      // ── Style totals row (bold) ───────────────────────────────────
      const totalsRowIdx = wsData.length - 1;
      for (let C = headerRange.s.c; C <= headerRange.e.c; C++) {
        const cellAddr = XLSX.utils.encode_cell({ r: totalsRowIdx, c: C });
        if (ws[cellAddr]) {
          ws[cellAddr].s = { font: { bold: true }, fill: { fgColor: { rgb: 'EEF2FF' } } };
        }
      }

      // ── Create workbook and trigger download ──────────────────────
      const wb = XLSX.utils.book_new();
      XLSX.utils.book_append_sheet(wb, ws, config.title.slice(0, 31));

      const dateStr = new Date().toISOString().slice(0, 10);
      const fileName = `${config.title.replace(/[^a-z0-9]/gi, '_')}_${dateStr}.xlsx`;

      XLSX.writeFile(wb, fileName);
    } catch (err) {
      console.error('Excel export failed:', err);
    } finally {
      setExportingExcel(false);
    }
  }, [config, sortedData]);

  const handleExportPdf = useCallback(() => {
    setExportingPdf(true);

    try {
      const columns = config.columns;
      const dateStr = new Date().toISOString().slice(0, 10);

      // ── Create A4 landscape document ──────────────────────────────
      const doc = new jsPDF({ orientation: 'landscape', unit: 'mm', format: 'a4' });
      const pageWidth = doc.internal.pageSize.getWidth();

      // ── Title block ───────────────────────────────────────────────
      doc.setFontSize(14);
      doc.setFont('helvetica', 'bold');
      doc.setTextColor(30, 41, 59); // slate-800
      doc.text(config.title, 14, 16);

      doc.setFontSize(8);
      doc.setFont('helvetica', 'normal');
      doc.setTextColor(100, 116, 139); // slate-500
      doc.text(config.description, 14, 22);

      doc.setFontSize(8);
      doc.text(`Generated: ${dateStr}`, pageWidth - 14, 16, { align: 'right' });
      if (filters.dateFrom && filters.dateTo) {
        doc.text(
          `Period: ${filters.dateFrom} – ${filters.dateTo}`,
          pageWidth - 14,
          22,
          { align: 'right' }
        );
      }

      // ── Build table head ──────────────────────────────────────────
      const head = [['#', ...columns.map((c) => c.label)]];

      // ── Build table body ──────────────────────────────────────────
      const body = sortedData.map((row, idx) => {
        const cells: (string | number)[] = [idx + 1];
        columns.forEach((col: ReportColumn) => {
          const val = row[col.key];
          if (col.type === 'currency') {
            cells.push(typeof val === 'number' ? `Rs. ${Math.round(val).toLocaleString('en-IN')}` : '—');
          } else if (col.type === 'percent') {
            cells.push(typeof val === 'number' ? `${val.toFixed(1)}%` : '—');
          } else if (col.type === 'number') {
            cells.push(typeof val === 'number' ? val : 0);
          } else {
            cells.push(val !== undefined && val !== null ? String(val) : '');
          }
        });
        return cells;
      });

      // ── Build totals row ──────────────────────────────────────────
      const totalsRow: (string | number)[] = [''];
      columns.forEach((col: ReportColumn) => {
        if (col.key === 'itemName' || col.key === 'date' || col.key === 'description') {
          totalsRow.push('TOTAL');
        } else if (col.totalsMethod === 'sum' && (col.type === 'currency' || col.type === 'number')) {
          const sum = sortedData.reduce((acc, r) => acc + ((r[col.key] as number) || 0), 0);
          totalsRow.push(
            col.type === 'currency'
              ? `Rs. ${Math.round(sum).toLocaleString('en-IN')}`
              : sum
          );
        } else if (col.totalsMethod === 'avg' && (col.type === 'percent' || col.type === 'currency')) {
          const avg =
            sortedData.reduce((acc, r) => acc + ((r[col.key] as number) || 0), 0) /
            (sortedData.length || 1);
          totalsRow.push(
            col.type === 'currency'
              ? `Rs. ${Math.round(avg).toLocaleString('en-IN')}`
              : `${avg.toFixed(1)}%`
          );
        } else {
          totalsRow.push('');
        }
      });

      // ── Column alignment map ──────────────────────────────────────
      const columnStyles: Record<number, { halign: 'left' | 'right' | 'center' }> = {
        0: { halign: 'center' }, // # column
      };
      columns.forEach((col, i) => {
        columnStyles[i + 1] = {
          halign: col.align === 'right' ? 'right' : col.align === 'center' ? 'center' : 'left',
        };
      });

      // ── Render table ──────────────────────────────────────────────
      autoTable(doc, {
        startY: 28,
        head,
        body,
        foot: [totalsRow],
        showFoot: 'lastPage',
        theme: 'grid',
        styles: {
          fontSize: 8,
          cellPadding: { top: 2.5, right: 3, bottom: 2.5, left: 3 },
          textColor: [30, 41, 59],
          lineColor: [226, 232, 240],
          lineWidth: 0.2,
          overflow: 'linebreak',
        },
        headStyles: {
          fillColor: [232, 237, 243],
          textColor: [30, 41, 59],
          fontStyle: 'bold',
          fontSize: 8,
        },
        footStyles: {
          fillColor: [238, 242, 255],
          textColor: [30, 41, 59],
          fontStyle: 'bold',
          fontSize: 8,
        },
        alternateRowStyles: {
          fillColor: [248, 250, 252],
        },
        columnStyles,
        margin: { top: 28, left: 14, right: 14, bottom: 14 },
        didDrawPage: (data) => {
          // Footer on every page
          const pageCount = (doc as jsPDF & { internal: { getNumberOfPages: () => number } }).internal.getNumberOfPages();
          doc.setFontSize(7);
          doc.setTextColor(148, 163, 184);
          doc.text(
            `Page ${data.pageNumber} of ${pageCount}`,
            pageWidth / 2,
            doc.internal.pageSize.getHeight() - 6,
            { align: 'center' }
          );
          doc.text(
            config.title,
            14,
            doc.internal.pageSize.getHeight() - 6
          );
        },
      });

      // ── Save file ─────────────────────────────────────────────────
      const fileName = `${config.title.replace(/[^a-z0-9]/gi, '_')}_${dateStr}.pdf`;
      doc.save(fileName);
    } catch (err) {
      console.error('PDF export failed:', err);
    } finally {
      setExportingPdf(false);
    }
  }, [config, sortedData, filters]);

  const formatDate = (iso: string) => {
    const [y, m, d] = iso.split('-');
    return `${d}/${m}/${y}`;
  };

  const toggleBookmark = useCallback((reportId: ReportType, e: React.MouseEvent) => {
    e.stopPropagation();
    setBookmarkedReports((prev) => {
      const next = new Set(prev);
      if (next.has(reportId)) {
        next.delete(reportId);
      } else {
        next.add(reportId);
      }
      return next;
    });
  }, []);

  // All reports flattened for search + bookmark ordering
  const allReportIds = useMemo<ReportType[]>(() => {
    return REPORT_GROUPS.flatMap((g) => g.reports as ReportType[]);
  }, []);

  // Filtered reports by search query
  const filteredReportIds = useMemo<ReportType[]>(() => {
    const q = sidebarSearch.trim().toLowerCase();
    if (!q) return allReportIds;
    return allReportIds.filter((id) =>
      REPORT_CONFIGS[id].title.toLowerCase().includes(q)
    );
  }, [sidebarSearch, allReportIds]);

  // Sort: bookmarked first, then rest
  const sortedReportIds = useMemo<ReportType[]>(() => {
    const bookmarked = filteredReportIds.filter((id) => bookmarkedReports.has(id));
    const rest = filteredReportIds.filter((id) => !bookmarkedReports.has(id));
    return [...bookmarked, ...rest];
  }, [filteredReportIds, bookmarkedReports]);

  // Group the sorted/filtered reports back into their groups (for section headers)
  const visibleGroups = useMemo(() => {
    if (sidebarSearch.trim() || bookmarkedReports.size > 0) {
      // When searching or bookmarks exist, show flat list with optional "Bookmarked" section
      return null; // handled separately below
    }
    return REPORT_GROUPS;
  }, [sidebarSearch, bookmarkedReports]);

  const SidebarContent = () => (
    <>
      {/* Brand */}
      <div className="px-4 py-4 border-b border-border flex items-center gap-2.5">
        <div className="w-7 h-7 rounded bg-primary flex items-center justify-center flex-shrink-0">
          <svg width="16" height="16" viewBox="0 0 20 20" fill="none">
            <circle cx="10" cy="10" r="8" stroke="white" strokeWidth="1.5" />
            <line x1="7" y1="4" x2="7" y2="9" stroke="#fbbf24" strokeWidth="1.5" strokeLinecap="round" />
            <line x1="9" y1="4" x2="9" y2="9" stroke="#fbbf24" strokeWidth="1.5" strokeLinecap="round" />
            <line x1="11" y1="4" x2="11" y2="9" stroke="#fbbf24" strokeWidth="1.5" strokeLinecap="round" />
            <line x1="9" y1="9" x2="9" y2="16" stroke="#fbbf24" strokeWidth="1.5" strokeLinecap="round" />
          </svg>
        </div>
        <div className="flex-1 min-w-0">
          <div className="text-sm font-semibold text-foreground leading-tight">RestaurantReports</div>
          <div className="text-xs text-muted-foreground leading-tight">FY 2082–83</div>
        </div>
        {/* Close button — mobile only */}
        <button
          onClick={() => setSidebarOpen(false)}
          className="lg:hidden p-1 rounded hover:bg-secondary text-muted-foreground"
          aria-label="Close menu"
        >
          <X size={16} />
        </button>
      </div>

      {/* Search box */}
      <div className="px-3 py-2.5 border-b border-border">
        <div className="relative">
          <Search size={13} className="absolute left-2.5 top-1/2 -translate-y-1/2 text-muted-foreground pointer-events-none" />
          <input
            type="text"
            value={sidebarSearch}
            onChange={(e) => setSidebarSearch(e.target.value)}
            placeholder="Search reports…"
            className="w-full pl-7 pr-7 py-1.5 text-xs rounded border border-border bg-background text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-1 focus:ring-primary/50 focus:border-primary/50"
          />
          {sidebarSearch && (
            <button
              onClick={() => setSidebarSearch('')}
              className="absolute right-2 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
              aria-label="Clear search"
            >
              <X size={12} />
            </button>
          )}
        </div>
      </div>

      {/* Report navigation */}
      <nav className="flex-1 overflow-y-auto py-3 px-2">
        {/* When searching or bookmarks active: flat sorted list */}
        {(sidebarSearch.trim() || bookmarkedReports.size > 0) ? (
          <>
            {bookmarkedReports.size > 0 && !sidebarSearch.trim() && (
              <div className="px-2 mb-1 text-xs font-semibold text-amber-500 uppercase tracking-widest flex items-center gap-1">
                <Star size={10} className="fill-amber-400 text-amber-400" />
                Bookmarked
              </div>
            )}
            {sortedReportIds.length === 0 ? (
              <div className="px-2 py-4 text-xs text-muted-foreground text-center">No reports found</div>
            ) : (
              sortedReportIds.map((reportId) => {
                const rc = REPORT_CONFIGS[reportId];
                const isActive = activeReport === reportId;
                const isBookmarked = bookmarkedReports.has(reportId);
                return (
                  <button
                    key={reportId}
                    onClick={() => handleReportChange(reportId)}
                    className={`w-full flex items-center gap-2 px-2.5 py-2 rounded text-sm text-left transition-colors mb-0.5 group ${
                      isActive
                        ? 'bg-primary text-primary-foreground font-medium'
                        : 'text-foreground hover:bg-secondary'
                    }`}
                  >
                    <span className={isActive ? 'opacity-90' : 'opacity-50'}>
                      {REPORT_ICONS[reportId]}
                    </span>
                    <span className="leading-tight flex-1 truncate">{rc.title}</span>
                    <span
                      role="button"
                      onClick={(e) => toggleBookmark(reportId, e)}
                      className={`flex-shrink-0 transition-colors ${
                        isBookmarked
                          ? 'text-amber-400'
                          : isActive
                          ? 'text-primary-foreground/40 hover:text-primary-foreground/80'
                          : 'text-transparent group-hover:text-muted-foreground hover:!text-amber-400'
                      }`}
                      aria-label={isBookmarked ? 'Remove bookmark' : 'Bookmark report'}
                    >
                      <Star size={13} className={isBookmarked ? 'fill-amber-400' : ''} />
                    </span>
                  </button>
                );
              })
            )}
          </>
        ) : (
          /* Default grouped view */
          REPORT_GROUPS.map((group) => (
            <div key={group.id} className="mb-4">
              <div className="px-2 mb-1 text-xs font-semibold text-muted-foreground uppercase tracking-widest">
                {group.label}
              </div>
              {(group.reports as ReportType[]).map((reportId) => {
                const rc = REPORT_CONFIGS[reportId];
                const isActive = activeReport === reportId;
                const isBookmarked = bookmarkedReports.has(reportId);
                return (
                  <button
                    key={reportId}
                    onClick={() => handleReportChange(reportId)}
                    className={`w-full flex items-center gap-2 px-2.5 py-2 rounded text-sm text-left transition-colors mb-0.5 group ${
                      isActive
                        ? 'bg-primary text-primary-foreground font-medium'
                        : 'text-foreground hover:bg-secondary'
                    }`}
                  >
                    <span className={isActive ? 'opacity-90' : 'opacity-50'}>
                      {REPORT_ICONS[reportId]}
                    </span>
                    <span className="leading-tight flex-1 truncate">{rc.title}</span>
                    <span
                      role="button"
                      onClick={(e) => toggleBookmark(reportId, e)}
                      className={`flex-shrink-0 transition-colors ${
                        isBookmarked
                          ? 'text-amber-400'
                          : isActive
                          ? 'text-primary-foreground/40 hover:text-primary-foreground/80'
                          : 'text-transparent group-hover:text-muted-foreground hover:!text-amber-400'
                      }`}
                      aria-label={isBookmarked ? 'Remove bookmark' : 'Bookmark report'}
                    >
                      <Star size={13} className={isBookmarked ? 'fill-amber-400' : ''} />
                    </span>
                  </button>
                );
              })}
            </div>
          ))
        )}
      </nav>

      {/* Footer */}
      <div className="px-4 py-3 border-t border-border">
        <div className="text-xs text-muted-foreground">Himalayan Kitchen Pvt. Ltd.</div>
      </div>
    </>
  );

  return (
    <div className="flex h-screen bg-background overflow-hidden print-full">

      {/* ── Mobile/Tablet Overlay Backdrop ───────────────────────────── */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 z-20 bg-black/40 lg:hidden"
          onClick={() => setSidebarOpen(false)}
          aria-hidden="true"
        />
      )}

      {/* ── Left Sidebar — desktop: always visible, mobile: slide-in ── */}
      <aside
        className={`
          print-hidden fixed inset-y-0 left-0 z-30 w-56 flex-shrink-0 bg-card border-r border-border flex flex-col
          transform transition-transform duration-200 ease-in-out
          ${sidebarOpen ? 'translate-x-0' : '-translate-x-full'}
          lg:relative lg:translate-x-0 lg:z-auto
        `}
      >
        <SidebarContent />
      </aside>

      {/* ── Main Content ─────────────────────────────────────────────── */}
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">

        {/* Top bar: hamburger + report title + export buttons */}
        <header className="print-hidden flex-shrink-0 bg-card border-b border-border px-4 py-3 flex items-center justify-between gap-3">
          <div className="flex items-center gap-3 min-w-0">
            {/* Hamburger — hidden on desktop */}
            <button
              onClick={() => setSidebarOpen(true)}
              className="lg:hidden p-1.5 rounded border border-border bg-background hover:bg-secondary text-foreground flex-shrink-0"
              aria-label="Open menu"
            >
              <Menu size={18} />
            </button>
            <div className="min-w-0">
              <h1 className="text-base sm:text-lg font-semibold text-foreground leading-tight truncate">{config.title}</h1>
              <p className="text-xs text-muted-foreground mt-0.5 hidden sm:block truncate">{config.description}</p>
            </div>
          </div>
          <div className="flex items-center gap-2 flex-shrink-0">
            <button
              onClick={handleExportExcel}
              disabled={exportingExcel}
              className="flex items-center gap-1.5 px-2.5 py-1.5 rounded border border-border bg-card text-sm font-medium text-foreground hover:bg-secondary hover:border-primary/40 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              title="Export to Excel"
            >
              {exportingExcel ? (
                <Loader2 size={14} className="animate-spin text-primary" />
              ) : (
                <FileSpreadsheet size={14} className="text-green-600" />
              )}
              <span className="hidden sm:inline">{exportingExcel ? 'Exporting…' : 'Excel'}</span>
            </button>
            <button
              onClick={handleExportPdf}
              disabled={exportingPdf}
              className="flex items-center gap-1.5 px-2.5 py-1.5 rounded border border-border bg-card text-sm font-medium text-foreground hover:bg-secondary hover:border-primary/40 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              title="Export to PDF / Print"
            >
              {exportingPdf ? (
                <Loader2 size={14} className="animate-spin text-primary" />
              ) : (
                <FileText size={14} className="text-red-600" />
              )}
              <span className="hidden sm:inline">{exportingPdf ? 'Preparing…' : 'PDF'}</span>
            </button>
          </div>
        </header>

        {/* Print-only header */}
        <div className="hidden print:block px-6 pt-4 pb-2">
          <h1 className="text-xl font-semibold text-foreground">{config.title}</h1>
          <p className="text-sm text-muted-foreground mt-0.5">
            Period: {formatDate(filters.dateFrom)} – {formatDate(filters.dateTo)}
            {filters.branch !== 'all' && <span> · Branch: {filters.branch}</span>}
          </p>
        </div>

        {/* Filter bar */}
        <div className="print-hidden flex-shrink-0 border-b border-border bg-background px-4 py-3">
          <ReportFilterBar
            config={config}
            filters={filters}
            onFilterChange={handleFilterChange}
          />
        </div>

        {/* Scrollable table area */}
        <div className="flex-1 overflow-auto px-4 py-4">
          {/* Row count summary */}
          {!isLoading && sortedData.length > 0 && (
            <div className="flex items-center justify-between mb-3 flex-wrap gap-1">
              <span className="text-xs text-muted-foreground">
                {sortedData.length} row{sortedData.length !== 1 ? 's' : ''} found
                {filters.branch !== 'all' && <span> · Branch: <strong>{filters.branch}</strong></span>}
                {filters.category !== 'all' && <span> · Category: <strong>{filters.category}</strong></span>}
                {filters.costCentres.length > 0 && (
                  <span> · Cost Centre: <strong>{filters.costCentres.join(', ')}</strong></span>
                )}
              </span>
              <span className="text-xs text-muted-foreground">Last updated: 10/09/2026</span>
            </div>
          )}

          {isLoading ? (
            <ReportLoadingSkeleton columns={config.columns.length} />
          ) : pagedData.length === 0 ? (
            <ReportEmptyState
              reportName={config.title}
              onClearFilters={() =>
                setFilters((prev) => ({ ...prev, category: 'all', branch: 'all', costCentres: [] }))
              }
            />
          ) : (
            <>
              <ReportTable
                config={config}
                data={pagedData}
                allData={sortedData}
                sortColumn={sortColumn}
                sortDirection={sortDirection}
                onSort={handleSort}
                showTotals={currentPage === totalPages || totalPages === 1}
              />

              {totalPages > 1 && (
                <div className="print-hidden mt-4">
                  <ReportPagination
                    currentPage={currentPage}
                    totalPages={totalPages}
                    totalRows={sortedData.length}
                    rowsPerPage={ROWS_PER_PAGE}
                    onPageChange={setCurrentPage}
                  />
                </div>
              )}
            </>
          )}

          {/* Print footer */}
          <div className="hidden print:flex justify-between text-xs text-muted-foreground mt-6 pt-3 border-t border-border">
            <span>Generated: 10/09/2026 · Himalayan Kitchen Pvt. Ltd.</span>
            <span>RestaurantReports — Confidential</span>
          </div>
        </div>
      </div>
    </div>
  );
}