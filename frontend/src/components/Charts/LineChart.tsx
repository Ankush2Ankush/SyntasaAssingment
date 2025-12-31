/**
 * Line Chart component using Chart.js
 */
import { Line } from 'react-chartjs-2';
import { ChartOptions } from 'chart.js';

interface LineChartProps {
  data: {
    labels: string[];
    datasets: {
      label: string;
      data: number[];
      borderColor?: string;
      backgroundColor?: string;
      tension?: number;
    }[];
  };
  title?: string;
  xAxisLabel?: string;
  yAxisLabel?: string;
}

const LineChart = ({ data, title, xAxisLabel, yAxisLabel }: LineChartProps) => {
  const options: ChartOptions<'line'> = {
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
      <Line data={data} options={options} />
    </div>
  );
};

export default LineChart;

