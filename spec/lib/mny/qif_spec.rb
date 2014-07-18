require 'rails_helper'
require 'mny_helper'

describe Mny::Qif::Importer do
  let(:qif) {
    Mny::Qif::Importer.new(qif_data)
  }
  let(:transactions) { qif.transactions }

  it "imports all the transactions" do
    expect(transactions.count).to eq(6)
  end

  it "doesn't import the same data in separate sessions" do
    first_t = transactions
    second_t = Mny::Qif::Importer.new(qif_data).transactions

    expect(first_t.count).to eq(6)
    expect(second_t.count).to eq(0)
  end
end

def qif_data
  <<-EOD
C*
D07/16/2014
NN/A
PThe Coffee Place
T-9.76
^
C*
D07/16/2014
NN/A
PZorba's Greek Restaurant
T-33.00
^
C*
D07/16/2014
NN/A
PATM WITHDRAWAL
T-200.00
^
C*
D07/15/2014
NN/A
PCheep Rentacars
T30.09
^
C*
D07/15/2014
NN/A
PCheep Rentacars
T30.09
^
C*
D07/15/2014
NN/A
PPayroll Deposit
T1000.00

  EOD
end

