defprotocol AppAnimal.Neural.Clusterish do
  @spec install_pulse_sender(t, {pid(), pid()}) :: t
  def install_pulse_sender(cluster, pid_pair)

  @spec ensure_ready(t, map()) :: map()
  def ensure_ready(cluster, started_processes_by_pid)
end
