/**
 * Surge Pricing API service - Question 3
 */
import api from './api';

export interface SurgeEvent {
  tpep_pickup_datetime: string;
  zone_id: number;
  fare_amount: number;
  median_fare: number;
  is_surge: number;
}

export interface SurgeEventResponse {
  data: SurgeEvent[];
  assumptions: Record<string, any>;
}

export interface SurgeCorrelation {
  zone_id: number;
  avg_surge_events: number;
  avg_daily_revenue: number;
  days_with_data: number;
}

export interface SurgeCorrelationResponse {
  data: SurgeCorrelation[];
  assumptions: Record<string, any>;
}

export const getSurgeEvents = async (threshold: number = 0.2): Promise<SurgeEventResponse> => {
  const response = await api.get<SurgeEventResponse>('/api/v1/surge/events', {
    params: { threshold },
  });
  return response.data;
};

export const getSurgeCorrelation = async (
  threshold: number = 0.2
): Promise<SurgeCorrelationResponse> => {
  const response = await api.get<SurgeCorrelationResponse>('/api/v1/surge/correlation', {
    params: { threshold },
  });
  return response.data;
};

