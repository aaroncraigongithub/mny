# Base class for filters for references.
class Mny::TransactionSet::Reference < Mny::TransactionSet

  def filter!
    return if @filtered

    ids = []

    unless @filters[@id_key].nil?
     ids = (@filters[@id_key].class == Array) ? @filters[@id_key] : [@filters[@id_key]]
    end
    unless @filters[@ref_key].nil?
     ids = (@filters[@ref_key].class == Array) ? @filters[@ref_key].collect(&:id) : [@filters[@ref_key].id]
    end

    @transactions = Transaction.where("#{ @foreign_key || @id_key } IN (?)", ids) unless ids.empty?

    @filtered = true
  end

end
