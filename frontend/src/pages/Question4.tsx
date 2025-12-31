/**
 * Question 4: Wait Time Reduction Levers
 */
import { Container, Typography } from '@mui/material';

const Question4 = () => {
  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      <Typography variant="h4" component="h1" gutterBottom>
        Question 4: Wait Time Reduction Levers
      </Typography>
      <Typography variant="body1" paragraph>
        If the city wanted to reduce average passenger wait time by 10% without adding vehicles,
        which two levers suggested by the data would you pull, and what trade-offs would worsen as a result?
      </Typography>
      {/* TODO: Add visualizations */}
    </Container>
  );
};

export default Question4;

