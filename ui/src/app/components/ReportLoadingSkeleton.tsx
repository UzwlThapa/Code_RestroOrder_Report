import React from 'react';

interface ReportLoadingSkeletonProps {
  columns: number;
}

export default function ReportLoadingSkeleton({ columns }: ReportLoadingSkeletonProps) {
  const rows = Array.from({ length: 8 });
  const cols = Array.from({ length: columns });

  return (
    <div className="bg-card border border-border rounded-md overflow-hidden">
      {/* Header skeleton */}
      <div className="bg-secondary border-b border-border px-3 py-2.5 flex gap-3">
        <div className="w-8 h-4 rounded animate-pulse bg-border" />
        {cols.map((_, ci) => (
          <div
            key={`skel-th-${ci}`}
            className="h-4 rounded animate-pulse bg-border flex-1"
            style={{ transitionDelay: `${ci * 30}ms` }}
          />
        ))}
      </div>

      {/* Row skeletons */}
      {rows.map((_, ri) => (
        <div
          key={`skel-row-${ri}`}
          className={`flex gap-3 px-3 py-3 border-b border-border last:border-b-0 ${
            ri % 2 === 0 ? 'bg-card' : 'bg-secondary/20'
          }`}
        >
          <div className="w-8 h-3.5 rounded animate-pulse bg-border opacity-60" />
          {cols.map((_, ci) => (
            <div
              key={`skel-cell-${ri}-${ci}`}
              className="h-3.5 rounded animate-pulse bg-border flex-1 opacity-60"
              style={{ transitionDelay: `${(ri * columns + ci) * 15}ms` }}
            />
          ))}
        </div>
      ))}

      {/* Footer skeleton */}
      <div className="px-4 py-2 border-t border-border bg-secondary/20 flex justify-between">
        <div className="w-32 h-3 rounded animate-pulse bg-border opacity-50" />
        <div className="w-40 h-3 rounded animate-pulse bg-border opacity-50" />
      </div>
    </div>
  );
}