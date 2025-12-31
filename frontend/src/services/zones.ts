/**
 * Zones API service - Question 1
 */
import api from './api';

export interface ZoneRevenue {
  zone_id: number;
  trip_count: number;
  total_revenue: number;
  total_tips: number;
  total_amount: number;
  avg_fare: number;
  avg_distance: number;
  avg_duration_minutes: number;
}

export interface ZoneRevenueResponse {
  data: ZoneRevenue[];
  assumptions: Record<string, any>;
}

export interface ZoneNetProfit {
  zone_id: number;
  trip_count: number;
  gross_revenue: number;
  avg_duration_minutes: number;
  net_profit: number;
}

export interface ZoneNetProfitResponse {
  data: ZoneNetProfit[];
  assumptions: Record<string, any>;
}

export const getZoneRevenue = async (limit: number = 20): Promise<ZoneRevenueResponse> => {
  const response = await api.get<ZoneRevenueResponse>('/api/v1/zones/revenue', {
    params: { limit },
  });
  return response.data;
};

export const getZoneNetProfit = async (
  idleCostPerHour: number = 30.0
): Promise<ZoneNetProfitResponse> => {
  const response = await api.get<ZoneNetProfitResponse>('/api/v1/zones/net-profit', {
    params: { idle_cost_per_hour: idleCostPerHour },
  });
  return response.data;
};

export const getNegativeZones = async (
  idleCostPerHour: number = 30.0
): Promise<ZoneNetProfitResponse> => {
  const response = await api.get<ZoneNetProfitResponse>('/api/v1/zones/negative-zones', {
    params: { idle_cost_per_hour: idleCostPerHour },
  });
  return response.data;
};

