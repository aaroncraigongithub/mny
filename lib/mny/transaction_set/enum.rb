# Base class for filters for enums.
class Mny::TransactionSet::Enum < Mny::TransactionSet

  def filter!
    return if @filtered or @filters[@enum_key].blank?
    @active = true

    enums     = @filters[@enum_key].is_a?(Array) ? @filters[@enum_key] : [@filters[@enum_key]]
    enum_map  = Transaction.send(@enum_key.to_s.pluralize)

    @transactions = Transaction.where("#{ @enum_key } IN(?)", enums.collect{ |e| enum_map[e] })

    @filtered = true
  end

end
