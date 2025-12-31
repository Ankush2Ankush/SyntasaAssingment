/**
 * Bar Chart component using Chart.js
 */
import { Bar } from 'react-chartjs-2';
import { ChartOptions } from 'chart.js';

interface BarChartProps {
  data: {
    labels: string[];
    datasets: {
      label: string;
      data: number[];
      backgroundColor?: string | string[];
      borderColor?: string | string[];
    }[];
  };
  title?: string;
  xAxisLabel?: string;
  yAxisLabel?: string;
}

const BarChart = ({ data, title, xAxisLabel, yAxisLabel }: BarChartProps) => {
  const options: ChartOptions<'bar'> = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      title: {
        display: !!title,
        text: title,
        font: {
          size: 16,
        },
      },
      legend: {
        display: true,
        position: 'top',
      },
      datalabels: {
        display: false,
      },
    },
    scales: {
      x: {
        title: {
          display: !!xAxisLabel,
          text: xAxisLabel,
        },
      },
      y: {
        title: {
          display: !!yAxisLabel,
          text: yAxisLabel,
        },
        beginAtZero: true,
      },
    },
  };

  return (
    <div style={{ height: '400px', position: 'relative' }}>
      <Bar data={data} options={options} />
    </div>
  );
};

export default BarChart;

