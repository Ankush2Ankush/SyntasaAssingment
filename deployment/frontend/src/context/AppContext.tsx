/**
 * Main application context for global state
 */
import { createContext, useContext, useState, ReactNode } from 'react';

interface AppState {
  selectedZones: number[];
  dateRange: { start: Date; end: Date };
}

interface AppContextType extends AppState {
  setSelectedZones: (zones: number[]) => void;
  setDateRange: (range: { start: Date; end: Date }) => void;
}

const AppContext = createContext<AppContextType | undefined>(undefined);

export const AppProvider = ({ children }: { children: ReactNode }) => {
  const [selectedZones, setSelectedZones] = useState<number[]>([]);
  const [dateRange, setDateRange] = useState<{ start: Date; end: Date }>({
    start: new Date('2025-01-01'),
    end: new Date('2025-04-30'),
  });

  return (
    <AppContext.Provider
      value={{
        selectedZones,
        dateRange,
        setSelectedZones,
        setDateRange,
      }}
    >
      {children}
    </AppContext.Provider>
  );
};

export const useApp = () => {
  const context = useContext(AppContext);
  if (!context) {
    throw new Error('useApp must be used within AppProvider');
  }
  return context;
};

