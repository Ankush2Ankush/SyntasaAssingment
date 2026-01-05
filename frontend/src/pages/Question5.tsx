/**
 * Question 5: High Trip, High Congestion Zones
 */
import { Container, Typography, Grid, Paper, Alert } from '@mui/material';
import { useQuery } from '@tanstack/react-query';
import {
  getCongestionZones,
  getThroughputAnalysis,
  getShortTripImpact,
} from '../services/congestion';
import BarChart from '../components/Charts/BarChart';
import ScatterChart from '../components/Charts/ScatterChart';
import LoadingSpinner from '../components/Common/LoadingSpinner';

const Question5 = () => {
  const { data: congestionData, isLoading: congestionLoading } = useQuery({
    queryKey: ['congestion-zones'],
    queryFn: getCongestionZones,
  });

  const { data: throughputData, isLoading: throughputLoading } = useQuery({
    queryKey: ['congestion-throughput'],
    queryFn: getThroughputAnalysis,
  });

  const { data: shortTripData, isLoading: shortTripLoading } = useQuery({
    queryKey: ['congestion-short-trips'],
    queryFn: () => getShortTripImpact(1.0),
  });

  if (congestionLoading || throughputLoading || shortTripLoading) {
    return <LoadingSpinner />;
  }

  // Prepare congestion index chart (top zones by congestion)
  const congestionChartData = congestionData
    ? {
        labels: congestionData.data
          .slice(0, 20)
          .map((d) => `Zone ${d.zone_id}`),
        datasets: [
          {
            label: 'Congestion Index (Duration/Distance)',
            data: congestionData.data
              .slice(0, 20)
              .map((d) => d.congestion_index || 0),
            backgroundColor: 'rgba(255, 159, 64, 0.6)',
            borderColor: 'rgba(255, 159, 64, 1)',
          },
        ],
      }
    : null;

  // Prepare throughput vs trip count scatter
  const throughputScatterData = throughputData
    ? {
        datasets: [
          {
            label: 'Trip Count vs Throughput',
            data: throughputData.data
              .filter((d) => d.throughput_per_hour !== null)
              .map((d) => ({
              x: d.trip_count,
              y: d.throughput_per_hour || 0,
            })),
            backgroundColor: 'rgba(153, 102, 255, 0.6)',
            borderColor: 'rgba(153, 102, 255, 1)',
          },
        ],
      }
    : null;

  // Prepare short trip impact chart
  const shortTripChartData = shortTripData
    ? {
        labels: shortTripData.data
          .slice(0, 20)
          .map((d) => `Zone ${d.zone_id}`),
        datasets: [
          {
            label: 'Short Trip Percentage',
            data: shortTripData.data
              .slice(0, 20)
              .map((d) => (d.short_trip_percentage || 0) * 100),
            backgroundColor: 'rgba(255, 99, 132, 0.6)',
            borderColor: 'rgba(255, 99, 132, 1)',
          },
        ],
      }
    : null;

  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      <Typography variant="h4" component="h1" gutterBottom>
        Question 5: High Trip, High Congestion Zones
      </Typography>
      <Typography variant="body1" paragraph>
        Which zones generate a high number of trips in 2025 (selected duration) but contribute
        disproportionately to congestion rather than throughput? Show how short trips distort productivity metrics.
      </Typography>

      {congestionData?.assumptions && (
        <Alert severity="info" sx={{ mb: 3 }}>
          <Typography variant="body2">
            <strong>Assumptions:</strong> {JSON.stringify(congestionData.assumptions, null, 2)}
          </Typography>
        </Alert>
      )}

      <Grid container spacing={3}>
        <Grid item xs={12}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Congestion Index by Zone (Top 20)
            </Typography>
            <Typography variant="body2" paragraph sx={{ color: 'text.secondary' }}>
              Higher index = more time per mile = more congestion
            </Typography>
            {congestionChartData && (
              <BarChart
                data={congestionChartData}
                title="Congestion Index (Duration/Distance)"
                xAxisLabel="Zone ID"
                yAxisLabel="Congestion Index"
              />
            )}
          </Paper>
        </Grid>

        <Grid item xs={12}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Trip Count vs Throughput
            </Typography>
            <Typography variant="body2" paragraph sx={{ color: 'text.secondary' }}>
              Zones with high trip count but low throughput indicate congestion issues
            </Typography>
            {throughputScatterData && (
              <ScatterChart
                data={throughputScatterData}
                title="Trip Count vs Throughput (Trips per Hour)"
                xAxisLabel="Total Trip Count"
                yAxisLabel="Throughput (Trips per Hour)"
              />
            )}
          </Paper>
        </Grid>

        <Grid item xs={12}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Short Trip Impact on Productivity (Top 20 Zones)
            </Typography>
            <Typography variant="body2" paragraph sx={{ color: 'text.secondary' }}>
              High short trip percentage may indicate low productivity despite high trip count
            </Typography>
            {shortTripChartData && (
              <BarChart
                data={shortTripChartData}
                title="Short Trip Percentage by Zone"
                xAxisLabel="Zone ID"
                yAxisLabel="Short Trip Percentage (%)"
              />
            )}

            {shortTripData && shortTripData.data.length > 0 && (
              <Alert severity="warning" sx={{ mt: 2 }}>
                <Typography variant="body2">
                  <strong>Key Insight:</strong> Zones with high short trip percentages may show
                  high trip counts but contribute more to congestion than throughput due to frequent
                  short-distance trips that don't efficiently move passengers.
                </Typography>
              </Alert>
            )}
          </Paper>
        </Grid>
      </Grid>
    </Container>
  );
};

export default Question5;

