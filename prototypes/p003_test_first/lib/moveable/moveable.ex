alias AppAnimal.Clusterish
alias AppAnimal.Moveable


defprotocol Moveable do
  @spec cast(t, Clusterish.t) :: none
  @doc "Casts a moveable to an appropriate destination, determined by the moveable's type."
  def cast(moveable, cluster)
end
