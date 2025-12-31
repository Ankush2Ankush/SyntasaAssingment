/**
 * Overview API service
 */
import api from './api';

export interface OverviewData {
  total_trips: number;
  start_date: string | null;
  end_date: string | null;
  zone_count: number;
  total_revenue: number;
}

export interface OverviewResponse {
  data: OverviewData;
  assumptions: Record<string, any>;
}

export const getOverview = async (): Promise<OverviewResponse> => {
  const response = await api.get<OverviewResponse>('/api/v1/overview');
  return response.data;
};

