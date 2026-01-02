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
  // #region agent log
  fetch('http://127.0.0.1:7242/ingest/586d6044-ae66-4d74-8a2d-c8c0597a6fc9',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'overview.ts:19',message:'getOverview called',data:{path:'/api/v1/overview'},timestamp:Date.now(),sessionId:'debug-session',runId:'run1',hypothesisId:'C'})}).catch(()=>{});
  // #endregion
  const response = await api.get<OverviewResponse>('/api/v1/overview');
  // #region agent log
  fetch('http://127.0.0.1:7242/ingest/586d6044-ae66-4d74-8a2d-c8c0597a6fc9',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'overview.ts:21',message:'getOverview response received',data:{status:response.status,statusText:response.statusText},timestamp:Date.now(),sessionId:'debug-session',runId:'run1',hypothesisId:'C'})}).catch(()=>{});
  // #endregion
  return response.data;
};

