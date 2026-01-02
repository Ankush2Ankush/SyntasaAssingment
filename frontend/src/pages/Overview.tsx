/**
 * Overview page - Executive Summary
 */
import { useQuery } from '@tanstack/react-query';
import { getOverview } from '../services/overview';
import { Container, Typography, Box, Grid, Card, CardContent } from '@mui/material';
import LoadingSpinner from '../components/Common/LoadingSpinner';

const Overview = () => {
  const { data, isLoading, error } = useQuery({
    queryKey: ['overview'],
    queryFn: getOverview,
    retry: 2,
    retryDelay: 1000,
  });

  if (isLoading) return <LoadingSpinner />;
  if (error) {
    console.error('Overview error:', error);
    return (
      <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
        <Typography variant="h5" color="error">
          Error loading overview data
        </Typography>
        <Typography variant="body1" sx={{ mt: 2 }}>
          {error instanceof Error ? error.message : 'Unknown error occurred'}
        </Typography>
        <Typography variant="body2" sx={{ mt: 2, color: 'text.secondary' }}>
          Please ensure the backend API is running at http://localhost:8000
        </Typography>
      </Container>
    );
  }

  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      <Typography variant="h3" component="h1" gutterBottom>
        NYC TLC Analytics Dashboard
      </Typography>
      <Typography variant="h5" component="h2" gutterBottom sx={{ mb: 4 }}>
        Executive Summary
      </Typography>

      {data && (
        <Grid container spacing={3}>
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Typography color="textSecondary" gutterBottom>
                  Total Trips
                </Typography>
                <Typography variant="h4">
                  {data.data.total_trips.toLocaleString()}
                </Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Typography color="textSecondary" gutterBottom>
                  Total Revenue
                </Typography>
                <Typography variant="h4">
                  ${data.data.total_revenue.toLocaleString(undefined, {
                    maximumFractionDigits: 0,
                  })}
                </Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Typography color="textSecondary" gutterBottom>
                  Zones Covered
                </Typography>
                <Typography variant="h4">{data.data.zone_count}</Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Typography color="textSecondary" gutterBottom>
                  Date Range
                </Typography>
                <Typography variant="h6">
                  {data.data.start_date && data.data.end_date
                    ? `${new Date(data.data.start_date).toLocaleDateString()} - ${new Date(data.data.end_date).toLocaleDateString()}`
                    : 'N/A'}
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      )}

      <Box sx={{ mt: 4 }}>
        <Typography variant="h6" gutterBottom>
          Navigation
        </Typography>
        <Typography>
          Use the navigation menu to explore each of the 8 analytical questions.
        </Typography>
      </Box>
    </Container>
  );
};

export default Overview;

