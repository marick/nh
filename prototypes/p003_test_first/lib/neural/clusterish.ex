defprotocol AppAnimal.Neural.Clusterish do
  @spec install_pulse_sender(t, {pid(), pid()}) :: t
  def install_pulse_sender(cluster, pid_pair)
end
