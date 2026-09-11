import React from 'react';
import { FileSearch, RotateCcw } from 'lucide-react';

interface ReportEmptyStateProps {
  reportName: string;
  onClearFilters: () => void;
}

export default function ReportEmptyState({
  reportName,
  onClearFilters,
}: ReportEmptyStateProps) {
  return (
    <div className="bg-card border border-border rounded-md flex flex-col items-center justify-center py-16 px-8 text-center">
      <div className="w-14 h-14 rounded-full bg-secondary flex items-center justify-center mb-4">
        <FileSearch size={28} className="text-muted-foreground" />
      </div>
      <h3 className="text-base font-semibold text-foreground mb-1">
        No data for selected filters
      </h3>
      <p className="text-sm text-muted-foreground max-w-sm mb-5">
        The <strong>{reportName}</strong> returned no rows for the current date range and
        filter combination. Try adjusting the date range or clearing the active filters.
      </p>
      <button
        onClick={onClearFilters}
        className="flex items-center gap-2 px-4 py-2 rounded border border-border bg-card text-sm font-medium text-foreground hover:bg-secondary hover:border-primary/40 transition-colors active:scale-95"
      >
        <RotateCcw size={14} />
        Clear filters and show all rows
      </button>
    </div>
  );
}