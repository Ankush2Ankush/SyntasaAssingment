/**
 * Question 1: High Revenue Zones with Hidden Costs
 */
import { Container, Typography, Grid, Paper, Box, Alert } from '@mui/material';
import { useQuery } from '@tanstack/react-query';
import { getZoneRevenue, getZoneNetProfit, getNegativeZones } from '../services/zones';
import BarChart from '../components/Charts/BarChart';
import ScatterChart from '../components/Charts/ScatterChart';
import LoadingSpinner from '../components/Common/LoadingSpinner';

const Question1 = () => {
  const { data: revenueData, isLoading: revenueLoading } = useQuery({
    queryKey: ['zone-revenue'],
    queryFn: () => getZoneRevenue(20),
  });

  const { data: netProfitData, isLoading: netProfitLoading } = useQuery({
    queryKey: ['zone-net-profit'],
    queryFn: () => getZoneNetProfit(30.0),
  });

  const { data: negativeZonesData, isLoading: negativeZonesLoading } = useQuery({
    queryKey: ['negative-zones'],
    queryFn: () => getNegativeZones(30.0),
  });

  if (revenueLoading || netProfitLoading || negativeZonesLoading) {
    return <LoadingSpinner />;
  }

  // Prepare chart data
  const revenueChartData = revenueData
    ? {
        labels: revenueData.data.map((z) => `Zone ${z.zone_id}`),
        datasets: [
          {
            label: 'Total Revenue',
            data: revenueData.data.map((z) => z.total_revenue),
            backgroundColor: 'rgba(54, 162, 235, 0.6)',
            borderColor: 'rgba(54, 162, 235, 1)',
          },
        ],
      }
    : null;

  const scatterData = netProfitData
    ? {
        datasets: [
          {
            label: 'Revenue vs Net Profit',
            data: netProfitData.data.map((z) => ({
              x: z.gross_revenue,
              y: z.net_profit,
            })),
            backgroundColor: 'rgba(255, 99, 132, 0.6)',
            borderColor: 'rgba(255, 99, 132, 1)',
          },
        ],
      }
    : null;

  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      <Typography variant="h4" component="h1" gutterBottom>
        Question 1: High Revenue Zones with Hidden Costs
      </Typography>
      <Typography variant="body1" paragraph>
        Which pickup zones appear to be high revenue zones but become net negative once idle time,
        trip duration, and empty return probability are accounted for?
      </Typography>

      {revenueData?.assumptions && (
        <Alert severity="info" sx={{ mb: 3 }}>
          <Typography variant="body2">
            <strong>Assumptions:</strong> {JSON.stringify(revenueData.assumptions, null, 2)}
          </Typography>
        </Alert>
      )}

      <Grid container spacing={3}>
        <Grid item xs={12}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Top 20 Zones by Revenue
            </Typography>
            {revenueChartData && (
              <BarChart
                data={revenueChartData}
                title="Total Revenue by Zone"
                xAxisLabel="Zone ID"
                yAxisLabel="Revenue ($)"
              />
            )}
          </Paper>
        </Grid>

        <Grid item xs={12}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Revenue vs Net Profit
            </Typography>
            {scatterData && (
              <ScatterChart
                data={scatterData}
                title="Gross Revenue vs Net Profit (after costs)"
                xAxisLabel="Gross Revenue ($)"
                yAxisLabel="Net Profit ($)"
              />
            )}
          </Paper>
        </Grid>

        {negativeZonesData && negativeZonesData.data.length > 0 && (
          <Grid item xs={12}>
            <Paper sx={{ p: 3 }}>
              <Typography variant="h6" gutterBottom>
                Zones That Become Net Negative
              </Typography>
              <Box sx={{ mt: 2 }}>
                {negativeZonesData.data.map((zone) => (
                  <Box key={zone.zone_id} sx={{ mb: 1 }}>
                    <Typography>
                      Zone {zone.zone_id}: Net Profit = ${zone.net_profit?.toFixed(2)} (Gross
                      Revenue: ${zone.gross_revenue?.toFixed(2)})
                    </Typography>
                  </Box>
                ))}
              </Box>
            </Paper>
          </Grid>
        )}
      </Grid>
    </Container>
  );
};

export default Question1;

