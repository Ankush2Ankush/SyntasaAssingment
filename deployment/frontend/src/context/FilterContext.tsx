/**
 * Filter context for dashboard filters
 */
import { createContext, useContext, useState, ReactNode } from 'react';

interface FilterState {
  dateRange: { start: Date; end: Date };
  selectedZones: number[];
  selectedMetrics: string[];
}

interface FilterContextType extends FilterState {
  setDateRange: (range: { start: Date; end: Date }) => void;
  setSelectedZones: (zones: number[]) => void;
  setSelectedMetrics: (metrics: string[]) => void;
}

const FilterContext = createContext<FilterContextType | undefined>(undefined);

export const FilterProvider = ({ children }: { children: ReactNode }) => {
  const [dateRange, setDateRange] = useState<{ start: Date; end: Date }>({
    start: new Date('2025-01-01'),
    end: new Date('2025-04-30'),
  });
  const [selectedZones, setSelectedZones] = useState<number[]>([]);
  const [selectedMetrics, setSelectedMetrics] = useState<string[]>([]);

  return (
    <FilterContext.Provider
      value={{
        dateRange,
        selectedZones,
        selectedMetrics,
        setDateRange,
        setSelectedZones,
        setSelectedMetrics,
      }}
    >
      {children}
    </FilterContext.Provider>
  );
};

export const useFilter = () => {
  const context = useContext(FilterContext);
  if (!context) {
    throw new Error('useFilter must be used within FilterProvider');
  }
  return context;
};

