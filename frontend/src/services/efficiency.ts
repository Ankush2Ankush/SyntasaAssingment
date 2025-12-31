/**
 * Efficiency API service - Question 2
 */
import api from './api';

export interface EfficiencyTimeSeries {
  hour: string;
  total_trips: number;
  total_revenue: number;
  avg_duration_minutes: number;
  efficiency: number;
}

export interface EfficiencyTimeSeriesResponse {
  data: EfficiencyTimeSeries[];
  assumptions: Record<string, any>;
}

export interface EfficiencyHeatmap {
  day_of_week: number;
  hour_of_day: number;
  total_trips: number;
  total_revenue: number;
  efficiency: number;
}

export interface EfficiencyHeatmapResponse {
  data: EfficiencyHeatmap[];
  assumptions: Record<string, any>;
}

export const getEfficiencyTimeSeries = async (): Promise<EfficiencyTimeSeriesResponse> => {
  const response = await api.get<EfficiencyTimeSeriesResponse>('/api/v1/efficiency/timeseries');
  return response.data;
};

export const getEfficiencyHeatmap = async (): Promise<EfficiencyHeatmapResponse> => {
  const response = await api.get<EfficiencyHeatmapResponse>('/api/v1/efficiency/heatmap');
  return response.data;
};

export const getDemandEfficiencyCorrelation = async (): Promise<EfficiencyTimeSeriesResponse> => {
  const response = await api.get<EfficiencyTimeSeriesResponse>(
    '/api/v1/efficiency/demand-correlation'
  );
  return response.data;
};

