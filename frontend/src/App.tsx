/**
 * Main App component with routing and providers
 */
import { lazy, Suspense } from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AppProvider } from './context/AppContext';
import { FilterProvider } from './context/FilterContext';
import LoadingSpinner from './components/Common/LoadingSpinner';
import './utils/chartConfig'; // Initialize Chart.js

// Lazy load page components
const Overview = lazy(() => import('./pages/Overview'));
const Question1 = lazy(() => import('./pages/Question1'));
const Question2 = lazy(() => import('./pages/Question2'));
const Question3 = lazy(() => import('./pages/Question3'));
const Question4 = lazy(() => import('./pages/Question4'));
const Question5 = lazy(() => import('./pages/Question5'));
const Question6 = lazy(() => import('./pages/Question6'));
const Question7 = lazy(() => import('./pages/Question7'));
const Question8 = lazy(() => import('./pages/Question8'));
const Assumptions = lazy(() => import('./pages/Assumptions'));

// Create React Query client
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 1,
      staleTime: 5 * 60 * 1000, // 5 minutes
      refetchOnMount: true,
      refetchOnReconnect: true,
    },
  },
});

import Header from './components/Layout/Header';

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AppProvider>
        <FilterProvider>
          <BrowserRouter
            future={{
              v7_startTransition: true,
              v7_relativeSplatPath: true,
            }}
          >
            <Header />
            <Suspense fallback={<LoadingSpinner />}>
              <Routes>
                <Route path="/" element={<Overview />} />
                <Route path="/question1" element={<Question1 />} />
                <Route path="/question2" element={<Question2 />} />
                <Route path="/question3" element={<Question3 />} />
                <Route path="/question4" element={<Question4 />} />
                <Route path="/question5" element={<Question5 />} />
                <Route path="/question6" element={<Question6 />} />
                <Route path="/question7" element={<Question7 />} />
                <Route path="/question8" element={<Question8 />} />
                <Route path="/assumptions" element={<Assumptions />} />
              </Routes>
            </Suspense>
          </BrowserRouter>
        </FilterProvider>
      </AppProvider>
    </QueryClientProvider>
  );
}

export default App;

