# AI Declaration: This script skeleton was generated with AI assistance and must be reviewed by the team.
import matplotlib.pyplot as plt

plugins = ["Flannel", "Calico", "Cilium"]
p50_ms = [1.575, 1.275, 1.035]
p95_ms = [2.725, 2.300, 1.825]

plt.figure(figsize=(8, 5))
plt.plot(plugins, p50_ms, marker="o", label="p50 latency (ms)")
plt.plot(plugins, p95_ms, marker="s", label="p95 latency (ms)")
plt.title("Latency Comparison Across CNI Plugins")
plt.xlabel("CNI Plugin")
plt.ylabel("Latency (ms)")
plt.grid(True, linestyle="--", alpha=0.4)
plt.legend()
plt.tight_layout()
plt.savefig("7_plots/7_latency_comparison.png", dpi=200)
