module Mny::Qif
  class Importer

    def initialize(qif_data)
      @data         = qif_data
      @transactions = []
    end

    def transactions
      if @transactions.empty?
        parse
        filter_transactions
      end

      @transactions
    end

    # Parse QIF lines into transaction data
    def parse
      current = {}
      @data.split("\n").each do |line|
        line.chomp!
        next if line.empty?

        if line == "^"
          unless current.empty?
            @transactions<< current
            current = {}
          end

          next
        end

        f, v = field_value(line)
        current[f] = v
      end

      @transactions<< current unless current.empty?
    end

    # Filter out transactions that were imported in a previous session.
    # Previous transactions are considered the same if the date, endpoint and
    # amount are the same.
    def filter_transactions
      @transactions.delete_if do |t_data|
        fp = Transaction.fingerprint(t_data)
        Transaction.where(fingerprint: fp).count > 0
      end
    end

    def field_value(line)
      [field_map[line[0]], line[1, line.length]]
    end

    # Map QIF fields to our fields
    def field_map
      {
        'C'   => 'C',
        'D'   => 'date',
        'N'   => 'N',
        'P'   => 'endpoint',
        'T'   => 'amount'
      }
    end
  end
end
