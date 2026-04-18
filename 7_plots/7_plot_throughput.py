# AI Declaration: This script skeleton was generated with AI assistance and must be reviewed by the team.
import matplotlib.pyplot as plt

plugins = ["Flannel", "Calico", "Cilium"]
throughput_rps = [855, 955, 1045]

plt.figure(figsize=(8, 5))
bars = plt.bar(plugins, throughput_rps)
plt.title("Throughput Comparison Across CNI Plugins")
plt.xlabel("CNI Plugin")
plt.ylabel("Requests per second (RPS)")
plt.grid(axis="y", linestyle="--", alpha=0.4)

for bar, value in zip(bars, throughput_rps):
    plt.text(bar.get_x() + bar.get_width() / 2, value + 8, str(value), ha="center")

plt.tight_layout()
plt.savefig("7_plots/7_throughput_comparison.png", dpi=200)
