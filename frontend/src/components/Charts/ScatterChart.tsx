/**
 * Scatter Chart component using Chart.js
 */
import { Scatter } from 'react-chartjs-2';
import { ChartOptions } from 'chart.js';

interface ScatterChartProps {
  data: {
    datasets: {
      label: string;
      data: { x: number; y: number }[];
      backgroundColor?: string;
      borderColor?: string;
    }[];
  };
  title?: string;
  xAxisLabel?: string;
  yAxisLabel?: string;
}

const ScatterChart = ({ data, title, xAxisLabel, yAxisLabel }: ScatterChartProps) => {
  const options: ChartOptions<'scatter'> = {
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
        type: 'linear',
        position: 'bottom',
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
      <Scatter data={data} options={options} />
    </div>
  );
};

export default ScatterChart;

