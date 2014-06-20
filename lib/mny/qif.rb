module Mny::Qif

  def self.parse(qif)
    transactions = []

    field_map = {
      'C'   => 'C',
      'D'   => 'date',
      'N'   => 'N',
      'P'   => 'endpoint',
      'T'   => 'amount'
    }

    current = {}
    qif.split("\n").each do |line|
      line.chomp!
      next if line.empty?

      if line == "^"
        unless current.empty?
          transactions<< current
          current = {}
        end

        next
      end

      field = field_map[line[0]]
      value = line[1, line.length]
      current[field] = value
    end

    transactions
  end
end
