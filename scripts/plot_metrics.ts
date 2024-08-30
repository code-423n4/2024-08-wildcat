import barChart from "cli-barchart";
import fs from "fs";

function plotCalls() {
  const file = process.argv.length > 2 ? process.argv[2] : "call-metrics.txt";
  const counter = new Map<string, number>();
  const zeroes = new Map<string, number>();

  const metricsData = fs.readFileSync(file, "utf-8");
  const lines = metricsData.split("\n");

  for (const line of lines) {
    if (line.trim() === "") continue;
    const [metric] = line.split("|");
    const [call] = metric.split(":");
    if (call.endsWith(".zero")) {
      const key = call.replace(".zero", "");
      zeroes.set(key, (zeroes.get(key) ?? 0) + 1);
      continue;
    }
    counter.set(call, (counter.get(call) ?? 0) + 1);
  }

  const data = Array.from(counter.entries())
    .map(([key, value]) => ({
      key,
      value,
    }))
    .sort((a, b) => a.key.localeCompare(b.key));
  const totalRuns = data.reduce((acc, item) => acc + item.value, 0);

  type Item = { key: string; value: number };
  const renderLabel = (_item: Item, index: number) => {
    const percent = ((data[index].value / totalRuns) * 100).toFixed(2);
    return `${data[index].value.toString()} (${percent}%)`;
  };

  const options = {
    renderLabel,
  };

  const chart = barChart(data, options);
  console.log(`Fuzz test metrics (${totalRuns} runs):\n`);
  console.log(chart);

  for (const key of counter.keys()) {
    const count = counter.get(key) ?? 0;
    const zeroCount = zeroes.get(key) ?? 0;
    const nonzeroCount = count - zeroCount;
    const data = [
      {
        key,
        value: nonzeroCount,
      },
      {
        key: `${key}.zero`,
        value: zeroCount,
      }
    ];
    const renderLabel = (_item: Item, index: number) => {
      const percent = ((data[index].value / count) * 100).toFixed(2);
      return `${data[index].value.toString()} (${percent}%)`;
    };
    console.log('--'.repeat(20));
    console.log(barChart(data, { renderLabel }))
    
  }
  

}

/* function plotMetrics() {
  const file = process.argv.length > 2 ? process.argv[2] : "call-metrics.txt";
  const counter = new Map<string, number>();

  const metricsData = fs.readFileSync(file, "utf-8");
  const lines = metricsData.split("\n");

  for (const line of lines) {
    if (line.trim() === "") continue;
    const [metric] = line.split("|");
    const [call] = metric.split(":");

    counter.set(call, (counter.get(call) ?? 0) + 1);
  }

  const data = Array.from(counter.entries())
    .map(([key, value]) => ({
      key,
      value,
    }))
    .sort((a, b) => a.key.localeCompare(b.key));
  const totalRuns = data.reduce((acc, item) => acc + item.value, 0);

  type Item = { key: string; value: number };
  const renderLabel = (_item: Item, index: number) => {
    const percent = ((data[index].value / totalRuns) * 100).toFixed(2);
    return `${data[index].value.toString()} (${percent}%)`;
  };

  const options = {
    renderLabel,
  };

  const chart = barChart(data, options);
  console.log(`Fuzz test metrics (${totalRuns} runs):\n`);
  console.log(chart);
} */

plotCalls();
