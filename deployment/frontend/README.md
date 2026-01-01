# NYC TLC Analytics Frontend

React TypeScript frontend for NYC Yellow Taxi Trip Records analysis dashboard.

## Setup

1. **Install dependencies**:
```bash
npm install
```

2. **Configure API endpoint** (optional):
Create `.env` file:
```
VITE_API_URL=http://localhost:8000
```

3. **Run development server**:
```bash
npm run dev
```

The app will be available at http://localhost:5173

## Build for Production

```bash
npm run build
```

The built files will be in the `dist/` directory.

## Features

- **React 18** with TypeScript
- **Chart.js** with annotation and datalabels plugins
- **React Query** for data fetching and caching
- **Context API** for state management
- **Lazy Loading** for route-based code splitting
- **Material-UI** for components
- **React Router** for navigation

## Project Structure

```
src/
├── components/
│   ├── Charts/          # Chart.js components
│   ├── Common/          # Common components (Loading, etc.)
│   └── Layout/          # Layout components (Header, etc.)
├── context/             # React Context providers
├── pages/               # Page components (Questions 1-8)
├── services/            # API service functions
└── utils/               # Utilities (Chart config, etc.)
```

## Available Pages

- `/` - Overview/Executive Summary
- `/question1` - High Revenue Zones with Hidden Costs
- `/question2` - Demand vs Efficiency Trade-offs
- `/question3` - Surge Pricing Paradox
- `/question4` - Wait Time Reduction Levers
- `/question5` - High Trip, High Congestion Zones
- `/question6` - Driver Incentive Misalignment
- `/question7` - Trip Duration Variability
- `/question8` - Minimum Distance Threshold Simulation
- `/assumptions` - Assumptions & Methodology

