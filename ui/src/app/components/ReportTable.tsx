'use client';

import React from 'react';
import { ArrowUpDown, ArrowUp, ArrowDown } from 'lucide-react';
import { type ReportConfig, type ReportColumn, formatRs } from '../data/reportData';
import CategoryBadge from './CategoryBadge';

interface ReportTableProps {
  config: ReportConfig;
  data: Record<string, unknown>[];
  allData: Record<string, unknown>[];
  sortColumn: string;
  sortDirection: 'asc' | 'desc';
  onSort: (column: string) => void;
  showTotals: boolean;
}

function getCellDisplay(
  col: ReportColumn,
  row: Record<string, unknown>
): React.ReactNode {
  const val = row[col.key];

  if (col.type === 'currency') {
    return (
      <span className="tabular-nums">{formatRs(val as number)}</span>
    );
  }
  if (col.type === 'number') {
    return (
      <span className="tabular-nums">
        {typeof val === 'number' ? val.toLocaleString('en-IN') : String(val ?? '')}
      </span>
    );
  }
  if (col.type === 'percent') {
    return (
      <span className="tabular-nums">
        {typeof val === 'number' ? val.toFixed(1) + '%' : String(val ?? '')}
      </span>
    );
  }
  if (col.type === 'badge') {
    return <CategoryBadge value={String(val ?? '')} />;
  }
  return <span>{String(val ?? '')}</span>;
}

function getTotalsCell(col: ReportColumn, allData: Record<string, unknown>[]): React.ReactNode {
  if (col.key === 'itemName' || col.key === 'date' || col.key === 'description') {
    return <span className="font-semibold text-foreground">TOTAL</span>;
  }
  if (col.totalsMethod === 'sum' && col.type === 'currency') {
    const sum = allData.reduce((acc, row) => acc + ((row[col.key] as number) || 0), 0);
    return <span className="tabular-nums font-semibold">{formatRs(sum)}</span>;
  }
  if (col.totalsMethod === 'sum' && col.type === 'number') {
    const sum = allData.reduce((acc, row) => acc + ((row[col.key] as number) || 0), 0);
    return <span className="tabular-nums font-semibold">{sum.toLocaleString('en-IN')}</span>;
  }
  if (col.totalsMethod === 'avg' && col.type === 'percent') {
    const avg = allData.reduce((acc, row) => acc + ((row[col.key] as number) || 0), 0) / (allData.length || 1);
    return <span className="tabular-nums font-semibold">{avg.toFixed(1)}%</span>;
  }
  if (col.totalsMethod === 'avg' && col.type === 'currency') {
    const avg = allData.reduce((acc, row) => acc + ((row[col.key] as number) || 0), 0) / (allData.length || 1);
    return <span className="tabular-nums font-semibold">{formatRs(avg)}</span>;
  }
  return <span className="text-muted-foreground">—</span>;
}

export default function ReportTable({
  config,
  data,
  allData,
  sortColumn,
  sortDirection,
  onSort,
  showTotals,
}: ReportTableProps) {
  return (
    <div className="bg-card border border-border rounded-md overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full text-sm border-collapse">
          <thead>
            <tr className="bg-secondary border-b border-border">
              {/* Row number column */}
              <th className="text-left px-3 py-2.5 text-xs font-medium text-muted-foreground w-10 border-r border-border">
                #
              </th>
              {config.columns.map((col) => (
                <th
                  key={`th-${col.key}`}
                  className={`px-3 py-2.5 text-xs font-medium text-muted-foreground uppercase tracking-wide whitespace-nowrap border-r border-border last:border-r-0 ${
                    col.align === 'right' ? 'text-right' : col.align === 'center' ? 'text-center' : 'text-left'
                  } ${col.sortable ? 'cursor-pointer select-none hover:bg-border/60 transition-colors group' : ''} ${
                    sortColumn === col.key ? 'bg-primary/5 text-primary' : ''
                  }`}
                  onClick={col.sortable ? () => onSort(col.key) : undefined}
                  title={col.sortable ? `Sort by ${col.label}` : undefined}
                >
                  <span className="inline-flex items-center gap-1">
                    {col.label}
                    {col.sortable && (
                      <span className="opacity-40 group-hover:opacity-100 transition-opacity">
                        {sortColumn === col.key ? (
                          sortDirection === 'asc' ? (
                            <ArrowUp size={12} className="text-primary opacity-100" />
                          ) : (
                            <ArrowDown size={12} className="text-primary opacity-100" />
                          )
                        ) : (
                          <ArrowUpDown size={11} />
                        )}
                      </span>
                    )}
                  </span>
                </th>
              ))}
            </tr>
          </thead>

          <tbody>
            {data.map((row, rowIdx) => {
              const rowId = (row.id as string) || `row-${rowIdx + 1}`;
              const isEven = rowIdx % 2 === 0;
              return (
                <tr
                  key={`tr-${rowId}`}
                  className={`border-b border-border last:border-b-0 hover:bg-primary/5 transition-colors ${
                    isEven ? 'bg-card' : 'bg-secondary/30'
                  }`}
                >
                  <td className="px-3 py-2.5 text-xs text-muted-foreground tabular-nums border-r border-border">
                    {rowIdx + 1}
                  </td>
                  {config.columns.map((col) => (
                    <td
                      key={`td-${rowId}-${col.key}`}
                      className={`px-3 py-2.5 text-foreground border-r border-border last:border-r-0 ${
                        col.align === 'right' ?'text-right'
                          : col.align === 'center' ?'text-center' :'text-left'
                      } ${sortColumn === col.key ? 'bg-primary/[0.03]' : ''}`}
                    >
                      {getCellDisplay(col, row)}
                    </td>
                  ))}
                </tr>
              );
            })}
          </tbody>

          {/* Totals row */}
          {showTotals && (
            <tfoot>
              <tr className="border-t-2 border-primary/20 bg-blue-50">
                <td className="px-3 py-2.5 text-xs text-muted-foreground border-r border-border" />
                {config.columns.map((col) => (
                  <td
                    key={`totals-${col.key}`}
                    className={`px-3 py-2.5 text-sm border-r border-border last:border-r-0 ${
                      col.align === 'right' ?'text-right'
                        : col.align === 'center' ?'text-center' :'text-left'
                    }`}
                  >
                    {getTotalsCell(col, allData)}
                  </td>
                ))}
              </tr>
            </tfoot>
          )}
        </table>
      </div>

      {/* Table footer info */}
      <div className="print-hidden px-4 py-2 border-t border-border bg-secondary/20 flex items-center justify-between">
        <span className="text-xs text-muted-foreground">
          Showing {data.length} of {allData.length} rows
        </span>
        <span className="text-xs text-muted-foreground">
          Last updated: 10/09/2026, 04:40
        </span>
      </div>
    </div>
  );
}