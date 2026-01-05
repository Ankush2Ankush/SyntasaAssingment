/**
 * Wait Time API service - Question 4
 */
import api from './api';

export interface WaitTimeData {
  zone_id: number;
  hour: string;
  demand: number;
  supply: number;
  wait_time_proxy: number | null;
}

export interface WaitTimeResponse {
  data: WaitTimeData[];
  assumptions: Record<string, any>;
}

export interface WaitTimeSimulationResponse {
  data: {
    lever: string;
    reduction_target: number;
    simulated_wait_time_reduction: number;
    impact: string;
  };
  assumptions: Record<string, any>;
}

export interface WaitTimeTradeoffsResponse {
  data: {
    lever_1: {
      name: string;
      benefits: string[];
      tradeoffs: string[];
    };
    lever_2: {
      name: string;
      benefits: string[];
      tradeoffs: string[];
    };
  };
  assumptions: Record<string, any>;
}

export const getCurrentWaitTime = async (): Promise<WaitTimeResponse> => {
  const response = await api.get<WaitTimeResponse>('/api/v1/wait-time/current');
  return response.data;
};

export const simulateWaitTimeReduction = async (
  lever: string = 'vehicle_distribution',
  reductionTarget: number = 0.1
): Promise<WaitTimeSimulationResponse> => {
  const response = await api.post<WaitTimeSimulationResponse>('/api/v1/wait-time/simulate', null, {
    params: {
      lever,
      reduction_target: reductionTarget,
    },
  });
  return response.data;
};

export const getWaitTimeTradeoffs = async (): Promise<WaitTimeTradeoffsResponse> => {
  const response = await api.get<WaitTimeTradeoffsResponse>('/api/v1/wait-time/tradeoffs');
  return response.data;
};


