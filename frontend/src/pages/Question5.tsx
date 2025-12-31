/**
 * Question 5: High Trip, High Congestion Zones
 */
import { Container, Typography } from '@mui/material';

const Question5 = () => {
  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      <Typography variant="h4" component="h1" gutterBottom>
        Question 5: High Trip, High Congestion Zones
      </Typography>
      <Typography variant="body1" paragraph>
        Which zones generate a high number of trips in 2025 (selected duration) but contribute
        disproportionately to congestion rather than throughput? Show how short trips distort productivity metrics.
      </Typography>
      {/* TODO: Add visualizations */}
    </Container>
  );
};

export default Question5;

