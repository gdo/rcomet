class Hash
  def <<( h )
    self.merge!( h )
  end
end
