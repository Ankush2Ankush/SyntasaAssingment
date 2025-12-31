/**
 * Question 6: Driver Incentive Misalignment
 */
import { Container, Typography, Grid, Paper, Alert, Box } from '@mui/material';
import { useQuery } from '@tanstack/react-query';
import {
  getDriverIncentives,
  getSystemEfficiency,
  getIncentiveMisalignment,
} from '../services/incentives';
import ScatterChart from '../components/Charts/ScatterChart';
import BarChart from '../components/Charts/BarChart';
import LoadingSpinner from '../components/Common/LoadingSpinner';

const Question6 = () => {
  const { data: driverData, isLoading: driverLoading } = useQuery({
    queryKey: ['driver-incentives'],
    queryFn: getDriverIncentives,
  });

  const { data: systemData, isLoading: systemLoading } = useQuery({
    queryKey: ['system-efficiency'],
    queryFn: getSystemEfficiency,
  });

  const { data: misalignmentData, isLoading: misalignmentLoading } = useQuery({
    queryKey: ['incentive-misalignment'],
    queryFn: getIncentiveMisalignment,
  });

  if (driverLoading || systemLoading || misalignmentLoading) {
    return <LoadingSpinner />;
  }

  // Prepare scatter chart: Driver Score vs System Score
  const scatterData = driverData && systemData
    ? {
        datasets: [
          {
            label: 'Driver Incentive vs System Efficiency',
            data: driverData.data.slice(0, 100).map((d) => {
              const system = systemData.data.find(
                (s) => s.zone_id === d.zone_id && s.hour_of_day === d.hour_of_day
              );
              return {
                x: d.driver_incentive_score || 0,
                y: system?.system_efficiency_score || 0,
              };
            }),
            backgroundColor: 'rgba(255, 99, 132, 0.6)',
            borderColor: 'rgba(255, 99, 132, 1)',
          },
        ],
      }
    : null;

  // Top misaligned zones
  const misalignedZones = misalignmentData
    ? misalignmentData.data
        .filter((m) => m.is_misaligned === 1)
        .slice(0, 15)
    : [];

  const misalignmentBarData = misalignedZones.length > 0
    ? {
        labels: misalignedZones.map(
          (z) => `Zone ${z.zone_id} @ ${z.hour_of_day}:00`
        ),
        datasets: [
          {
            label: 'Driver Score',
            data: misalignedZones.map((z) => z.driver_score),
            backgroundColor: 'rgba(255, 159, 64, 0.6)',
            borderColor: 'rgba(255, 159, 64, 1)',
          },
          {
            label: 'System Score',
            data: misalignedZones.map((z) => z.system_score),
            backgroundColor: 'rgba(75, 192, 192, 0.6)',
            borderColor: 'rgba(75, 192, 192, 1)',
          },
        ],
      }
    : null;

  // Top driver incentive zones
  const topDriverZones = driverData
    ? driverData.data.slice(0, 10)
    : [];

  const driverBarData = topDriverZones.length > 0
    ? {
        labels: topDriverZones.map((z) => `Zone ${z.zone_id} @ ${z.hour_of_day}:00`),
        datasets: [
          {
            label: 'Driver Incentive Score',
            data: topDriverZones.map((z) => z.driver_incentive_score),
            backgroundColor: 'rgba(153, 102, 255, 0.6)',
            borderColor: 'rgba(153, 102, 255, 1)',
          },
        ],
      }
    : null;

  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      <Typography variant="h4" component="h1" gutterBottom>
        Question 6: Driver Incentive Misalignment
      </Typography>
      <Typography variant="body1" paragraph>
        Identify situations in your data where driver incentives (higher fares, tips, or trip density)
        are misaligned with overall system efficiency. Explain how rational driver behavior can degrade city-level outcomes.
      </Typography>

      {misalignmentData && (
        <Alert severity="info" sx={{ mb: 3 }}>
          Found {misalignmentData.data.filter((m) => m.is_misaligned === 1).length} misaligned
          zone-hour combinations where driver incentives are high but system efficiency is low.
        </Alert>
      )}

      <Grid container spacing={3}>
        {/* Scatter: Driver vs System Efficiency */}
        {scatterData && (
          <Grid item xs={12}>
            <Paper sx={{ p: 3 }}>
              <Typography variant="h6" gutterBottom>
                Driver Incentive Score vs System Efficiency Score
              </Typography>
              <Typography variant="body2" color="text.secondary" paragraph>
                Points in the top-left quadrant indicate high driver incentives but low system
                efficiency (misalignment).
              </Typography>
              <Box sx={{ height: 400 }}>
                <ScatterChart
                  data={scatterData}
                  options={{
                    scales: {
                      x: {
                        title: {
                          display: true,
                          text: 'Driver Incentive Score (Earnings per Minute)',
                        },
                      },
                      y: {
                        title: {
                          display: true,
                          text: 'System Efficiency Score',
                        },
                      },
                    },
                  }}
                />
              </Box>
            </Paper>
          </Grid>
        )}

        {/* Misaligned Zones Bar Chart */}
        {misalignmentBarData && (
          <Grid item xs={12}>
            <Paper sx={{ p: 3 }}>
              <Typography variant="h6" gutterBottom>
                Top Misaligned Zone-Hour Combinations
              </Typography>
              <Typography variant="body2" color="text.secondary" paragraph>
                Zones and hours where driver incentives are high (top 25%) but system efficiency is
                low (bottom 50%).
              </Typography>
              <Box sx={{ height: 400 }}>
                <BarChart
                  data={misalignmentBarData}
                  options={{
                    scales: {
                      y: {
                        beginAtZero: true,
                      },
                    },
                  }}
                />
              </Box>
            </Paper>
          </Grid>
        )}

        {/* Top Driver Incentive Zones */}
        {driverBarData && (
          <Grid item xs={12}>
            <Paper sx={{ p: 3 }}>
              <Typography variant="h6" gutterBottom>
                Top Driver Incentive Zones (Earnings per Minute)
              </Typography>
              <Typography variant="body2" color="text.secondary" paragraph>
                Zones and hours with the highest driver incentive scores, calculated as (Fare +
                Tip) / Trip Duration.
              </Typography>
              <Box sx={{ height: 400 }}>
                <BarChart
                  data={driverBarData}
                  options={{
                    scales: {
                      y: {
                        beginAtZero: true,
                      },
                    },
                  }}
                />
              </Box>
            </Paper>
          </Grid>
        )}

        {/* Assumptions */}
        {misalignmentData && (
          <Grid item xs={12}>
            <Paper sx={{ p: 3 }}>
              <Typography variant="h6" gutterBottom>
                Assumptions & Methodology
              </Typography>
              <Box component="ul" sx={{ pl: 2 }}>
                <li>
                  <strong>Driver Incentive Score:</strong>{' '}
                  {driverData?.assumptions.driver_incentive_score || 'N/A'}
                </li>
                <li>
                  <strong>System Efficiency Score:</strong>{' '}
                  {systemData?.assumptions.system_efficiency_score || 'N/A'}
                </li>
                <li>
                  <strong>Misalignment Definition:</strong>{' '}
                  {misalignmentData.assumptions.misalignment_definition || 'N/A'}
                </li>
                <li>
                  <strong>Threshold:</strong> {misalignmentData.assumptions.threshold || 'N/A'}
                </li>
              </Box>
            </Paper>
          </Grid>
        )}
      </Grid>
    </Container>
  );
};

export default Question6;


