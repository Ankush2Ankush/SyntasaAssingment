/**
 * Header component with navigation
 */
import { AppBar, Toolbar, Typography, Button, Box } from '@mui/material';
import { Link, useLocation } from 'react-router-dom';

const Header = () => {
  const location = useLocation();

  const navItems = [
    { label: 'Overview', path: '/' },
    { label: 'Q1: Revenue Zones', path: '/question1' },
    { label: 'Q2: Efficiency', path: '/question2' },
    { label: 'Q3: Surge Pricing', path: '/question3' },
    { label: 'Q4: Wait Time', path: '/question4' },
    { label: 'Q5: Congestion', path: '/question5' },
    { label: 'Q6: Incentives', path: '/question6' },
    { label: 'Q7: Variability', path: '/question7' },
    { label: 'Q8: Simulation', path: '/question8' },
    { label: 'Assumptions', path: '/assumptions' },
  ];

  return (
    <AppBar position="static">
      <Toolbar>
        <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
          NYC TLC Analytics
        </Typography>
        <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
          {navItems.map((item) => (
            <Button
              key={item.path}
              component={Link}
              to={item.path}
              color={location.pathname === item.path ? 'secondary' : 'inherit'}
              variant={location.pathname === item.path ? 'outlined' : 'text'}
              size="small"
            >
              {item.label}
            </Button>
          ))}
        </Box>
      </Toolbar>
    </AppBar>
  );
};

export default Header;

