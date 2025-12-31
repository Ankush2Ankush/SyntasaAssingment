/**
 * Question 3: Surge Pricing Paradox
 */
import { Container, Typography, Grid, Paper, Alert } from '@mui/material';
import { useQuery } from '@tanstack/react-query';
import { getSurgeCorrelation } from '../services/surge';
import ScatterChart from '../components/Charts/ScatterChart';
import BarChart from '../components/Charts/BarChart';
import LoadingSpinner from '../components/Common/LoadingSpinner';

const Question3 = () => {
  const { data: correlationData, isLoading } = useQuery({
    queryKey: ['surge-correlation'],
    queryFn: () => getSurgeCorrelation(0.2),
  });

  if (isLoading) {
    return <LoadingSpinner />;
  }

  // Prepare scatter chart data
  const scatterData = correlationData
    ? {
        datasets: [
          {
            label: 'Surge Events vs Daily Revenue',
            data: correlationData.data.map((z) => ({
              x: z.avg_surge_events,
              y: z.avg_daily_revenue,
            })),
            backgroundColor: 'rgba(153, 102, 255, 0.6)',
            borderColor: 'rgba(153, 102, 255, 1)',
          },
        ],
      }
    : null;

  // Top zones by surge events
  const topSurgeZones = correlationData
    ? correlationData.data
        .sort((a, b) => b.avg_surge_events - a.avg_surge_events)
        .slice(0, 10)
    : [];

  const barChartData = topSurgeZones.length > 0
    ? {
        labels: topSurgeZones.map((z) => `Zone ${z.zone_id}`),
        datasets: [
          {
            label: 'Avg Surge Events',
            data: topSurgeZones.map((z) => z.avg_surge_events),
            backgroundColor: 'rgba(255, 159, 64, 0.6)',
            borderColor: 'rgba(255, 159, 64, 1)',
          },
          {
            label: 'Avg Daily Revenue',
            data: topSurgeZones.map((z) => z.avg_daily_revenue),
            backgroundColor: 'rgba(75, 192, 192, 0.6)',
            borderColor: 'rgba(75, 192, 192, 1)',
          },
        ],
      }
    : null;

  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      <Typography variant="h4" component="h1" gutterBottom>
        Question 3: Surge Pricing Paradox
      </Typography>
      <Typography variant="body1" paragraph>
        Identify zones where surge-like pricing correlates with lower total daily revenue, and
        explain the mechanism using the data.
      </Typography>

      {correlationData?.assumptions && (
        <Alert severity="info" sx={{ mb: 3 }}>
          <Typography variant="body2">
            <strong>Assumptions:</strong> {JSON.stringify(correlationData.assumptions, null, 2)}
          </Typography>
        </Alert>
      )}

      <Grid container spacing={3}>
        <Grid item xs={12}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Surge Events vs Daily Revenue Correlation
            </Typography>
            <Typography variant="body2" paragraph>
              Zones with negative correlation (high surge events, low revenue) indicate the surge
              pricing paradox.
            </Typography>
            {scatterData && (
              <ScatterChart
                data={scatterData}
                title="Surge Frequency vs Average Daily Revenue"
                xAxisLabel="Average Surge Events per Day"
                yAxisLabel="Average Daily Revenue ($)"
              />
            )}
          </Paper>
        </Grid>

        <Grid item xs={12}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Top 10 Zones by Surge Events
            </Typography>
            {barChartData && (
              <BarChart
                data={barChartData}
                title="Surge Events vs Revenue Comparison"
                xAxisLabel="Zone ID"
                yAxisLabel="Value"
              />
            )}
          </Paper>
        </Grid>
      </Grid>
    </Container>
  );
};

export default Question3;

