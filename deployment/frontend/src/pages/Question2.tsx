/**
 * Question 2: Demand vs Efficiency Trade-offs
 */
import { Container, Typography, Grid, Paper, Alert } from '@mui/material';
import { useQuery } from '@tanstack/react-query';
import {
  getEfficiencyTimeSeries,
  getEfficiencyHeatmap,
  getDemandEfficiencyCorrelation,
} from '../services/efficiency';
import LineChart from '../components/Charts/LineChart';
import ScatterChart from '../components/Charts/ScatterChart';
import LoadingSpinner from '../components/Common/LoadingSpinner';

const Question2 = () => {
  const { data: timeSeriesData, isLoading: timeSeriesLoading } = useQuery({
    queryKey: ['efficiency-timeseries'],
    queryFn: getEfficiencyTimeSeries,
  });

  const { data: correlationData, isLoading: correlationLoading } = useQuery({
    queryKey: ['demand-efficiency-correlation'],
    queryFn: getDemandEfficiencyCorrelation,
  });

  if (timeSeriesLoading || correlationLoading) {
    return <LoadingSpinner />;
  }

  // Prepare time series chart data
  const timeSeriesChartData = timeSeriesData
    ? {
        labels: timeSeriesData.data.map((d) => new Date(d.hour).toLocaleString()),
        datasets: [
          {
            label: 'Total Trips',
            data: timeSeriesData.data.map((d) => d.total_trips),
            borderColor: 'rgba(54, 162, 235, 1)',
            backgroundColor: 'rgba(54, 162, 235, 0.1)',
            yAxisID: 'y',
          },
          {
            label: 'System Efficiency',
            data: timeSeriesData.data.map((d) => d.efficiency || 0),
            borderColor: 'rgba(255, 99, 132, 1)',
            backgroundColor: 'rgba(255, 99, 132, 0.1)',
            yAxisID: 'y1',
          },
        ],
      }
    : null;

  // Prepare correlation scatter data
  const correlationScatterData = correlationData
    ? {
        datasets: [
          {
            label: 'Demand vs Efficiency',
            data: correlationData.data.map((d) => ({
              x: d.demand_trips || 0,
              y: d.efficiency || 0,
            })),
            backgroundColor: 'rgba(75, 192, 192, 0.6)',
            borderColor: 'rgba(75, 192, 192, 1)',
          },
        ],
      }
    : null;

  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      <Typography variant="h4" component="h1" gutterBottom>
        Question 2: Demand vs Efficiency Trade-offs
      </Typography>
      <Typography variant="body1" paragraph>
        At what times does increased demand reduce overall system efficiency, even though total trips
        increase?
      </Typography>

      {timeSeriesData?.assumptions && (
        <Alert severity="info" sx={{ mb: 3 }}>
          <Typography variant="body2">
            <strong>Assumptions:</strong> {JSON.stringify(timeSeriesData.assumptions, null, 2)}
          </Typography>
        </Alert>
      )}

      <Grid container spacing={3}>
        <Grid item xs={12}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Total Trips vs System Efficiency Over Time
            </Typography>
            {timeSeriesChartData && (
              <LineChart
                data={timeSeriesChartData}
                title="Demand and Efficiency Over Time"
                xAxisLabel="Time"
                yAxisLabel="Value"
              />
            )}
          </Paper>
        </Grid>

        <Grid item xs={12}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Demand vs Efficiency Correlation
            </Typography>
            <Typography variant="body2" paragraph>
              Points below the trend line indicate times when increased demand reduces efficiency.
            </Typography>
            {correlationScatterData && (
              <ScatterChart
                data={correlationScatterData}
                title="Demand (Trips) vs System Efficiency"
                xAxisLabel="Demand (Total Trips)"
                yAxisLabel="System Efficiency"
              />
            )}
          </Paper>
        </Grid>
      </Grid>
    </Container>
  );
};

export default Question2;

