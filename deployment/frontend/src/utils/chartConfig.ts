/**
 * Chart.js configuration and plugin registration
 */
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  Title,
  Tooltip,
  Legend,
  ArcElement,
} from 'chart.js';
import annotationPlugin from 'chartjs-plugin-annotation';
import datalabelsPlugin from 'chartjs-plugin-datalabels';

// Register Chart.js components and plugins
ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  Title,
  Tooltip,
  Legend,
  ArcElement,
  annotationPlugin,
  datalabelsPlugin
);

export default ChartJS;

