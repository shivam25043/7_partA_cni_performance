# AI Declaration: This script skeleton was generated with AI assistance and must be reviewed by the team.
import matplotlib.pyplot as plt

plugins = ["Flannel", "Calico", "Cilium"]
cpu_percent = [19, 23, 17]
memory_mb = [215, 265, 245]

fig, ax1 = plt.subplots(figsize=(8, 5))

ax1.plot(plugins, cpu_percent, marker="o", label="CPU (%)")
ax1.set_xlabel("CNI Plugin")
ax1.set_ylabel("CPU (%)")
ax1.grid(True, linestyle="--", alpha=0.4)

ax2 = ax1.twinx()
ax2.plot(plugins, memory_mb, marker="s", label="Memory (MB)")
ax2.set_ylabel("Memory (MB)")

lines1, labels1 = ax1.get_legend_handles_labels()
lines2, labels2 = ax2.get_legend_handles_labels()
ax1.legend(lines1 + lines2, labels1 + labels2, loc="upper left")

plt.title("Node Resource Overhead by CNI Plugin")
plt.tight_layout()
plt.savefig("7_plots/7_cpu_memory_comparison.png", dpi=200)
