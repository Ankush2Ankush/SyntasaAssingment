/**
 * Variability API service - Question 7
 */
import api from './api';

export interface VariabilityHeatmap {
  hour_of_day: number;
  distance_bin: string;
  trip_count: number;
  mean_duration: number;
  std_duration: number;
  coefficient_of_variation: number;
}

export interface VariabilityHeatmapResponse {
  data: VariabilityHeatmap[];
  assumptions: Record<string, any>;
}

export interface DurationDistribution {
  hour_of_day: number;
  trip_count: number;
  min_duration: number;
  mean_duration: number;
  max_duration: number;
  std_duration: number;
  p25_duration?: number;
  median_duration?: number;
  p75_duration?: number;
}

export interface DurationDistributionResponse {
  data: DurationDistribution[];
  assumptions: Record<string, any>;
}

export interface VariabilityTrend {
  date: string;
  hour_of_day: number;
  trip_count: number;
  mean_duration: number;
  std_duration: number;
  coefficient_of_variation: number;
}

export interface VariabilityTrendResponse {
  data: VariabilityTrend[];
  assumptions: Record<string, any>;
}

export const getVariabilityHeatmap = async (): Promise<VariabilityHeatmapResponse> => {
  const response = await api.get<VariabilityHeatmapResponse>('/api/v1/variability/heatmap');
  return response.data;
};

export const getDurationDistribution = async (): Promise<DurationDistributionResponse> => {
  const response = await api.get<DurationDistributionResponse>('/api/v1/variability/distribution');
  return response.data;
};

export const getVariabilityTrends = async (): Promise<VariabilityTrendResponse> => {
  const response = await api.get<VariabilityTrendResponse>('/api/v1/variability/trends');
  return response.data;
};

