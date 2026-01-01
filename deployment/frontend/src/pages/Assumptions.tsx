/**
 * Assumptions and Methodology page
 */
import { Container, Typography, Box, Paper } from '@mui/material';

const Assumptions = () => {
  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      <Typography variant="h4" component="h1" gutterBottom>
        Assumptions & Methodology
      </Typography>

      <Box sx={{ mt: 4 }}>
        <Paper sx={{ p: 3, mb: 3 }}>
          <Typography variant="h6" gutterBottom>
            Idle Time Calculation
          </Typography>
          <Typography variant="body2" paragraph>
            Method: Zone-level temporal clustering
          </Typography>
          <Typography variant="body2" paragraph>
            Time window: 30 minutes
          </Typography>
          <Typography variant="body2" paragraph>
            Spatial window: Same zone or adjacent zones
          </Typography>
        </Paper>

        <Paper sx={{ p: 3, mb: 3 }}>
          <Typography variant="h6" gutterBottom>
            Empty Return Probability
          </Typography>
          <Typography variant="body2" paragraph>
            Time window: 2 hours
          </Typography>
          <Typography variant="body2" paragraph>
            Definition: Return trip from destination to origin
          </Typography>
        </Paper>

        <Paper sx={{ p: 3, mb: 3 }}>
          <Typography variant="h6" gutterBottom>
            Wait Time Proxy
          </Typography>
          <Typography variant="body2" paragraph>
            Formula: Demand/Supply ratio
          </Typography>
          <Typography variant="body2" paragraph>
            Note: May not reflect actual wait times
          </Typography>
        </Paper>

        <Paper sx={{ p: 3, mb: 3 }}>
          <Typography variant="h6" gutterBottom>
            Surge Detection
          </Typography>
          <Typography variant="body2" paragraph>
            Threshold: 20% above base fare
          </Typography>
          <Typography variant="body2" paragraph>
            Base fare: Median fare for similar distance/time
          </Typography>
        </Paper>
      </Box>
    </Container>
  );
};

export default Assumptions;

