/**
 * Question 4: Wait Time Reduction Levers
 */
import { Container, Typography, Grid, Paper, Alert, Box } from '@mui/material';
import { useQuery } from '@tanstack/react-query';
import {
  getCurrentWaitTime,
  getWaitTimeTradeoffs,
} from '../services/wait_time';
import BarChart from '../components/Charts/BarChart';
import LoadingSpinner from '../components/Common/LoadingSpinner';

const Question4 = () => {
  const { data: waitTimeData, isLoading: waitTimeLoading } = useQuery({
    queryKey: ['wait-time-current'],
    queryFn: getCurrentWaitTime,
  });

  const { data: tradeoffsData, isLoading: tradeoffsLoading } = useQuery({
    queryKey: ['wait-time-tradeoffs'],
    queryFn: getWaitTimeTradeoffs,
  });

  if (waitTimeLoading || tradeoffsLoading) {
    return <LoadingSpinner />;
  }

  // Prepare wait time chart data (top zones by wait time proxy)
  const waitTimeChartData = waitTimeData
    ? {
        labels: waitTimeData.data
          .slice(0, 20)
          .map((d) => `Zone ${d.zone_id} (Hour ${d.hour})`),
        datasets: [
          {
            label: 'Wait Time Proxy (Demand/Supply)',
            data: waitTimeData.data
              .slice(0, 20)
              .map((d) => d.wait_time_proxy || 0),
            backgroundColor: 'rgba(255, 99, 132, 0.6)',
            borderColor: 'rgba(255, 99, 132, 1)',
          },
        ],
      }
    : null;

  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      <Typography variant="h4" component="h1" gutterBottom>
        Question 4: Wait Time Reduction Levers
      </Typography>
      <Typography variant="body1" paragraph>
        If the city wanted to reduce average passenger wait time by 10% without adding vehicles,
        which two levers suggested by the data would you pull, and what trade-offs would worsen as a result?
      </Typography>

      {waitTimeData?.assumptions && (
        <Alert severity="info" sx={{ mb: 3 }}>
          <Typography variant="body2">
            <strong>Assumptions:</strong> {JSON.stringify(waitTimeData.assumptions, null, 2)}
          </Typography>
        </Alert>
      )}

      <Grid container spacing={3}>
        <Grid item xs={12}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Wait Time Proxy by Zone and Hour (Top 20)
            </Typography>
            <Typography variant="body2" paragraph sx={{ color: 'text.secondary' }}>
              Higher values indicate longer wait times (demand exceeds supply)
            </Typography>
            {waitTimeChartData && (
              <BarChart
                data={waitTimeChartData}
                title="Wait Time Proxy (Demand/Supply Ratio)"
                xAxisLabel="Zone and Hour"
                yAxisLabel="Wait Time Proxy"
              />
            )}
          </Paper>
        </Grid>

        {tradeoffsData && (
          <Grid item xs={12}>
            <Paper sx={{ p: 3 }}>
              <Typography variant="h6" gutterBottom>
                Wait Time Reduction Levers and Trade-offs
              </Typography>
              <Grid container spacing={3} sx={{ mt: 2 }}>
                {tradeoffsData.data.lever_1 && (
                  <Grid item xs={12} md={6}>
                    <Box sx={{ p: 2, border: '1px solid', borderColor: 'divider', borderRadius: 1 }}>
                      <Typography variant="h6" gutterBottom>
                        Lever 1: {tradeoffsData.data.lever_1.name}
                      </Typography>
                      <Typography variant="subtitle2" sx={{ mt: 1, mb: 1 }}>
                        Benefits:
                      </Typography>
                      <ul>
                        {tradeoffsData.data.lever_1.benefits.map((benefit, idx) => (
                          <li key={idx}>
                            <Typography variant="body2">{benefit}</Typography>
                          </li>
                        ))}
                      </ul>
                      <Typography variant="subtitle2" sx={{ mt: 1, mb: 1 }}>
                        Trade-offs:
                      </Typography>
                      <ul>
                        {tradeoffsData.data.lever_1.tradeoffs.map((tradeoff, idx) => (
                          <li key={idx}>
                            <Typography variant="body2" color="warning.main">
                              {tradeoff}
                            </Typography>
                          </li>
                        ))}
                      </ul>
                    </Box>
                  </Grid>
                )}

                {tradeoffsData.data.lever_2 && (
                  <Grid item xs={12} md={6}>
                    <Box sx={{ p: 2, border: '1px solid', borderColor: 'divider', borderRadius: 1 }}>
                      <Typography variant="h6" gutterBottom>
                        Lever 2: {tradeoffsData.data.lever_2.name}
                      </Typography>
                      <Typography variant="subtitle2" sx={{ mt: 1, mb: 1 }}>
                        Benefits:
                      </Typography>
                      <ul>
                        {tradeoffsData.data.lever_2.benefits.map((benefit, idx) => (
                          <li key={idx}>
                            <Typography variant="body2">{benefit}</Typography>
                          </li>
                        ))}
                      </ul>
                      <Typography variant="subtitle2" sx={{ mt: 1, mb: 1 }}>
                        Trade-offs:
                      </Typography>
                      <ul>
                        {tradeoffsData.data.lever_2.tradeoffs.map((tradeoff, idx) => (
                          <li key={idx}>
                            <Typography variant="body2" color="warning.main">
                              {tradeoff}
                            </Typography>
                          </li>
                        ))}
                      </ul>
                    </Box>
                  </Grid>
                )}
              </Grid>

              {tradeoffsData.assumptions && (
                <Alert severity="info" sx={{ mt: 2 }}>
                  <Typography variant="body2">
                    <strong>Note:</strong> {tradeoffsData.assumptions.note}
                  </Typography>
                </Alert>
              )}
            </Paper>
          </Grid>
        )}
      </Grid>
    </Container>
  );
};

export default Question4;

