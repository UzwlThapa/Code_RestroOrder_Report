'use client';

import React, { useState, useRef, useEffect } from 'react';
import { ChevronDown, RotateCcw, Check } from 'lucide-react';
import {
  type ReportConfig,
  type FilterState,
  BRANCH_OPTIONS,
  CATEGORY_OPTIONS,
  COST_CENTRE_OPTIONS,
} from '../data/reportData';

interface ReportFilterBarProps {
  config: ReportConfig;
  filters: FilterState;
  onFilterChange: (key: keyof FilterState, value: string | string[]) => void;
}

// Multi-select dropdown for cost centres
function CostCentreMultiSelect({
  selected,
  onChange,
}: {
  selected: string[];
  onChange: (vals: string[]) => void;
}) {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    function handleClick(e: MouseEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    }
    document.addEventListener('mousedown', handleClick);
    return () => document.removeEventListener('mousedown', handleClick);
  }, []);

  const toggle = (val: string) => {
    if (selected.includes(val)) {
      onChange(selected.filter((v) => v !== val));
    } else {
      onChange([...selected, val]);
    }
  };

  const label =
    selected.length === 0
      ? 'All Cost Centres'
      : selected.length === 1
      ? selected[0]
      : `${selected.length} selected`;

  return (
    <div ref={ref} className="relative">
      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        className="flex items-center gap-2 bg-background border border-border rounded text-sm text-foreground pl-3 pr-7 py-1.5 focus:outline-none focus:ring-2 focus:ring-ring cursor-pointer hover:border-primary/60 transition-colors w-48 text-left"
      >
        <span className="flex-1 truncate">{label}</span>
        <ChevronDown
          size={13}
          className={`absolute right-2 top-1/2 -translate-y-1/2 text-muted-foreground pointer-events-none transition-transform ${open ? 'rotate-180' : ''}`}
        />
      </button>

      {open && (
        <div className="absolute z-50 top-full left-0 mt-1 w-48 bg-card border border-border rounded shadow-md py-1">
          {/* All option */}
          <button
            type="button"
            onClick={() => { onChange([]); setOpen(false); }}
            className={`w-full flex items-center gap-2 px-3 py-1.5 text-sm text-left hover:bg-secondary transition-colors ${
              selected.length === 0 ? 'text-primary font-medium' : 'text-foreground'
            }`}
          >
            <span className="w-4 flex-shrink-0">
              {selected.length === 0 && <Check size={13} className="text-primary" />}
            </span>
            All Cost Centres
          </button>
          <div className="border-t border-border my-1" />
          {COST_CENTRE_OPTIONS.map((opt) => (
            <button
              key={opt.value}
              type="button"
              onClick={() => toggle(opt.value)}
              className="w-full flex items-center gap-2 px-3 py-1.5 text-sm text-left hover:bg-secondary transition-colors text-foreground"
            >
              <span className="w-4 flex-shrink-0">
                {selected.includes(opt.value) && <Check size={13} className="text-primary" />}
              </span>
              {opt.label}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

export default function ReportFilterBar({
  config,
  filters,
  onFilterChange,
}: ReportFilterBarProps) {
  const hasActiveFilters =
    filters.branch !== 'all' ||
    filters.category !== 'all' ||
    filters.costCentres.length > 0;

  return (
    <div className="flex flex-wrap items-end gap-4">
      {/* Date From */}
      <div className="flex flex-col gap-1">
        <label htmlFor="date-from" className="text-xs font-medium text-muted-foreground uppercase tracking-wide">
          From
        </label>
        <input
          id="date-from"
          type="date"
          value={filters.dateFrom}
          onChange={(e) => onFilterChange('dateFrom', e.target.value)}
          className="border border-border rounded text-sm text-foreground bg-background px-3 py-1.5 focus:outline-none focus:ring-2 focus:ring-ring w-36"
        />
      </div>

      {/* Date To */}
      <div className="flex flex-col gap-1">
        <label htmlFor="date-to" className="text-xs font-medium text-muted-foreground uppercase tracking-wide">
          To
        </label>
        <input
          id="date-to"
          type="date"
          value={filters.dateTo}
          onChange={(e) => onFilterChange('dateTo', e.target.value)}
          className="border border-border rounded text-sm text-foreground bg-background px-3 py-1.5 focus:outline-none focus:ring-2 focus:ring-ring w-36"
        />
      </div>

      {/* Divider */}
      <div className="h-8 w-px bg-border self-end mb-0.5 hidden sm:block" />

      {/* Branch */}
      {config.filters.includes('branch') && (
        <div className="flex flex-col gap-1">
          <label htmlFor="filter-branch" className="text-xs font-medium text-muted-foreground uppercase tracking-wide">
            Branch
          </label>
          <div className="relative">
            <select
              id="filter-branch"
              value={filters.branch}
              onChange={(e) => onFilterChange('branch', e.target.value)}
              className="appearance-none bg-background border border-border rounded text-sm text-foreground pl-3 pr-7 py-1.5 focus:outline-none focus:ring-2 focus:ring-ring cursor-pointer hover:border-primary/60 transition-colors w-44"
            >
              {BRANCH_OPTIONS.map((opt) => (
                <option key={opt.value} value={opt.value}>{opt.label}</option>
              ))}
            </select>
            <ChevronDown size={13} className="absolute right-2 top-1/2 -translate-y-1/2 text-muted-foreground pointer-events-none" />
          </div>
        </div>
      )}

      {/* Category */}
      {config.filters.includes('category') && (
        <div className="flex flex-col gap-1">
          <label htmlFor="filter-category" className="text-xs font-medium text-muted-foreground uppercase tracking-wide">
            Category
          </label>
          <div className="relative">
            <select
              id="filter-category"
              value={filters.category}
              onChange={(e) => onFilterChange('category', e.target.value)}
              className="appearance-none bg-background border border-border rounded text-sm text-foreground pl-3 pr-7 py-1.5 focus:outline-none focus:ring-2 focus:ring-ring cursor-pointer hover:border-primary/60 transition-colors w-40"
            >
              {CATEGORY_OPTIONS.map((opt) => (
                <option key={opt.value} value={opt.value}>{opt.label}</option>
              ))}
            </select>
            <ChevronDown size={13} className="absolute right-2 top-1/2 -translate-y-1/2 text-muted-foreground pointer-events-none" />
          </div>
        </div>
      )}

      {/* Cost Centre — multi-select */}
      {config.filters.includes('costCentre') && (
        <div className="flex flex-col gap-1">
          <label className="text-xs font-medium text-muted-foreground uppercase tracking-wide">
            Cost Centre
          </label>
          <CostCentreMultiSelect
            selected={filters.costCentres}
            onChange={(vals) => onFilterChange('costCentres', vals)}
          />
        </div>
      )}

      {/* Clear filters */}
      {hasActiveFilters && (
        <button
          onClick={() => {
            onFilterChange('branch', 'all');
            onFilterChange('category', 'all');
            onFilterChange('costCentres', []);
          }}
          className="flex items-center gap-1.5 text-xs font-medium text-primary hover:underline self-end pb-2 transition-colors"
        >
          <RotateCcw size={12} />
          Clear filters
        </button>
      )}
    </div>
  );
}