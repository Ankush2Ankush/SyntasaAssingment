/**
 * Incentives API service - Question 6
 */
import api from './api';

export interface DriverIncentive {
  zone_id: number;
  hour_of_day: number;
  trip_count: number;
  avg_earnings_per_trip: number;
  avg_duration_minutes: number;
  driver_incentive_score: number;
}

export interface DriverIncentiveResponse {
  data: DriverIncentive[];
  assumptions: Record<string, any>;
}

export interface SystemEfficiency {
  zone_id: number;
  hour_of_day: number;
  trip_count: number;
  total_revenue: number;
  avg_duration_minutes: number;
  system_efficiency_score: number;
}

export interface SystemEfficiencyResponse {
  data: SystemEfficiency[];
  assumptions: Record<string, any>;
}

export interface IncentiveMisalignment {
  zone_id: number;
  hour_of_day: number;
  driver_score: number;
  system_score: number;
  is_misaligned: number;
}

export interface IncentiveMisalignmentResponse {
  data: IncentiveMisalignment[];
  assumptions: Record<string, any>;
}

export const getDriverIncentives = async (): Promise<DriverIncentiveResponse> => {
  const response = await api.get<DriverIncentiveResponse>('/api/v1/incentives/driver');
  return response.data;
};

export const getSystemEfficiency = async (): Promise<SystemEfficiencyResponse> => {
  const response = await api.get<SystemEfficiencyResponse>('/api/v1/incentives/system');
  return response.data;
};

export const getIncentiveMisalignment = async (): Promise<IncentiveMisalignmentResponse> => {
  const response = await api.get<IncentiveMisalignmentResponse>('/api/v1/incentives/misalignment');
  return response.data;
};

