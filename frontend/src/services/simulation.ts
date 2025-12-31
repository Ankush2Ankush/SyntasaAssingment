/**
 * Simulation API service - Question 8
 */
import api from './api';

export interface SimulationResult {
  threshold_miles: number;
  before: {
    total_trips: number;
    total_revenue: number;
    avg_duration_minutes: number;
    trips_below_threshold: number;
  };
  after: {
    total_trips: number;
    total_revenue: number;
    avg_duration_minutes: number;
  };
  impact: {
    trips_removed: number;
    trips_removed_percentage: number;
    revenue_impact: number;
    revenue_impact_percentage: number;
    avg_duration_change: number;
  };
}

export interface SimulationResponse {
  data: SimulationResult;
  assumptions: Record<string, any>;
}

export interface SensitivityResult {
  threshold: number;
  total_trips: number;
  trips_removed: number;
  trips_removed_percentage: number;
  revenue_before: number;
  revenue_after: number;
  revenue_impact_percentage: number;
}

export interface SensitivityResponse {
  data: SensitivityResult[];
  assumptions: Record<string, any>;
}

export const simulateMinDistance = async (
  threshold: number = 1.0
): Promise<SimulationResponse> => {
  const response = await api.get<SimulationResponse>('/api/v1/simulation/min-distance', {
    params: { threshold },
  });
  return response.data;
};

export const getSensitivityAnalysis = async (): Promise<SensitivityResponse> => {
  const response = await api.get<SensitivityResponse>('/api/v1/simulation/sensitivity');
  return response.data;
};

