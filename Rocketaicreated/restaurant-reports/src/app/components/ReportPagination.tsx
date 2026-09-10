'use client';

import React from 'react';
import { ChevronLeft, ChevronRight, ChevronsLeft, ChevronsRight } from 'lucide-react';

interface ReportPaginationProps {
  currentPage: number;
  totalPages: number;
  totalRows: number;
  rowsPerPage: number;
  onPageChange: (page: number) => void;
}

export default function ReportPagination({
  currentPage,
  totalPages,
  totalRows,
  rowsPerPage,
  onPageChange,
}: ReportPaginationProps) {
  const startRow = (currentPage - 1) * rowsPerPage + 1;
  const endRow = Math.min(currentPage * rowsPerPage, totalRows);

  // Build page number list with ellipsis
  const pages: (number | 'ellipsis-start' | 'ellipsis-end')[] = [];
  if (totalPages <= 7) {
    for (let i = 1; i <= totalPages; i++) pages.push(i);
  } else {
    pages.push(1);
    if (currentPage > 3) pages.push('ellipsis-start');
    const start = Math.max(2, currentPage - 1);
    const end = Math.min(totalPages - 1, currentPage + 1);
    for (let i = start; i <= end; i++) pages.push(i);
    if (currentPage < totalPages - 2) pages.push('ellipsis-end');
    pages.push(totalPages);
  }

  const btnBase =
    'inline-flex items-center justify-center w-8 h-8 rounded text-sm border transition-colors';
  const btnActive =
    'bg-primary text-primary-foreground border-primary font-semibold';
  const btnDefault =
    'bg-card text-foreground border-border hover:bg-secondary hover:border-primary/40';
  const btnDisabled =
    'bg-secondary text-muted-foreground border-border cursor-not-allowed opacity-50';

  return (
    <div className="flex flex-col sm:flex-row items-center justify-between gap-3 bg-card border border-border rounded-md px-4 py-2.5">
      {/* Row info */}
      <span className="text-xs text-muted-foreground">
        Showing rows {startRow}–{endRow} of {totalRows}
      </span>

      {/* Page controls */}
      <div className="flex items-center gap-1">
        {/* First */}
        <button
          onClick={() => onPageChange(1)}
          disabled={currentPage === 1}
          className={`${btnBase} ${currentPage === 1 ? btnDisabled : btnDefault}`}
          title="First page"
        >
          <ChevronsLeft size={14} />
        </button>

        {/* Prev */}
        <button
          onClick={() => onPageChange(currentPage - 1)}
          disabled={currentPage === 1}
          className={`${btnBase} ${currentPage === 1 ? btnDisabled : btnDefault}`}
          title="Previous page"
        >
          <ChevronLeft size={14} />
        </button>

        {/* Page numbers */}
        {pages.map((page, idx) =>
          page === 'ellipsis-start' || page === 'ellipsis-end' ? (
            <span
              key={`ellipsis-${idx}`}
              className="w-8 h-8 flex items-center justify-center text-muted-foreground text-sm"
            >
              …
            </span>
          ) : (
            <button
              key={`page-${page}`}
              onClick={() => onPageChange(page)}
              className={`${btnBase} ${page === currentPage ? btnActive : btnDefault}`}
            >
              {page}
            </button>
          )
        )}

        {/* Next */}
        <button
          onClick={() => onPageChange(currentPage + 1)}
          disabled={currentPage === totalPages}
          className={`${btnBase} ${currentPage === totalPages ? btnDisabled : btnDefault}`}
          title="Next page"
        >
          <ChevronRight size={14} />
        </button>

        {/* Last */}
        <button
          onClick={() => onPageChange(totalPages)}
          disabled={currentPage === totalPages}
          className={`${btnBase} ${currentPage === totalPages ? btnDisabled : btnDefault}`}
          title="Last page"
        >
          <ChevronsRight size={14} />
        </button>
      </div>

      {/* Page X of Y */}
      <span className="text-xs text-muted-foreground">
        Page {currentPage} of {totalPages}
      </span>
    </div>
  );
}