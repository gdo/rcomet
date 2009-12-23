class Hash #:nodoc:
  def <<( h )
    self.merge!( h )
  end
end
