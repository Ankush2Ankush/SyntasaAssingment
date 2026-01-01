/**
 * Question 8: Minimum Distance Threshold Simulation
 */
import { Container, Typography, Grid, Paper, Alert, Box, TextField, Button } from '@mui/material';
import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { simulateMinDistance, getSensitivityAnalysis } from '../services/simulation';
import BarChart from '../components/Charts/BarChart';
import LineChart from '../components/Charts/LineChart';
import LoadingSpinner from '../components/Common/LoadingSpinner';

const Question8 = () => {
  const [threshold, setThreshold] = useState(1.0);
  const [runSimulation, setRunSimulation] = useState(false);

  const { data: simulationData, isLoading: simulationLoading } = useQuery({
    queryKey: ['simulation', threshold],
    queryFn: () => simulateMinDistance(threshold),
    enabled: runSimulation,
  });

  const { data: sensitivityData, isLoading: sensitivityLoading } = useQuery({
    queryKey: ['sensitivity-analysis'],
    queryFn: getSensitivityAnalysis,
  });

  if (simulationLoading || sensitivityLoading) {
    return <LoadingSpinner />;
  }

  const handleSimulate = () => {
    setRunSimulation(true);
  };

  // Prepare before/after comparison chart
  const comparisonData = simulationData
    ? {
        labels: ['Total Trips', 'Total Revenue', 'Avg Duration (min)'],
        datasets: [
          {
            label: 'Before',
            data: [
              simulationData.data.before.total_trips,
              simulationData.data.before.total_revenue,
              simulationData.data.before.avg_duration_minutes,
            ],
            backgroundColor: 'rgba(54, 162, 235, 0.6)',
            borderColor: 'rgba(54, 162, 235, 1)',
          },
          {
            label: 'After',
            data: [
              simulationData.data.after.total_trips,
              simulationData.data.after.total_revenue,
              simulationData.data.after.avg_duration_minutes,
            ],
            backgroundColor: 'rgba(255, 99, 132, 0.6)',
            borderColor: 'rgba(255, 99, 132, 1)',
          },
        ],
      }
    : null;

  // Sensitivity analysis chart
  const sensitivityChartData = sensitivityData
    ? {
        labels: sensitivityData.data.map((d) => `${d.threshold} mi`),
        datasets: [
          {
            label: 'Trips Removed %',
            data: sensitivityData.data.map((d) => d.trips_removed_percentage),
            borderColor: 'rgba(255, 99, 132, 1)',
            backgroundColor: 'rgba(255, 99, 132, 0.1)',
          },
          {
            label: 'Revenue Impact %',
            data: sensitivityData.data.map((d) => d.revenue_impact_percentage),
            borderColor: 'rgba(75, 192, 192, 1)',
            backgroundColor: 'rgba(75, 192, 192, 0.1)',
          },
        ],
      }
    : null;

  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      <Typography variant="h4" component="h1" gutterBottom>
        Question 8: Minimum Distance Threshold Simulation
      </Typography>
      <Typography variant="body1" paragraph>
        Using selected data only, simulate the likely impact of removing trips below a minimum
        distance threshold. Identify which metrics improve, which worsen, and which effects are
        non-intuitive. Clearly state the assumptions that make this analysis fragile.
      </Typography>

      <Box sx={{ mb: 3, display: 'flex', gap: 2, alignItems: 'center' }}>
        <TextField
          label="Threshold (miles)"
          type="number"
          value={threshold}
          onChange={(e) => setThreshold(parseFloat(e.target.value))}
          inputProps={{ min: 0.1, max: 5, step: 0.1 }}
        />
        <Button variant="contained" onClick={handleSimulate}>
          Run Simulation
        </Button>
      </Box>

      {simulationData?.assumptions && (
        <Alert severity="warning" sx={{ mb: 3 }}>
          <Typography variant="body2">
            <strong>Fragile Assumptions:</strong>
            <ul>
              {simulationData.assumptions.limitations?.map((limitation: string, idx: number) => (
                <li key={idx}>{limitation}</li>
              ))}
            </ul>
          </Typography>
        </Alert>
      )}

      <Grid container spacing={3}>
        {simulationData && (
          <>
            <Grid item xs={12}>
              <Paper sx={{ p: 3 }}>
                <Typography variant="h6" gutterBottom>
                  Before/After Comparison (Threshold: {threshold} miles)
                </Typography>
                {comparisonData && (
                  <BarChart
                    data={comparisonData}
                    title="Impact of Removing Trips Below Threshold"
                    xAxisLabel="Metric"
                    yAxisLabel="Value"
                  />
                )}
              </Paper>
            </Grid>

            <Grid item xs={12} md={6}>
              <Paper sx={{ p: 3 }}>
                <Typography variant="h6" gutterBottom>
                  Impact Summary
                </Typography>
                <Box sx={{ mt: 2 }}>
                  <Typography>
                    <strong>Trips Removed:</strong> {simulationData.data.impact.trips_removed.toLocaleString()} (
                    {simulationData.data.impact.trips_removed_percentage.toFixed(2)}%)
                  </Typography>
                  <Typography>
                    <strong>Revenue Impact:</strong> ${simulationData.data.impact.revenue_impact.toLocaleString()} (
                    {simulationData.data.impact.revenue_impact_percentage.toFixed(2)}%)
                  </Typography>
                  <Typography>
                    <strong>Duration Change:</strong>{' '}
                    {simulationData.data.impact.avg_duration_change.toFixed(2)} minutes
                  </Typography>
                </Box>
              </Paper>
            </Grid>
          </>
        )}

        <Grid item xs={12}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Sensitivity Analysis
            </Typography>
            <Typography variant="body2" paragraph>
              Shows how different threshold values affect trips removed and revenue impact.
            </Typography>
            {sensitivityChartData && (
              <LineChart
                data={sensitivityChartData}
                title="Sensitivity to Threshold Changes"
                xAxisLabel="Threshold (miles)"
                yAxisLabel="Percentage (%)"
              />
            )}
          </Paper>
        </Grid>
      </Grid>
    </Container>
  );
};

export default Question8;

