import React from 'react';

interface CategoryBadgeProps {
  value: string;
}

const BADGE_STYLES: Record<string, string> = {
  Top: 'bg-green-100 text-green-800 border border-green-200',
  Low: 'bg-yellow-100 text-yellow-800 border border-yellow-200',
  Dead: 'bg-red-100 text-red-800 border border-red-200',
  // IRD Sales statuses
  Reconciled: 'bg-green-100 text-green-800 border border-green-200',
  Pending: 'bg-yellow-100 text-yellow-800 border border-yellow-200',
  Voided: 'bg-red-100 text-red-800 border border-red-200',
  // Cost centre statuses
  Approved: 'bg-green-100 text-green-800 border border-green-200',
  'Under Review': 'bg-yellow-100 text-yellow-800 border border-yellow-200',
  Rejected: 'bg-red-100 text-red-800 border border-red-200',
};

export default function CategoryBadge({ value }: CategoryBadgeProps) {
  const style =
    BADGE_STYLES[value] ?? 'bg-slate-100 text-slate-700 border border-slate-200';
  return (
    <span
      className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${style}`}
    >
      {value}
    </span>
  );
}