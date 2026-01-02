/**
 * Question 7: Trip Duration Variability
 */
import { Container, Typography, Grid, Paper, Alert, Box } from '@mui/material';
import { useQuery } from '@tanstack/react-query';
import {
  getVariabilityHeatmap,
  getDurationDistribution,
  getVariabilityTrends,
} from '../services/variability';
import BarChart from '../components/Charts/BarChart';
import LineChart from '../components/Charts/LineChart';
import LoadingSpinner from '../components/Common/LoadingSpinner';

const Question7 = () => {
  const { data: heatmapData, isLoading: heatmapLoading } = useQuery({
    queryKey: ['variability-heatmap'],
    queryFn: getVariabilityHeatmap,
  });

  const { data: distributionData, isLoading: distributionLoading } = useQuery({
    queryKey: ['duration-distribution'],
    queryFn: getDurationDistribution,
  });

  const { data: trendsData, isLoading: trendsLoading } = useQuery({
    queryKey: ['variability-trends'],
    queryFn: getVariabilityTrends,
  });

  if (heatmapLoading || distributionLoading || trendsLoading) {
    return <LoadingSpinner />;
  }

  // Prepare heatmap data: Coefficient of Variation by hour and distance bin
  const topVariabilityHours = heatmapData
    ? heatmapData.data
        .sort((a, b) => (b.coefficient_of_variation || 0) - (a.coefficient_of_variation || 0))
        .slice(0, 20)
    : [];

  const variabilityBarData = topVariabilityHours.length > 0
    ? {
        labels: topVariabilityHours.map(
          (v) => `${v.hour_of_day}:00 - ${v.distance_bin} mi`
        ),
        datasets: [
          {
            label: 'Coefficient of Variation',
            data: topVariabilityHours.map((v) => v.coefficient_of_variation || 0),
            backgroundColor: 'rgba(255, 99, 132, 0.6)',
            borderColor: 'rgba(255, 99, 132, 1)',
          },
        ],
      }
    : null;

  // Prepare distribution data: Mean and StdDev by hour
  const distributionChartData = distributionData
    ? {
        labels: distributionData.data.map((d) => `${d.hour_of_day}:00`),
        datasets: [
          {
            label: 'Mean Duration (minutes)',
            data: distributionData.data.map((d) => d.mean_duration),
            borderColor: 'rgba(54, 162, 235, 1)',
            backgroundColor: 'rgba(54, 162, 235, 0.1)',
            yAxisID: 'y',
          },
          {
            label: 'Std Deviation (minutes)',
            data: distributionData.data.map((d) => d.std_duration || 0),
            borderColor: 'rgba(255, 159, 64, 1)',
            backgroundColor: 'rgba(255, 159, 64, 0.1)',
            yAxisID: 'y1',
          },
        ],
      }
    : null;

  // Prepare trends data: Coefficient of variation over time
  const trendsChartData = trendsData
    ? {
        labels: trendsData.data.map((t) => `${t.date} ${t.hour_of_day}:00`),
        datasets: [
          {
            label: 'Coefficient of Variation',
            data: trendsData.data.map((t) => t.coefficient_of_variation || 0),
            borderColor: 'rgba(153, 102, 255, 1)',
            backgroundColor: 'rgba(153, 102, 255, 0.1)',
          },
        ],
      }
    : null;

  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      <Typography variant="h4" component="h1" gutterBottom>
        Question 7: Trip Duration Variability
      </Typography>
      <Typography variant="body1" paragraph>
        Which hours of the day show the highest variability in trip duration for similar distances,
        and what does this suggest about predictability and rider experience?
      </Typography>

      {heatmapData?.assumptions && (
        <Alert severity="info" sx={{ mb: 3 }}>
          <Typography variant="body2">
            <strong>Assumptions:</strong> {heatmapData.assumptions.interpretation || 'Higher CV = more variability = less predictable'}
          </Typography>
        </Alert>
      )}

      <Grid container spacing={3}>
        {/* Top Variability Hours */}
        {variabilityBarData && (
          <Grid item xs={12}>
            <Paper sx={{ p: 3 }}>
              <Typography variant="h6" gutterBottom>
                Highest Variability Hours (by Distance Bin)
              </Typography>
              <Typography variant="body2" color="text.secondary" paragraph>
                Coefficient of Variation = Std(Duration) / Mean(Duration). Higher values indicate
                less predictable trip durations.
              </Typography>
              <Box sx={{ height: 400 }}>
                <BarChart
                  data={variabilityBarData}
                  yAxisLabel="Coefficient of Variation"
                />
              </Box>
            </Paper>
          </Grid>
        )}

        {/* Duration Distribution by Hour */}
        {distributionChartData && (
          <Grid item xs={12}>
            <Paper sx={{ p: 3 }}>
              <Typography variant="h6" gutterBottom>
                Mean Duration and Standard Deviation by Hour
              </Typography>
              <Typography variant="body2" color="text.secondary" paragraph>
                Shows average trip duration and variability (standard deviation) for each hour of
                the day.
              </Typography>
              <Box sx={{ height: 400 }}>
                <LineChart
                  data={distributionChartData}
                  title="Duration Statistics by Hour"
                  xAxisLabel="Hour of Day"
                  yAxisLabel="Minutes"
                />
              </Box>
            </Paper>
          </Grid>
        )}

        {/* Variability Trends */}
        {trendsChartData && (
          <Grid item xs={12}>
            <Paper sx={{ p: 3 }}>
              <Typography variant="h6" gutterBottom>
                Variability Trends Over Time
              </Typography>
              <Typography variant="body2" color="text.secondary" paragraph>
                Coefficient of variation over time. Higher values indicate periods of less
                predictable trip durations.
              </Typography>
              <Box sx={{ height: 400 }}>
                <LineChart
                  data={trendsChartData}
                  title="Variability Over Time"
                  xAxisLabel="Date & Hour"
                  yAxisLabel="Coefficient of Variation"
                />
              </Box>
            </Paper>
          </Grid>
        )}

        {/* Assumptions */}
        {heatmapData && (
          <Grid item xs={12}>
            <Paper sx={{ p: 3 }}>
              <Typography variant="h6" gutterBottom>
                Assumptions & Methodology
              </Typography>
              <Box component="ul" sx={{ pl: 2 }}>
                <li>
                  <strong>Coefficient of Variation:</strong>{' '}
                  {heatmapData.assumptions.coefficient_of_variation || 'Std(Duration) / Mean(Duration)'}
                </li>
                <li>
                  <strong>Distance Bins:</strong> {heatmapData.assumptions.distance_bins || '0-2, 2-5, 5-10, 10+ miles'}
                </li>
                <li>
                  <strong>Interpretation:</strong> {heatmapData.assumptions.interpretation || 'Higher CV = more variability = less predictable'}
                </li>
              </Box>
            </Paper>
          </Grid>
        )}
      </Grid>
    </Container>
  );
};

export default Question7;


